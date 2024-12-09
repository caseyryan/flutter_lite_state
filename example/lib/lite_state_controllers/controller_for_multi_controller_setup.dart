import 'package:flutter/foundation.dart';
import 'package:lite_state/lite_state.dart';

/// Notice that you cannot use findController for this type
/// since it can't use a search by type in a hash map

class ControllerForMultiControllerSetup
    extends LiteStateController<ControllerForMultiControllerSetup> {
  ControllerForMultiControllerSetup({
    required this.printKey,
  });

  final String printKey;

  int _counter = 0;
  int get counter {
    return _counter;
  }

  void updateCounter() {
    debugPrint('updateCounter called on $printKey');
    _counter++;
    rebuild();
  }

  @override
  void reset() {
    debugPrint('reset called on $printKey');
  }

  @override
  void onLocalStorageInitialized() {}
}
