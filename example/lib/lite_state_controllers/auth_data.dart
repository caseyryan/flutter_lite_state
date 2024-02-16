import 'package:lite_state/lite_state.dart';

/// AuthData class is here just to
/// demonstrate how to write a reviver for local storage
/// if you need to store typed data in it
class AuthData implements LSJsonEncodable {
  String type;
  String token;
  String userName;
  AuthData({
    required this.type,
    required this.token,
    required this.userName,
  });

  @override
  Map encode() {
    return {
      'type': type,
      'token': token,
      'userName': userName,
    };
  }

  @override
  String toString() {
    return '[$runtimeType token: $token, userName: $userName]';
  }

  static AuthData decode(Map map) {
    return AuthData(
      type: map['type'],
      token: map['token'],
      userName: map['userName'],
    );
  }
}
