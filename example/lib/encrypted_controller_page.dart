import 'package:example/button.dart';
import 'package:example/lite_state_controllers/auth_data.dart';
import 'package:example/lite_state_controllers/encrypted_controller.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class AuthRepo extends LiteRepo {
  AuthRepo()
      : super(
          collectionName: 'authRepo',
          encryptionPassword: '12345',
          modelInitializer: {
            AuthData: AuthData.decode,
          },
        );
}

class EncryptedControllerPage extends StatefulWidget {
  const EncryptedControllerPage({super.key});

  @override
  State<EncryptedControllerPage> createState() =>
      _EncryptedControllerPageState();
}

class _EncryptedControllerPageState extends State<EncryptedControllerPage> {
  late final EncryptedController _controller;

  @override
  void initState() {
    _controller = EncryptedController(
      strongPassword: 'qwerty123',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<EncryptedController>(
      controller: _controller,
      builder: (BuildContext c, EncryptedController controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Encrypted Controller'),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50.0),
                Button(
                  text: 'Save Auth Data',
                  onPressed: controller.setAuthData,
                ),
                Button(
                  text: 'Revive Auth Data',
                  onPressed: controller.reviveAuthData,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
