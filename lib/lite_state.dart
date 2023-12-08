import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

typedef ControllerInitializer = LiteStateController Function();

Map<String, ControllerInitializer> _lazyControllerInitializers = {};
Map<String, LiteStateController> _controllers = {};

abstract class LSJsonEncodable {
  Map encode();
}

Map<String, Decoder> _jsonDecoders = {};

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
    controller._disposeStream();
    _controllers.remove(typeKey);
  }
}

typedef Decoder = Object? Function(Map);

/// Initializes JSON decoders
/// for custom types
/// (if you ever need to store anything custom in shared preferences),
/// so they can be easily
/// restored from SharedPreferences.
/// Call this method someplace at the beginning of
/// your app, just before you initialize LiteState controllers
/// so that controllers can have access to this data before
/// they are initialized themselves.
/// [Decoder] MUST be a STATIC function
/// that creates instances of custom classes
/// from a map
/// e.g.
/// static AuthData decode(Map map) {
///   return AuthData(
///     type: map['type'],
///     token: map['token'],
///     userName: map['userName'],
///   );
/// }
/// this function converts a Map, stored in SharedPreferences
/// into a user defined object. In this case a custom class
/// called AuthData
///
/// IMPORTANT! Before decoding anything, you need to encode it first
/// but to be able to be encoded to JSON
/// your custom classes must implement LSJsonEncodable interface
/// from LiteState package. See AuthData in an example project
/// it simply makes sure that your class contains "encode()" method
/// that will convert your instance to a Map
void initJsonDecoders(Map<Type, Decoder> value) {
  for (var v in value.entries) {
    final key = v.key.toString();
    if (key.contains('<')) {
      throw 'Encodable type must not be generic. Actual type: $key';
    }
    _jsonDecoders[key] = v.value;
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

// String _getControllerExistsText(String typeKey) {
//   return '''
//           The controller for $typeKey is already initialized.
//           Please use findController<T>() generic function
//           to find a controller you need and do not initialize
//           the controllers by calling their constructors directly
//           use special global functions instead. E.g.
//           initControllersLazy({
//             AppBarController: () => AppBarController(),
//             ThemeController: () => ThemeController(),
//           });
//           or
//           initControllers({
//             AppBarController: () => AppBarController(),
//             ThemeController: () => ThemeController(),
//           });
//           if you need to initialized them all at ones.
//           You can use both initControllersLazy() and initControllers()
//           together. Don't worry, a controller can still be initialized
//           only once
//         ''';
// }

void _lazilyInitializeController(String typeKey) {
  if (_controllers.containsKey(typeKey)) {
    return;
  }
  final initializer = _lazyControllerInitializers[typeKey];
  _controllers[typeKey] = initializer!();
  _controllers[typeKey]!.rebuild();
  if (kDebugMode) {
    print('LiteState: LAZILY INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
  }
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

  /// [builder] a function that will be called every time
  /// you call rebuild in your controller
  /// [controller] if you don't need a persistent controller
  /// pass a new instance of controller here and it will be disposed
  /// as soon as your LiteState widget is disposed
  const LiteState({
    required this.builder,
    this.controller,
    Key? key,
  }) : super(key: key);

  @override
  State<LiteState> createState() => _LiteStateState<T>();
}

class _LiteStateState<T extends LiteStateController>
    extends State<LiteState<T>> {
  Widget? _child;

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

  Widget _streamBuilder() {
    return StreamBuilder<T>(
      stream: _controller!._stream,
      initialData: _controller as T,
      builder: (BuildContext c, AsyncSnapshot<T> snapshot) {
        if (_controller!.useLocalStorage) {
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

class _EncodedValueWrapper {
  String typeName;
  Map value;
  _EncodedValueWrapper({
    required this.typeName,
    required this.value,
  });

  String _toEncodedJson() {
    /// stores value as base64 string
    /// even though it take more space it is also
    /// a safer way to store some complex maps that may
    /// fail to be stored as strings
    final encodedData = base64Encode(
      utf8.encode(jsonEncode(value)),
    );
    return jsonEncode({
      'type': '_EncodedValueWrapper',
      'typeName': typeName,
      'value': encodedData,
    });
  }
}

abstract class LiteStateController<T> {
  LiteStateController({
    this.useLocalStorage = true,
    this.measureStorageInitializationTime = false,
  }) {
    _init();
  }

  static final Map<String, dynamic> _streamControllers = {};

  final bool useLocalStorage;

  Box? _hiveBox;

  bool get isLocalStorageInitialized {
    return _hiveBox != null;
  }

  /// Can be used for debugging purposes to find out if
  /// your local storage takes too much time for initializations
  final bool measureStorageInitializationTime;

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

  /// This hack is necessary to give the type some time
  /// to be initialized since you can't add anything by type
  /// from the constructor
  Future _init() async {
    final typeKey = T.toString();
    if (_controllers.containsKey(typeKey)) {
      disposeControllerByType(T);
    }
    await _initLocalStorage();
  }

  /// It's just a utility method in case you need to
  /// simulate some loading or just wait for something
  Future delay(int millis) async {
    await Future.delayed(Duration(milliseconds: millis));
  }

  /// Retrieves a persistent data stored in SharedPreferences
  /// You can use your own types here but in this
  /// case you need to add json encoders / revivers so that
  /// jsonEncode / jsonDecode could understand how to work with your type
  TType? getPersistentValue<TType>(String key) {
    if (_hiveBox == null) {
      return null;
    }
    final value = _hiveBox?.get(key);
    if (value is String && value.contains('{')) {
      return _reviveValue(key, value) as TType?;
    }
    return value as TType?;
  }

  Future setPersistentValue<TType>(
    String key,
    TType? value,
  ) async {
    if (value == null) {
      await _hiveBox?.delete(key);
    } else {
      final encodedValue = _encodeValue(value);
      _hiveBox?.put(key, encodedValue);
    }
    rebuild();
  }

  Object? _encodeValue(Object? nonEncodable) {
    final typeName = nonEncodable.runtimeType.toString();
    if (nonEncodable is DateTime) {
      return _EncodedValueWrapper(
        typeName: 'DateTime',
        value: {
          'date': nonEncodable.toIso8601String(),
        },
      )._toEncodedJson();
    } else if (nonEncodable is io.File) {
      return _EncodedValueWrapper(
        typeName: "File",
        value: {
          'path': nonEncodable.path,
        },
      )._toEncodedJson();
    } else if (nonEncodable is List) {
      final list = nonEncodable.map((e) => _encodeValue(e)).toList();
      return _EncodedValueWrapper(
        typeName: 'List',
        value: {
          'list': list,
        },
      )._toEncodedJson();
    }
    if (_isPrimitiveType(typeName)) {
      return nonEncodable;
    }

    if (nonEncodable is! LSJsonEncodable) {
      throw 'Your class must implement JsonEncodable before it can be converted to JSON';
    }
    return _EncodedValueWrapper(
      typeName: typeName,
      value: nonEncodable.encode(),
    )._toEncodedJson();
  }

  bool _isPrimitiveType(String typeName) {
    switch (typeName) {
      case 'bool':
      case 'int':
      case 'double':
      case 'num':
      case 'String':
        return true;
    }
    return false;
  }

  Object? _reviveValue(
    Object? key,
    Object? value,
  ) {
    Map? map;

    try {
      map = jsonDecode(
        value?.toString() ?? '{}',
        reviver: _reviveValue,
      );
      // ignore: empty_catches
    } catch (e) {}
    if (map != null) {
      if (map['type'] == '_EncodedValueWrapper') {
        final typeName = map['typeName'];
        final String innerValue = map['value'];
        final Map mapFromBase64 = jsonDecode(
          utf8.decode(
            base64Decode(innerValue),
          ),
        ) as Map;
        if (typeName == 'DateTime') {
          return DateTime.tryParse(mapFromBase64['date'] ?? '');
        } else if (typeName == 'File') {
          return io.File(mapFromBase64['path']);
        } else if (typeName == 'List') {
          List list = mapFromBase64['list'];
          final result = list.map((e) => _reviveValue(key, e)).toList();
          return result;
        } else if (_jsonDecoders[typeName] != null) {
          final Decoder decode = _jsonDecoders[typeName] as Decoder;
          return decode(mapFromBase64);
        } else {
          if (kDebugMode) {
            print(
              '''
              No decoder found for $typeName.
                To make your class encodable / decodable it must implement LSJsonEncodable interface 
                e.g. 
                class UserData implements LSJsonEncodable {
                  
                  /// comes from the abstract subclass (interface) 
                  Map encode() {
                    /// implement your own method to 
                    return toMap();
                  }

                  /// add a static function that returns an instance
                  static UserData decode(Map data) {
                    /// use your way to decode an instance from map
                    /// in this case I used a factory constructor but it doesn't 
                    /// really matter.
                    return UserData.fromMap(data);
                  }
                }
              ''',
            );
          }
          return null;
        }
      }
    }
    return value;
  }

  String get _preferencesKey {
    return runtimeType.toString();
  }

  Future clearPersistentData([
    bool forceReBuild = false,
  ]) async {
    if (_hiveBox != null) {
      await _hiveBox!.clear();
      if (forceReBuild) {
        rebuild();
      }
    }
  }

  Future _initLocalStorage() async {
    if (!useLocalStorage) {
      return;
    }
    Stopwatch? stopwatch;
    if (measureStorageInitializationTime) {
      if (kDebugMode) {
        stopwatch = Stopwatch()..start();
      }
    }
    if (_hiveBox == null) {
      final supportDir = await getApplicationSupportDirectory();
      _hiveBox = await Hive.openBox(
        _preferencesKey,
        path: supportDir.path,
        // encryptionCipher: HiveAesCipher(
        //   Hive.generateSecureKey(),
        // ),
      );
    }

    if (measureStorageInitializationTime) {
      if (kDebugMode) {
        print(
          '${_preferencesKey}_initLocalStorage() took: ${stopwatch?.elapsed.inMilliseconds} milliseconds',
        );
      }
    }
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
