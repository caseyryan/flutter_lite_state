import 'package:example/button.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'lite_state_controllers/single_use_controller.dart';

class SingleUseControllerPage extends StatelessWidget {
  const SingleUseControllerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LiteState<SingleUseController>(
      controller: SingleUseController(),
      builder: (BuildContext c, SingleUseController controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Single Use Controller'),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  controller.counter.toString(),
                  style: const TextStyle(
                    fontSize: 50.0,
                  ),
                ),
                if (controller.date != null) Text(controller.date!),
                Button(
                  text: 'Update Counter',
                  onPressed: () {
                    controller.counter++;
                  },
                ),
                Button(
                  text: 'Set Date',
                  onPressed: () {
                    controller.setDate();
                  },
                ),
                Button(
                  text: 'Save List',
                  onPressed: () {
                    controller.saveList([
                      'one',
                      'two',
                      'tree',
                    ]);
                  },
                ),
                Button(
                  text: 'Save Map',
                  onPressed: () {
                    controller.saveMap();
                  },
                ),
                Button(
                  text: 'Save Bool',
                  onPressed: () {
                    controller.saveBool();
                  },
                ),
                Button(
                  text: 'Clear',
                  onPressed: () async {
                    controller.clearPersistentData(
                      forceReBuild: true,
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
