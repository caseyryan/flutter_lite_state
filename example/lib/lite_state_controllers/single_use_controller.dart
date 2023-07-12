import 'package:lite_state/lite_state.dart';

SingleUseController get singleuseController {
  return findController<SingleUseController>();
}

class SingleUseController extends LiteStateController<SingleUseController> {
  int _counter = 0;
  int get counter {
    return _counter;
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
