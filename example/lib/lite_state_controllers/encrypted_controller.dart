import 'package:example/lite_state_controllers/auth_data.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

EncryptedController get encryptedController {
  return findController<EncryptedController>();
}

class EncryptedController extends LiteStateController<EncryptedController> {
  EncryptedController({
    required String strongPassword,
  }) : super(
          encryptionPassword: strongPassword,
        );

  Future setAuthData() async {
    final authData = AuthData(
      type: 'Bearer',
      token: 'some token',
      userName: 'John Doe',
    );
    await setPersistentValue(
      'authData',
      authData,
    );
    debugPrint('SAVED DATA');
  }

  Future reviveAuthData() async {
    final authData = getPersistentValue<AuthData>('authData');
    debugPrint(authData.toString());
  }

  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {}
}
