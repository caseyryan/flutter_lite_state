import 'package:example/lite_state_controllers/money_data.dart';
import 'package:flutter/foundation.dart';
import 'package:lite_state/lite_state.dart';

SeparateRepoController get separateRepoController {
  return findController<SeparateRepoController>();
}

class SeparateRepoController
    extends LiteStateController<SeparateRepoController> {
  SeparateRepoController({
    required LiteRepo liteRepo,
  }) : super(
          liteRepo: liteRepo,
        );

  Future saveMoneyData() async {
    final money = [
      MoneyData(currency: 'USD', amount: 120.0),
      MoneyData(currency: 'RUB', amount: 1500.0),
      MoneyData(currency: 'CNY', amount: 135.0),
    ];
    await setPersistentValue<List>('money', money);
    final someMaps = [
      {'mapKey': 123}
    ];

    /// an example of storing types without revivers and encoders. A simple list of maps
    await setPersistentValue('someMaps', someMaps);
    debugPrint('Money saved');
  }

  Future reviveMoneyData() async {
    final List? money = getPersistentValue<List>('money');
    debugPrint(money?.map((e) => e.toString()).join() ?? '');

    /// Just to demonstrate how to store arbitrary data without revivers and encoders
    final someMaps = getPersistentValue<List>('someMaps');
    if (kDebugMode) {
      print(someMaps);
    }
  }

  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {}
}
