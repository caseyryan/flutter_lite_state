import 'package:example/button.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class NamedBuildersPage extends StatefulWidget {
  const NamedBuildersPage({super.key});

  @override
  State<NamedBuildersPage> createState() => _NamedBuildersPageState();
}

class _NamedBuildersPageState extends State<NamedBuildersPage> {
  final NamedBuilderController _controller = NamedBuilderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Named Builders Page'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100.0,
            ),

            /// Press one of two buttons and see how only a particular print will work
            /// While the builders use the same instance of controller
            LiteState<NamedBuilderController>(
              controller: _controller,
              builderName: 'text1',
              builder: (BuildContext c, NamedBuilderController controller) {
                debugPrint('REBUILD TEXT 1');
                return const Text('Text1');
              },
            ),
            const SizedBox(
              height: 20.0,
            ),
            LiteState<NamedBuilderController>(
              controller: _controller,
              builderName: 'text2',
              builder: (BuildContext c, NamedBuilderController controller) {
                debugPrint('REBUILD TEXT 2');
                return const Text('Text2');
              },
            ),
            const SizedBox(
              height: 20.0,
            ),
            Button(
              text: 'Rebuild Text1',
              onPressed: () {
                _controller.rebuild('text1');
              },
            ),
            Button(
              text: 'Rebuild Text2',
              onPressed: () {
                _controller.rebuild('text2');
              },
            ),
            Button(
              text: 'Unnamed Rebuild',
              onPressed: () {
                _controller.rebuild();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NamedBuilderController
    extends LiteStateController<NamedBuilderController> {
  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {}
}
