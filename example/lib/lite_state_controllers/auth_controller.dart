import 'package:lite_state/lite_state.dart';

/// AuthData class is here just to
/// demonstrate how to write a reviver for local storage
/// if you need to store typed data in it
class AuthData {
  String type;
  String token;
  String userName;
  AuthData({
    required this.type,
    required this.token,
    required this.userName,
  });

  /// These two methods are for encoders / revivers
  Map<String, dynamic> encode() {
    return {
      'type': type,
      'token': token,
      'userName': userName,
    };
  }

  static AuthData decode(dynamic map) {
    return AuthData(
      type: map['type'],
      token: map['token'],
      userName: map['userName'],
    );
  }
}

AuthController get authController {
  return findController<AuthController>();
}

class AuthController extends LiteStateController<AuthController> {
  /// In case you want to store typed persistent data,
  /// you need to provide encoders and revivers so that
  /// json encoder could understand how to store your data
  AuthController()
      : super(
          encoders: {
            AuthData: <AuthData>(value) => value.encode(),
          },
          revivers: {AuthData: (value) => AuthData.decode(value)},
        );

  AuthData? _authData;

  String get userName {
    return _authData != null ? _authData!.userName : 'Guest';
  }

  /// This method is called internally when local storage
  /// if initialized. You can use it to store / restore persistant
  /// data like Bearer tokens or something like this
  @override
  void onLocalStorageInitialied() {
    /// if you authorized before this will return auth data next time
    /// because it's store in a local storage
    _authData = getPersistentValue<AuthData>('authData');

    /// call rebuild() to make sure the state is updated
    rebuild();
  }

  bool get isAuthorized {
    return _authData != null;
  }

  Future logout() async {
    startLoading();

    /// simulate a backend request by a small delay
    delay(500);

    /// Simply set persistent data to null to delete it
    await setPersistentValue<AuthData>('authData', null);
    _authData = null;
    stopLoading();
  }

  Future authorize() async {
    /// startLoading() / stopLoading() are 2
    /// basic methods that simply set isLoading variable
    /// of the controller to true / false
    /// and call rebuild()
    startLoading();

    /// jsut to simulate a backend request
    await delay(1000);
    _authData = AuthData(
      type: 'Bearer',
      token: 'SomeToken',
      userName: 'Vasya',
    );
    await setPersistentValue<AuthData>(
      'authData',
      _authData!,
    );

    stopLoading();
  }
}
