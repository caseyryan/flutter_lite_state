import 'package:example/lite_state_controllers/auth_controller.dart';
import 'package:example/lite_state_controllers/loader_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'button.dart';

class LoaderPage extends StatelessWidget {
  const LoaderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LiteState<AuthController>(
      onReady: (AuthController controller) {
        if (kDebugMode) {
          print('$AuthController first build of $this');
        }
      },
      builder: (BuildContext c, AuthController controller) {
        return LiteState<LoaderController>(
          builder: (BuildContext c, LoaderController controller) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 40.0,
                        right: 40.0,
                        bottom: 20.0,
                      ),
                      child: Text(
                        'Loaders on this page block corresponding buttons only',
                      ),
                    ),
                    Button(
                      isLoading: controller.getIsLoading('load1'),
                      text: 'Load 1',
                      onPressed: () {
                        fc<LoaderController>().load1();
                      },
                    ),
                    const SizedBox(height: 20.0),
                    Button(
                      isLoading: controller.getIsLoading('load2'),
                      text: 'Load 2',
                      onPressed: () {
                        fc<LoaderController>().load2();
                      },
                    ),
                    const SizedBox(height: 20.0),
                    Button(
                      isLoading: controller.getIsLoading('load3'),
                      text: 'Load 3',
                      onPressed: () {
                        fc<LoaderController>().load3();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
