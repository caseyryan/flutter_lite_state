part of 'lite_state.dart';

abstract class LiteStateController<T> {
  /// [encryptionPassword] If you set this, it will be used to
  /// encrypt your local data store for this controller
  /// It won't have any effect if you pass [liteRepo]
  ///
  /// [liteRepo] you can use a custom repository which might easily be shared
  /// between different controllers.
  /// This repo WILL NOT be destroyed with controller.
  /// if you don't pass a [liteRepo] one will be created by default and will be
  /// destroyed with the controller if the [preserveLocalStorageOnControllerDispose] is false
  LiteStateController({
    this.useLocalStorage = true,
    this.preserveLocalStorageOnControllerDispose = false,
    String? encryptionPassword,
    LiteRepo? liteRepo,
  }) {
    _init(liteRepo, encryptionPassword);
  }

  /// This hack is necessary to give the type some time
  /// to be initialized since you can't add anything by type
  /// from the constructor
  Future _init(
    LiteRepo? liteRepo,
    String? encryptionPassword,
  ) async {
    final typeKey = T.toString();
    if (_controllers.containsKey(typeKey)) {
      disposeControllerByType(T);
    }
    if (useLocalStorage) {
      _providedRepo = liteRepo != null;
      _liteRepo = liteRepo ??
          LiteRepo(
            encryptionPassword: encryptionPassword,
            collectionName: _preferencesKey,
            modelInitializer: {},
          );
    } else {
      if (liteRepo != null) {
        throw 'You have set `useLocalStorage` to false but passed `liteRepo`';
      }
    }

    await _initLocalStorage();
  }

  static final Map<String, dynamic> _streamControllers = {};

  LiteRepo? _liteRepo;

  LiteRepo? get repo {
    return _liteRepo;
  }

  /// [useLocalStorage] whether to use a local storage (based on `Hive` or not)
  final bool useLocalStorage;

  /// [preserveLocalStorageOnControllerDispose] if true, the values you saved
  /// using [setPersistentValue] will be preserved despite of the controller's lifecycle
  final bool preserveLocalStorageOnControllerDispose;
  bool _providedRepo = false;
  // Box? _hiveBox;

  bool get isLocalStorageInitialized {
    return _liteRepo?.isInitialized == true;
  }

  StreamController<T>? _isolatedStreamController;

  StreamController<T> _getStreamController({
    required bool useIsolatedController,
  }) {
    if (useIsolatedController) {
      _isolatedStreamController ??= StreamController<T>.broadcast();
      return _isolatedStreamController!;
    }

    final key = T.toString();
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<T>.broadcast();
      _streamControllers[key].sink.add(this as T);
    }
    return _streamControllers[key];
  }

  void _disposeStream() {
    if (_isolatedStreamController != null) {
      _isolatedStreamController!.close();
      return;
    }
    final key = T.toString();
    if (_streamControllers.containsKey(key)) {
      _streamControllers[key].close();
      _streamControllers.remove(key);
    }
  }

  void reset();

  Stream<T> _getStream({
    bool useIsolatedController = false,
  }) {
    return _getStreamController(
      useIsolatedController: useIsolatedController,
    ).stream.asBroadcastStream();
  }

  final Map<String, bool> _loaderFlags = {};
  // HiveAesCipher? _hiveCipher;

  /// It's just a utility method in case you need to
  /// simulate some loading or just wait for something
  Future delay(int millis) async {
    await Future.delayed(Duration(milliseconds: millis));
  }

  /// Retrieves a persistent data stored in SharedPreferences
  /// You can use your own types here but in this
  /// case you need to add json encoders / revivers so that
  /// jsonEncode / jsonDecode could understand how to work with your type
  dynamic getPersistentValue<TType>(String key) {
    if (_liteRepo == null || !useLocalStorage) {
      return null;
    }
    return _liteRepo?.get<TType>(key);
  }

  Future setPersistentList<TGenericType>(
    String key,
    List<TGenericType> values,
  ) async {
    if (!useLocalStorage) {
      return;
    }
    _liteRepo?.setList<TGenericType>(key, values);
    rebuild();
  }

  List<TGenericType>? getPersistentList<TGenericType>(String key) {
    if (!useLocalStorage) {
      return null;
    }
    return _liteRepo?.getList<TGenericType>(key);
  }

  Future setPersistentValue<TType>(
    String key,
    TType? value,
  ) async {
    if (!useLocalStorage) {
      return;
    }
    await _liteRepo?.set(key, value);
    rebuild();
  }

  String get _preferencesKey {
    return runtimeType.toString();
  }

  /// [forceReBuild] if true, it will call `rebuild()` after
  /// the data is cleared.
  /// [forceClearLocalStorage] makes sense only if you set
  /// `preserveLocalStorageOnControllerDispose` to true for your controller.
  /// This flag will clear your local storage
  Future clearPersistentData({
    bool forceReBuild = false,
    bool forceClearLocalStorage = false,
  }) async {
    if (_liteRepo != null) {
      if (preserveLocalStorageOnControllerDispose) {
        if (forceClearLocalStorage) {
          if (kDebugMode) {
            print('YOU\'VE USED [forceClearLocalStorage] on $runtimeType');
          }
          await _liteRepo!.clear();
        }
      } else {
        if (!_providedRepo) {
          await _liteRepo!.clear();
        }
      }
      if (forceReBuild) {
        rebuild();
      }
    }
  }

  Future _initLocalStorage() async {
    if (!useLocalStorage) {
      return;
    }
    await _liteRepo?.initialize();
    onLocalStorageInitialized();
    rebuild();
  }

  /// called when the local storage has
  /// loaded all stored values. Override it if you
  /// need to get some values from local storage
  void onLocalStorageInitialized() {}

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void startLoading() {
    _isLoading = true;
    rebuild();
  }

  void stopLoading() {
    _isLoading = false;
    rebuild();
  }

  bool getIsLoading(String? loaderName) {
    if (loaderName == null) {
      return _isLoading;
    }
    return _loaderFlags[loaderName] == true;
  }

  void setIsLoading(
    String? loaderName,
    bool value,
  ) {
    if (loaderName != null) {
      _loaderFlags[loaderName] = value;
    } else {
      _isLoading = value;
    }
    rebuild();
  }

  /// just sets all loader flags to false
  /// but doesn't actually stop any loaders
  void stopAllLoadings() {
    _isLoading = false;
    for (var kv in _loaderFlags.entries) {
      _loaderFlags[kv.key] = false;
    }
    rebuild();
  }

  @mustCallSuper
  void rebuild() {
    if (_isolatedStreamController != null) {
      if (!_isolatedStreamController!.isClosed) {
        _isolatedStreamController!.sink.add(this as T);
      }
    } else {
      final c = _getStreamController(
        useIsolatedController: false,
      );
      if (c.isClosed == false) {
        c.sink.add(this as T);
      }
    }
  }
}