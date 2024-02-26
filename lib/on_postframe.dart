import 'package:flutter/material.dart';

void onPostframe(VoidCallback callback) {
  WidgetsBinding.instance.ensureVisualUpdate();
  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    callback();
  });
}
