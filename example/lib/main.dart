import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'lite_state_controllers/auth_controller.dart';
import 'lite_state_controllers/loader_controller.dart';
import 'test_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    initControllersLazy({
      AuthController:() => AuthController(),
      LoaderController:() => LoaderController(),
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const TestPage(),
    );
  }
}

