import 'package:example/button.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'lite_state_controllers/controller_for_multi_controller_setup.dart';

class MultiControllerSetup extends StatefulWidget {
  const MultiControllerSetup({super.key});

  @override
  State<MultiControllerSetup> createState() => _MultiControllerSetupState();
}

class _MultiControllerSetupState extends State<MultiControllerSetup> {
  final ControllerForMultiControllerSetup _controller1 =
      ControllerForMultiControllerSetup(
    printKey: 'controller1',
  );
  final ControllerForMultiControllerSetup _controller2 =
      ControllerForMultiControllerSetup(
    printKey: 'controller2',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Use Controller'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LiteState<ControllerForMultiControllerSetup>(
              key: const ValueKey('controller1'),
              controller: _controller1,
              useIsolatedController: true,
              builder: (BuildContext c,
                  ControllerForMultiControllerSetup controller) {
                return Column(
                  children: [
                    Text(
                      'Controller 1 counter:${controller.counter}',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    Button(
                      text: 'Update Controller 1 Counter',
                      onPressed: controller.updateCounter,
                    ),
                  ],
                );
              },
            ),
            LiteState<ControllerForMultiControllerSetup>(
              key: const ValueKey('controller2'),
              controller: _controller2,
              useIsolatedController: true,
              builder: (BuildContext c,
                  ControllerForMultiControllerSetup controller) {
                return Column(
                  children: [
                    Text(
                      'Controller 2 counter:${controller.counter}',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    Button(
                      text: 'Update Controller 2 Counter',
                      onPressed: controller.updateCounter,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
