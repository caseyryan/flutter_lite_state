// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

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
void initJsonDecoders(Map<Type, ModelDecoderFunction> value) {
  for (var v in value.entries) {
    final key = v.key.toString();
    if (key.contains('<')) {
      throw 'Encodable type must not be generic. Actual type: $key';
    }
    if (!_jsonDecoders.containsKey(key)) {
      _jsonDecoders[key] = v.value;
    }
  }
}

Map<String, ModelDecoderFunction> _jsonDecoders = {};

class LiteRepo {
  final String? encryptionPassword;

  /// [collectionName] You must provide a unique name for this repository
  /// this will be used to store your data in a Hive box
  final String collectionName;

  /// [modelInitializer] pass your type as a key to this map
  /// and the method that will return a value of your type
  /// converted from map.
  /// IMPORTANT! Your type (the key) MUST implement [LSJsonEncodable]
  /// example: { AuthData: AuthData.decode }
  final Map<Type, ModelDecoderFunction> modelInitializer;
  final Completer<bool> _completer = Completer();

  Box? _hiveBox;
  HiveAesCipher? _hiveCipher;

  LiteRepo({
    required this.collectionName,
    required this.modelInitializer,
    this.encryptionPassword,
  }) {
    _init();
  }

  List<int> _generateSecureKey() {
    var bytes = Uint8List.fromList(utf8.encode(encryptionPassword!));
    var digest = sha256.convert(bytes);
    return digest.bytes;
  }

  /// This is just a hack, to make it compatible
  /// with LiteState's inner storage
  /// but you can also use it to make sure
  /// the repository is initialized
  /// and can already be used to store values
  Future<bool> initialize() async {
    return _completer.future;
  }


   Future setList<TGenericType>(
    String key,
    List<TGenericType> values,
  ) async {
    await set(key, values);
  }

  List<TGenericType>? getList<TGenericType>(String key) {
    final value = get(key);
    if (value is List) {
      return value.cast<TGenericType>().toList();
    }
    return null;
  }

  bool get isInitialized {
    return _completer.isCompleted;
  }

  Object? _encodeValue(Object? nonEncodable) {
    if (nonEncodable == null) {
      return null;
    }
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
    } else if (nonEncodable is Map) {
      final mapped = {};
      for (var kv in nonEncodable.entries) {
        mapped[kv.key] = _encodeValue(kv.value);
      }
      return _EncodedValueWrapper(
        typeName: 'Map',
        value: {
          'map': mapped,
        },
      )._toEncodedJson();
    }
    if (_isPrimitiveType(typeName)) {
      return nonEncodable;
    }

    if (nonEncodable is! LSJsonEncodable) {
      throw 'Your class must implement `LSJsonEncodable` before it can be converted to JSON';
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

  Future set<TType>(
    String key,
    TType? value,
  ) async {
    if (value == null) {
      await _hiveBox?.delete(key);
    } else {
      final encodedValue = _encodeValue(value);
      _hiveBox?.put(key, encodedValue);
    }
  }

  Future<int> clear() async {
    return await _hiveBox?.clear() ?? 0;
  }

  /// Retrieves a persistent data stored in SharedPreferences
  /// You can use your own types here but in this
  /// case you need to add json encoders / revivers so that
  /// jsonEncode / jsonDecode could understand how to work with your type
  dynamic get<TType>(String key) {
    final value = _hiveBox?.get(key);
    if (value is String && value.contains('{')) {
      return _reviveValue(key, value) as dynamic;
    }
    return value;
  }

  Future _init() async {
    initJsonDecoders(modelInitializer);

    if (_hiveBox == null) {
      if (encryptionPassword?.isNotEmpty == true) {
        _hiveCipher = HiveAesCipher(_generateSecureKey());
      }
      String? path;
      if (!kIsWeb) {
        final supportDir = await getApplicationSupportDirectory();
        path = supportDir.path;
      }
      _hiveBox = await Hive.openBox(
        collectionName,
        path: path,
        encryptionCipher: _hiveCipher,
      );
      _completer.complete(true);
    }
  }

  Object? _reviveValue(
    Object? key,
    Object? value,
  ) {
    Map? map;
    if (value == null) {
      return null;
    }
    try {
      final stringValue = value.toString();
      if (stringValue.startsWith('{') || stringValue.startsWith('[')) {
        map = jsonDecode(
          stringValue,
          reviver: _reviveValue,
        );
      }
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
        } else if (typeName == 'Map') {
          Map map = mapFromBase64['map'];
          final revivedMap = {};
          for (var kv in map.entries) {
            final value = _reviveValue(kv.key, kv.value);
            revivedMap[kv.key] = value;
          }
          return revivedMap;
        } else if (_jsonDecoders[typeName] != null) {
          final ModelDecoderFunction decode =
              _jsonDecoders[typeName] as ModelDecoderFunction;
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

abstract class LSJsonEncodable {
  Map encode();
}

typedef ModelDecoderFunction = LSJsonEncodable Function(Map json);
