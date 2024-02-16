import 'package:example/separate_repo_page.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class MoneyDataPage extends StatefulWidget {
  const MoneyDataPage({super.key});

  @override
  State<MoneyDataPage> createState() => _MoneyDataPageState();
}

class _MoneyDataPageState extends State<MoneyDataPage> {
  late final MoneyDataController _controller;

  @override
  void initState() {
    /// See we use here the same controller as we used in a SeparateRepoController
    /// and it will have the same data
    _controller = MoneyDataController(
      liteRepo: moneyRepo,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<MoneyDataController>(
      controller: _controller,
      builder: (BuildContext c, MoneyDataController controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Money Data'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50.0),
                  Text(
                    controller.savedMoney,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

MoneyDataController get moneyDataController {
  return findController<MoneyDataController>();
}

class MoneyDataController extends LiteStateController<MoneyDataController> {
  MoneyDataController({
    required LiteRepo liteRepo,
  }) : super(liteRepo: liteRepo);

  String? _savedMoney;

  String get savedMoney {
    return _savedMoney ?? 'No money saved yet';
  }

  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {
    final listOfMoney = getPersistentValue<List>('money');
    if (listOfMoney is List) {
      _savedMoney = listOfMoney.map((e) => e.toString()).join('\n');
      debugPrint(_savedMoney);
      rebuild();
    }
  }
}
