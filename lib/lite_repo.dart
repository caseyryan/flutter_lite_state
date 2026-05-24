// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Initializes JSON decoders for custom types so they can be easily
/// restored from storage. Call this at the beginning of your app,
/// just before you initialize LiteState controllers.
///
/// [Decoder] MUST be a STATIC function that creates instances of
/// custom classes from a map, e.g.:
/// ```dart
/// static AuthData decode(Map<String, dynamic> map) {
///   return AuthData(
///     type: map['type'],
///     token: map['token'],
///     userName: map['userName'],
///   );
/// }
/// ```
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

  /// [collectionName] A unique name for this repository,
  /// used to identify the Hive box on disk.
  final String collectionName;

  /// [modelInitializer] Maps your type to a decode function.
  /// IMPORTANT: Your type (the key) MUST implement [LSJsonEncodable].
  /// Example: { AuthData: AuthData.decode }
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
    final bytes = Uint8List.fromList(utf8.encode(encryptionPassword!));
    final digest = sha256.convert(bytes);
    return digest.bytes;
  }

  /// Returns a Future that completes when the repository is ready to use.
  Future<bool> initialize() async {
    return _completer.future;
  }

  bool get isInitialized => _completer.isCompleted;

  Future<void> setList<TGenericType>(
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

  /// Encodes a value for storage. Wraps non-primitive types in
  /// [_EncodedValueWrapper] so they can be reliably revived later.
  Object? _encodeValue(Object? nonEncodable) {
    if (nonEncodable == null) {
      return null;
    }

    final typeName = nonEncodable.runtimeType.toString();

    if (nonEncodable is DateTime) {
      return _EncodedValueWrapper(
        typeName: 'DateTime',
        value: {'date': nonEncodable.toIso8601String()},
      )._toEncodedJson();
    }

    if (nonEncodable is io.File) {
      return _EncodedValueWrapper(
        typeName: 'File',
        value: {'path': nonEncodable.path},
      )._toEncodedJson();
    }

    if (nonEncodable is List) {
      // FIX: encode each element individually — do NOT use jsonDecode reviver
      // here, encoding is a one-way pass; each element is encoded recursively.
      final list = nonEncodable.map((e) => _encodeValue(e)).toList();
      return _EncodedValueWrapper(
        typeName: 'List',
        value: {'list': list},
      )._toEncodedJson();
    }

    if (nonEncodable is Map) {
      final mapped = <dynamic, dynamic>{};
      for (final kv in nonEncodable.entries) {
        mapped[kv.key] = _encodeValue(kv.value);
      }
      return _EncodedValueWrapper(
        typeName: 'Map',
        value: {'map': mapped},
      )._toEncodedJson();
    }

    if (_isPrimitiveType(typeName)) {
      return nonEncodable;
    }

    if (nonEncodable is! LSJsonEncodable) {
      throw 'Your class must implement `LSJsonEncodable` before it can be '
          'converted to JSON. Type: $typeName';
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

  Future<void> set<TType>(String key, TType? value) async {
    if (value == null) {
      // FIX: await the async delete call
      await _hiveBox?.delete(key);
    } else {
      final encodedValue = _encodeValue(value);
      // FIX: await the async put call so callers can rely on data being persisted
      await _hiveBox?.put(key, encodedValue);
    }
  }

  Future<int> clear() async {
    return await _hiveBox?.clear() ?? 0;
  }

  /// Retrieves persisted data. Non-primitive types stored as JSON strings
  /// are automatically revived to their original types.
  dynamic get<TType>(String key) {
    final value = _hiveBox?.get(key);

    // FIX: only attempt JSON revival when the value is a String that looks like
    // a JSON object — identified by our own wrapper sentinel, not a naive
    // `contains('{')` check which would match ordinary user strings.
    if (value is String) {
      final trimmed = value.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        return _reviveValue(key, value);
      }
    }
    return value;
  }

  Future<void> _init() async {
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

  /// Revives a stored value back to its original Dart type.
  ///
  /// This method does NOT use `jsonDecode` with a `reviver` callback — doing so
  /// would cause double-processing of nested structures (the reviver would fire
  /// on inner nodes before we even see the outer wrapper).  Instead we decode
  /// the raw JSON once, then recursively revive the already-parsed structure.
  Object? _reviveValue(Object? key, Object? value) {
    if (value == null) return null;

    // --- Try to parse the top-level string as JSON ---
    Map<String, dynamic>? topMap;
    if (value is String) {
      final trimmed = value.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          // FIX: plain jsonDecode without a reviver so we get the raw structure;
          // we walk it ourselves below.
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) {
            topMap = decoded;
          } else if (decoded is List) {
            // A bare JSON array that is not wrapped — revive each element.
            return decoded.map((e) => _reviveValue(key, e)).toList();
          }
        } catch (e, st) {
          // FIX: log the error instead of silently swallowing it
          if (kDebugMode) {
            print(
                'LiteRepo._reviveValue: failed to parse JSON for key "$key": $e\n$st');
          }
          return value; // return raw value rather than crashing
        }
      }
    } else if (value is Map<String, dynamic>) {
      // Already a parsed map (e.g. nested call from within a List/Map revival)
      topMap = value;
    }

    if (topMap == null) {
      // Primitive or unrecognised — return as-is
      return value;
    }

    // --- Check for our own wrapper sentinel ---
    if (topMap['type'] != '_EncodedValueWrapper') {
      // An ordinary map that the user stored directly — return it as-is.
      return topMap;
    }

    final typeName = topMap['typeName'] as String?;
    // FIX: safe cast with a clear error message
    final rawValue = topMap['value'];
    if (typeName == null || rawValue == null) {
      if (kDebugMode) {
        print(
            'LiteRepo._reviveValue: malformed wrapper for key "$key": $topMap');
      }
      return null;
    }

    // FIX: guard against non-String base64 payloads
    if (rawValue is! String) {
      if (kDebugMode) {
        print('LiteRepo._reviveValue: expected base64 String for key "$key", '
            'got ${rawValue.runtimeType}');
      }
      return null;
    }

    late final Map<String, dynamic> innerMap;
    try {
      innerMap = jsonDecode(utf8.decode(base64Decode(rawValue)))
          as Map<String, dynamic>;
    } catch (e, st) {
      if (kDebugMode) {
        print('LiteRepo._reviveValue: failed to decode base64 payload for '
            'key "$key" / type "$typeName": $e\n$st');
      }
      return null;
    }

    switch (typeName) {
      case 'DateTime':
        return DateTime.tryParse((innerMap['date'] as String?) ?? '');

      case 'File':
        final path = innerMap['path'] as String?;
        return path != null ? io.File(path) : null;

      case 'List':
        // FIX: revive each element individually — do NOT pass _reviveValue as
        // a jsonDecode reviver; that would double-process already-decoded nodes.
        final list = innerMap['list'];
        if (list is! List) return null;
        return list.map((e) => _reviveValue(key, e)).toList();

      case 'Map':
        final map = innerMap['map'];
        if (map is! Map) return null;
        return {
          for (final kv in map.entries) kv.key: _reviveValue(kv.key, kv.value),
        };

      default:
        final decoder = _jsonDecoders[typeName];
        if (decoder != null) {
          try {
            return decoder(innerMap);
          } catch (e, st) {
            if (kDebugMode) {
              print('LiteRepo._reviveValue: decoder for "$typeName" threw: '
                  '$e\n$st');
            }
            return null;
          }
        }

        if (kDebugMode) {
          print('''
LiteRepo: No decoder found for "$typeName".
To make your class encodable/decodable it must implement LSJsonEncodable:

  class UserData implements LSJsonEncodable {
    @override
    Map<String, dynamic> encode() => toMap();

    static UserData decode(Map<String, dynamic> data) => UserData.fromMap(data);
  }

Then register it:
  initJsonDecoders({ UserData: UserData.decode });
''');
        }
        return null;
    }
  }
}

// ---------------------------------------------------------------------------

class _EncodedValueWrapper {
  final String typeName;
  final Map<dynamic, dynamic> value;

  const _EncodedValueWrapper({
    required this.typeName,
    required this.value,
  });

  /// Encodes [value] as a base64 string so complex / nested maps survive
  /// round-trips through Hive without encoding issues.
  String _toEncodedJson() {
    final encodedData = base64Encode(utf8.encode(jsonEncode(value)));
    return jsonEncode({
      'type': '_EncodedValueWrapper',
      'typeName': typeName,
      'value': encodedData,
    });
  }
}

// ---------------------------------------------------------------------------

abstract class LSJsonEncodable {
  Map encode();
}

typedef ModelDecoderFunction = LSJsonEncodable Function(Map json);
