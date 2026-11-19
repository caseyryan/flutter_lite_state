import 'package:material_ui/material_ui.dart';

void onPostframe(VoidCallback callback) {
  WidgetsBinding.instance.ensureVisualUpdate();
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    callback();
  });
}
