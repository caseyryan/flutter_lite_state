import 'package:lite_state/lite_state.dart';

import 'auth_data.dart';

/// just a shortcut that can be used to access your controller
/// from any place in your app. You may not create it if you don't need it
/// I just find it pretty convenient.
/// As you can see it does not need any context to be accessed
AuthController get authController {
  return findController<AuthController>();
}

class AuthController extends LiteStateController<AuthController> {
  /// this will return AuthData only after
  /// in has been initialized
  AuthData? get authData {
    return getPersistentValue<AuthData>('authData');
  }

  set authData(AuthData? value) {
    /// you don't have to call rebuild() here
    /// because setPersistentValue() will do it for you
    /// under the hood
    setPersistentValue<AuthData>('authData', value);
  }

  String get userName {
    return authData?.userName ?? 'Guest';
  }

  /// This method is called internally when local storage
  /// if initialized. You can use it to store / restore persistant
  /// data like Bearer tokens or something like this
  @override
  void onLocalStorageInitialied() {
    /// this is the place where all your local data is
    /// already initialized
  }

  bool get isAuthorized {
    return authData != null;
  }

  Future logout() async {
    startLoading();

    /// simulate a backend request by a small delay
    delay(500);

    /// Simply set persistent data to null to delete it
    authData = null;
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
    authData = AuthData(
      type: 'Bearer',
      token: 'SomeToken',
      userName: 'Vasya',
    );
    stopLoading();
  }

  @override
  void reset() {}
}
