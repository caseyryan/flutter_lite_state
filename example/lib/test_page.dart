import 'package:example/loader_page.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'button.dart';
import 'lite_state_controllers/auth_controller.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  Widget _buildUserName() {
    /// I use authController global property here instead of
    /// calling findController<AuthController>()
    /// but it does call findController inside. It's just a shorhand
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
                // Button(
                //   text: 'reset controller',
                //   onPressed: () {
                //     disposeControllerByType(AuthController);
                //   },
                // ),
                _buildLoadersButton(context),
                const Padding(
                  padding: EdgeInsets.only(
                    left: 40.0,
                    right: 40.0,
                    top: 20.0,
                  ),
                  child: Text(
                    'Notice that your authorization is storede across sessions in a persistant local storage. Reload the app and you will see that authorization is still there',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
