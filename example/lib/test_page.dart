import 'package:example/loader_page.dart';
import 'package:example/named_builders_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'button.dart';
import 'encrypted_controller_page.dart';
import 'lite_state_controllers/auth_controller.dart';
import 'multi_controller_setup.dart';
import 'separate_repo_page.dart';
import 'single_use_controller_page.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  Widget _buildUserName() {
    /// I use authController global property here instead of
    /// calling findController<AuthController>()
    /// but it does call findController inside. It's just a shorthand
    return Text('Welcome, ${authController.userName}');
  }

  Widget _buildLoadersButton(BuildContext context) {
    if (authController.isAuthorized) {
      return Button(
          text: 'Go to loaders',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: ((context) => const LoaderPage()),
              ),
            );
          });
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<AuthController>(
      onReady: (AuthController controller) {
        if (kDebugMode) {
          print('$AuthController first build of $this');
          final authData = controller.getPersistentValue('authData');
          print(authData);
        }
      },
      builder: (BuildContext c, AuthController controller) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUserName(),
                const SizedBox(height: 20.0),
                Button(
                  isLoading: controller.isLoading,
                  text: controller.isAuthorized ? 'Log Out' : 'Authorize',
                  onPressed: () {
                    /// you can also use a shorthand method fc<AuthController>()
                    /// to do the same. It calls findController internally
                    /// or just write a global function to get it.
                    /// e.g. right above AuthController declaration
                    /// AuthController get authController {
                    ///   return findController<AuthController>();
                    /// }
                    if (controller.isAuthorized) {
                      findController<AuthController>().logout();
                    } else {
                      findController<AuthController>().authorize();
                    }
                  },
                ),
                const SizedBox(height: 20.0),
                _buildLoadersButton(context),
                const Padding(
                  padding: EdgeInsets.only(
                    left: 40.0,
                    right: 40.0,
                    top: 20.0,
                  ),
                  child: Text(
                    'Notice that your authorization is stored across sessions in a persistent local storage. Reload the app and you will see that authorization is still there',
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                Button(
                  text: 'Open Named Builders Page',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const NamedBuildersPage();
                        },
                      ),
                    );
                  },
                ),
                Button(
                  text: 'Open Single Use Controller Page',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const SingleUseControllerPage();
                        },
                      ),
                    );
                  },
                ),
                Button(
                  text: 'Open Encrypted Controller Page',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const EncryptedControllerPage();
                        },
                      ),
                    );
                  },
                ),
                Button(
                  text: 'Open Separate Repo Page',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const SeparateRepoPage();
                        },
                      ),
                    );
                  },
                ),
                Button(
                  text: 'Open Multi Controller Setup',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return const MultiControllerSetup();
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
