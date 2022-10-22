import 'package:lite_state/lite_state.dart';

class LoaderController extends LiteStateController<LoaderController> {
  Future load1() async {
    /// you can control what elements should be blocked
    /// by setting some properties specially for them
    setIsLoading('load1', true);
    await delay(6000);
    setIsLoading('load1', false);
  }

  Future load2() async {
    setIsLoading('load2', true);
    await delay(2000);
    setIsLoading('load2', false);
  }

  Future load3() async {
    setIsLoading('load3', true);
    await delay(4000);
    setIsLoading('load3', false);
  }
}
