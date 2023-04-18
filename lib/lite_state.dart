import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// IMPORTANT! Bafore decoding enythig, you need to encode it first
/// but to be able to be encoded to JSON
/// your custom classes must implement LSJsonEncodable interface
/// from LiteState package. See AuthData in an example project
/// it simply makes sure that your class contains "encode()" method
/// that will convert your instance to a Map
void initJsonDecoders(Map<Type, Decoder> value) {
  for (var v in value.entries) {
    final key = v.key.toString();
    if (key.contains('<')) {
      throw 'Encodable type must not be generic';
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

String _getControllerExistsText(String typeKey) {
  return '''
          The controller for $typeKey is already initialized.
          Please use findController<T>() generic function 
          to find a controller you need and do not initialize 
          the controllers by calling their constructors directly
          use special global functions instead. E.g.
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
  if (kDebugMode) {
    print('LiteState: LAZILY INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
  }
}

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

typedef LiteStateBuilder<T extends LiteStateController> = Widget Function(
  BuildContext context,
  T controller,
);

class LiteState<T extends LiteStateController> extends StatefulWidget {
  final LiteStateBuilder<T> builder;

  const LiteState({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<LiteState> createState() => _LiteStateState<T>();
}

class _LiteStateState<T extends LiteStateController>
    extends State<LiteState<T>> {
  Widget? _child;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiteState<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _streamBuilder() {
    return StreamBuilder<T>(
      stream: _controller!._stream,
      initialData: _controller as T,
      builder: (BuildContext c, AsyncSnapshot<T> snapshot) {
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
      color: Colors.red,
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
  static final Map<String, dynamic> _streamControllers = {};

  StreamController<T> get _streamController {
    final key = T.toString();
    if (!_streamControllers.containsKey(key)) {
      _streamControllers[key] = StreamController<T>.broadcast();
      _streamController.sink.add(this as T);
    }
    return _streamControllers[key];
  }

  void reset();

  Stream<T> get _stream => _streamController.stream.asBroadcastStream();

  final Map<String, bool> _loaderFlags = {};
  SharedPreferences? _prefs;
  Map<String, dynamic> _persistentData = {};

  LiteStateController() {
    _init();
  }

  /// This hack is necessary to give the type some time
  /// to be initialized since you can't add anything by type
  /// from the constructor
  Future _init() async {
    final typeKey = T.toString();
    if (_controllers.containsKey(typeKey)) {
      throw _getControllerExistsText(typeKey);
    }
    await _initLocalStorage();
  }

  /// It's just a utility method in case you need to
  /// simlulate some loading or just wait for something
  Future delay(int millis) async {
    await Future.delayed(Duration(milliseconds: millis));
  }

  /// Retrieves a persistend data stored in SharedPreferences
  /// You can use your own types here but in this
  /// case you need to add json encoders / revivers so that
  /// jsonEncode / jsonDecode could understand how to work with your type
  TType? getPersistentValue<TType>(String key) {
    return _persistentData[key] as TType?;
  }

  Future setPersistentValue<TType>(
    String key,
    TType? value,
  ) async {
    if (value == null) {
      _persistentData.remove(key);
    } else {
      _persistentData[key] = value;
    }
    await _updateLocalPrefs();
    rebuild();
  }

  Future _updateLocalPrefs() async {
    if (_prefs != null) {
      try {
        final data = jsonEncode(
          _persistentData,
          toEncodable: _encodeValue,
        );
        await _prefs!.setString(
          _prefsKey,
          data,
        );
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
    }
  }

  String? _encodeValue(Object? nonEncodable) {
    dynamic value;
    if (nonEncodable is DateTime) {
      return nonEncodable.toIso8601String();
    } else if (nonEncodable is io.File) {
      return nonEncodable.path;
    }
    final typeName = nonEncodable.runtimeType.toString();
    if (typeName.contains('<')) {
      throw 'Encodable type must not be generic';
    }
    if (_isPrimitiveType(typeName)) {
      return value;
    }
    if (nonEncodable is! LSJsonEncodable) {
      throw 'Your class must implement JsonEncodable before it can be converted to JSON';
    }
    final wrapper = _EncodedValueWrapper(
      typeName: typeName,
      value: nonEncodable.encode(),
    );
    return wrapper._toEncodedJson();
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
        if (_jsonDecoders[typeName] != null) {
          final Decoder decode = _jsonDecoders[typeName] as Decoder;
          final String innerValue = map['value'];
          final Map mapFromBase64 = jsonDecode(
            utf8.decode(
              base64Decode(innerValue),
            ),
          ) as Map;
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

  String get _prefsKey {
    return runtimeType.toString();
  }

  Future clearPersistentData() async {
    if (_prefs != null) {
      _persistentData.clear();
      await _prefs?.remove(_prefsKey);
    }
  }

  Future _initLocalStorage() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      final string = _prefs!.getString(_prefsKey);
      if (string == null) {
        _persistentData = <String, dynamic>{};
      } else {
        _persistentData = jsonDecode(
          string,
          reviver: _reviveValue,
        )?.cast<String, dynamic>();
      }
      onLocalStorageInitialied();
      rebuild();
    }
  }

  /// called when the local storage has
  /// loaded all stored values. Override it if you
  /// need to get some values from local storage
  void onLocalStorageInitialied() {}

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
