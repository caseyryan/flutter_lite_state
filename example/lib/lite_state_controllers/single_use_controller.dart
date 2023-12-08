import 'package:flutter/foundation.dart';
import 'package:lite_state/lite_state.dart';

SingleUseController get singleUseController {
  return findController<SingleUseController>();
}

class SingleUseController extends LiteStateController<SingleUseController> {
  int _counter = 0;
  int get counter {
    return _counter;
  }

  String? get date {
    final date = getPersistentValue('date');
    return date?.toString() ?? 'none';
  }

  Future setDate() async {
    await setPersistentValue(
      'date',
      DateTime.now(),
    );
  }

  Future setList(List value) async {
    await setPersistentValue(
      'list',
      value,
    );

    final list = getPersistentValue('list');
    if (kDebugMode) {
      print(list);
    }
  }

  set counter(int value) {
    _counter = value;
    rebuild();
  }

  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {}
}
