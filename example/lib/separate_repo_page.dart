import 'package:example/button.dart';
import 'package:example/lite_state_controllers/money_data.dart';
import 'package:example/lite_state_controllers/separate_repo_controller.dart';
import 'package:example/money_data_page.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class MoneyRepo extends LiteRepo {
  MoneyRepo()
      : super(
          collectionName: 'moneyRepo',
          encryptionPassword: '12345',
          modelInitializer: {
            MoneyData: MoneyData.decode,
          },
        );
}

final MoneyRepo moneyRepo = MoneyRepo();

class SeparateRepoPage extends StatefulWidget {
  const SeparateRepoPage({super.key});

  @override
  State<SeparateRepoPage> createState() => _SeparateRepoPageState();
}

class _SeparateRepoPageState extends State<SeparateRepoPage> {
  late final SeparateRepoController _controller;

  @override
  void initState() {
    _controller = SeparateRepoController(
      liteRepo: moneyRepo,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<SeparateRepoController>(
      controller: _controller,
      builder: (BuildContext c, SeparateRepoController controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Separate Repo Controller'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50.0),
                  Button(
                    text: 'Save Money Data',
                    onPressed: controller.saveMoneyData,
                  ),
                  Button(
                    text: 'Revive Money Data',
                    onPressed: controller.reviveMoneyData,
                  ),
                  const SizedBox(height: 50.0),
                  const Text(
                    'On the Money Data page you will be able to see the money data saved into current moneyRepo but used in ANOTHER controller',
                  ),
                  const SizedBox(height: 20.0),
                  Button(
                    text: 'Open Money Data Page',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return const MoneyDataPage();
                          },
                        ),
                      );
                    },
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
