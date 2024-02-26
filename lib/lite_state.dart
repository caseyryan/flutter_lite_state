// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'lite_repo.dart';
import 'on_postframe.dart';

export 'lite_repo.dart';
export 'on_postframe.dart';

typedef ControllerInitializer = LiteStateController Function();

Map<String, ControllerInitializer> _lazyControllerInitializers = {};
Map<String, LiteStateController> _controllers = {};

/// just calls a reset() method on all initialized controllers
/// what this method should / should not do is up to you. Just write
/// your own implementation if you need it
void resetAllControllers() {
  for (var controller in _controllers.values) {
    controller.reset();
  }
}

void initControllersLazy(
  Map<Type, ControllerInitializer> controllerInitializers,
) {
  for (var kv in controllerInitializers.entries) {
    final typeKey = kv.key.toString();
    if (!_controllers.containsKey(typeKey)) {
      _lazyControllerInitializers[typeKey] = kv.value;
    }
  }
}

void disposeControllerByType(Type controllerType) {
  final typeKey = controllerType.toString();
  final controller = _controllers[typeKey];
  if (controller != null) {
    controller.reset();
    controller.clearPersistentData();
    controller._disposeStream();
    _controllers.remove(typeKey);
  }
}

void initControllers(
  Map<Type, ControllerInitializer> controllerInitializers,
) {
  controllerInitializers.forEach((key, value) {
    final typeKey = key.toString();
    if (!_controllers.containsKey(typeKey)) {
      _controllers[typeKey] = value.call();
      if (kDebugMode) {
        print('LiteState: INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
      }
    }
  });
}

String _getNoControllerErrorText(String typeKey) {
  return '''
          No controller initializer for $typeKey is found.
          You need to call initializer somewhere before using LiteState
          e.g. if you need your controllers to be "lazily" initialized on demand
          initControllersLazy({
            AppBarController: () => AppBarController(),
            ThemeController: () => ThemeController(),
          });
          or 
          initControllers({
            AppBarController: () => AppBarController(),
            ThemeController: () => ThemeController(),
          });
          if you need to initialized them all at ones. 
          You can use both initControllersLazy() and initControllers()
          together. Don't worry, a controller can still be initialized 
          only once
        ''';
}

void _lazilyInitializeController(String typeKey) {
  if (_controllers.containsKey(typeKey)) {
    return;
  }
  final initializer = _lazyControllerInitializers[typeKey];
  _controllers[typeKey] = initializer!();
  _controllers[typeKey]!.rebuild();
  debugPrint(
      'LiteState: LAZILY INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
}

void _addTemporaryController<T>(
  LiteStateController<T> controller,
) {
  final typeKey = T.toString();
  _controllers[typeKey] = controller;
}

/// fc - short for Find Controller
T fc<T extends LiteStateController>() {
  return findController<T>();
}

T findController<T extends LiteStateController>() {
  final typeKey = T.toString();
  if (_controllers.containsKey(typeKey)) {
    return _controllers[typeKey] as T;
  }
  if (_lazyControllerInitializers.containsKey(typeKey)) {
    _lazilyInitializeController(typeKey);
    return _controllers[typeKey] as T;
  } else {
    throw _getNoControllerErrorText(typeKey);
  }
}

bool _hasControllerInitializer<T extends LiteStateController>() {
  final typeKey = T.toString();
  return _controllers.containsKey(typeKey) ||
      _lazyControllerInitializers.containsKey(typeKey);
}

typedef LiteStateBuilder<T extends LiteStateController> = Widget Function(
  BuildContext context,
  T controller,
);

class LiteState<T extends LiteStateController> extends StatefulWidget {
  final LiteStateBuilder<T> builder;
  final LiteStateController<T>? controller;
  final ValueChanged<T>? onReady;

  /// [builder] a function that will be called every time
  /// you call rebuild in your controller
  /// [controller] if you don't need a persistent controller
  /// pass a new instance of controller here and it will be disposed
  /// as soon as your LiteState widget is disposed
  /// [onReady] this callback is guaranteed to be called after
  /// [LiteState] has completed initialization and local storage
  /// already can be used
  const LiteState({
    required this.builder,
    this.controller,
    this.onReady,
    Key? key,
  }) : super(key: key);

  @override
  State<LiteState> createState() => _LiteStateState<T>();
}

class _LiteStateState<T extends LiteStateController>
    extends State<LiteState<T>> {
  Widget? _child;
  bool _isReady = false;

  @override
  void initState() {
    if (widget.controller != null) {
      if (_hasControllerInitializer<T>()) {
        /// just to make sure the controller did not exist
        disposeControllerByType(T);
      }
      _addTemporaryController(widget.controller!);
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiteState<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      disposeControllerByType(T);
    }
    super.dispose();
  }

  void _tryCallOnReady() {
    if (_isReady == true || _controller == null) {
      return;
    }
    _isReady = true;
    widget.onReady?.call(_controller! as T);
  }

  Widget _streamBuilder() {
    return StreamBuilder<T>(
      stream: _controller!._stream,
      initialData: _controller as T,
      builder: (BuildContext c, AsyncSnapshot<T> snapshot) {
        if (_controller?.useLocalStorage == true) {
          if (!_controller!.isLocalStorageInitialized) {
            return const SizedBox.shrink();
          }
        }
        if (snapshot.hasData) {
          _child = widget.builder(
            c,
            snapshot.data!,
          );
        }
        if (_child != null && widget.onReady != null) {
          onPostframe(() {
            _tryCallOnReady();
          });
        }
        return _child ?? const SizedBox.shrink();
      },
    );
  }

  LiteStateController<T>? get _controller {
    if (widget.controller != null) {
      return widget.controller!;
    }
    final key = T.toString();
    return _controllers[key] as LiteStateController<T>?;
  }

  void _ensureControllerInitialized() {
    if (_controller == null) {
      final typeKey = T.toString();
      if (!_lazyControllerInitializers.containsKey(typeKey)) {
        throw _getNoControllerErrorText(typeKey);
      } else {
        _lazilyInitializeController(typeKey);
      }
    }
  }

  bool get _hasStream {
    _ensureControllerInitialized();
    return _controller?._stream != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasStream) {
      return _streamBuilder();
    }
    return Container(
      color: Colors.transparent,
    );
  }
}

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

  StreamController<T> get _streamController {
    final key = T.toString();
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<T>.broadcast();
      _streamController.sink.add(this as T);
    }
    return _streamControllers[key];
  }

  void _disposeStream() {
    final key = T.toString();
    if (_streamControllers.containsKey(key)) {
      _streamControllers[key].close();
      _streamControllers.remove(key);
    }
  }

  void reset();

  Stream<T> get _stream => _streamController.stream.asBroadcastStream();

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
    _streamController.sink.add(this as T);
  }
}
