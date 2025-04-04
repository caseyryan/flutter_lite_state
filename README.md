## Flutter Lite State

<a href="https://pub.dev/packages/lite_state"><img src="https://img.shields.io/pub/v/lite_state?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter">
<img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>

The litest state machine ever. You don't need to depend on any heavy libraries 
if you only need to control state of your widgets. 
This state manager is for those who are tired of writing 
lots of boilerplate code of states like in case of using BLoC, 
or don't want to depend on BuildContext like with using Provider 
or just don't want tons of functionality in one place like with using Get. 
I personally do like those state managers but I also see their disadvantages in some usecases. They just don't fit some projects. That's why I decided to write LiteState for the projects that need to be up and running in just a couple of minutes

Lite State is very simple and lite. It consists of a single file. 
The purpose of LiteState is to make writing and using controllers as
quick and easy as possible. I wish I could do them even simplier 
by using reflection, so that one don't even need to instantiate controllers 
but unfortunately, Flutter doesn't support mirrors :(

Anyway, just take a look at the example below

You might also like my other packages

**flutter_multi_formatter**

<a href="https://pub.dev/packages/flutter_multi_formatter"><img src="https://img.shields.io/pub/v/flutter_multi_formatter?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter">
<img alt="Awesome Flutter" src="https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square" />
</a>

**flutter_instagram_storyboard** 

<a href="https://pub.dev/packages/flutter_instagram_storyboard"><img src="https://img.shields.io/pub/v/flutter_instagram_storyboard?logo=dart" alt="pub.dev"></a>[![style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart) <a href="https://github.com/Solido/awesome-flutter"></a>


## Features
Easily controlling the state of your widgets without a need for context. That's it. 


## Getting started

All your Lite State controllers must be inherited from LiteStateController 
generic class. All the magic is happening inside. 

1) Create a controller you need. E.g. an auth controller to check users' 
authorization 


```dart
import 'package:lite_state/lite_state.dart';

class AuthController extends LiteStateController<AuthController> {

}
```

2)

## INITIALIZATION OF CONTROLLERS

### You have two options here

1) Add initialization of your controller somewhere in the beginning of your app
e.g. in initState() {} of your main class 
```dart
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
    /// In this case I've used lazy initialization
    /// this means the controller will be instantiated when it's first 
    /// used. Pay attention, I've used AuthController type as a key 
    /// in the instantiator Map. This is used internally to look for 
    /// a controller using generic constraints
    /// In case you want to initialize all your controllers at once
    /// just use initControllers() instead of initControllersLazy()
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
        primarySwatch: Colors.blue,
      ),
      home: TestPage(),
    );
  }
}
```
Just you LiteState builder any where you need
```dart
Widget build(BuildContext context) {
  return LiteState<AuthController>(
    builder: (BuildContext c, AuthController controller) {
      /// ... your code goes here
    },
  );
}

```

### OR

You can use a single use controller like this 
BE AWARE that in this case you controller will be disposed as soon 
as LiteState widget, where you pass it, is disposed
The controller like this will override any other controller of the same time 
that you might have initialized via initControllers or initControllersLazy

```dart
return LiteState<SingleUseController>(
  controller: SingleUseController(),
  builder: (BuildContext c, SingleUseController controller) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Use Controller'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              controller.counter.toString(),
              style: const TextStyle(
                fontSize: 50.0,
              ),
            ),
            Button(
              text: 'Update Counter',
              onPressed: () {
                controller.counter++;
              },
            ),
            
          ],
        ),
      ),
    );
  },
);

```

It's also possible to use the same controller type for many widgets. And the controller instances will not 
conflict with each other. In this case the setup is almost the same as the above but along with the instance of the controller you need to pass `true` to the `useIsolatedController` parameter of the `LiteState` widget.

```dart
import 'package:example/button.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

import 'lite_state_controllers/controller_for_multi_controller_setup.dart';

class MultiControllerSetup extends StatefulWidget {
  const MultiControllerSetup({super.key});

  @override
  State<MultiControllerSetup> createState() => _MultiControllerSetupState();
}

class _MultiControllerSetupState extends State<MultiControllerSetup> {
  final ControllerForMultiControllerSetup _controller1 = ControllerForMultiControllerSetup(
    printKey: 'controller1',
  );
  final ControllerForMultiControllerSetup _controller2 = ControllerForMultiControllerSetup(
    printKey: 'controller2',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single Use Controller'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LiteState<ControllerForMultiControllerSetup>(
              controller: _controller1,
              useIsolatedController: true,
              builder: (BuildContext c, ControllerForMultiControllerSetup controller) {
                return Column(
                  children: [
                    Text(
                      'Controller 1 counter:${controller.counter}',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    Button(
                      text: 'Update Controller 1 Counter',
                      onPressed: controller.updateCounter,
                    ),
                  ],
                );
              },
            ),
            LiteState<ControllerForMultiControllerSetup>(
              controller: _controller2,
              useIsolatedController: true,
              builder: (BuildContext c, ControllerForMultiControllerSetup controller) {
                return Column(
                  children: [
                    Text(
                      'Controller 2 counter:${controller.counter}',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                    Button(
                      text: 'Update Controller 2 Counter',
                      onPressed: controller.updateCounter,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

```


## Usage


<img src="https://github.com/caseyryan/images/blob/master/lite_state/lite_state.gif?raw=true" width="240"/>

```dart

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  Widget _buildUserName() {
    /// I use authController global property here instead of
    /// calling findController<AuthController>()
    /// but it does call findController inside. It's just a shorhand
    return Text('Welcome, ${authController.userName}');
  }

  @override
  Widget build(BuildContext context) {
    return LiteState<AuthController>(
      builder: (BuildContext c, AuthController controller) {
        return Scaffold(
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildUserName(),
                const SizedBox(height: 20.0),
                Button(
                  isLoading: controller.isLoading,
                  text: controller.isAuthorized ? 'Log Out' : 'Authorize',
                  onPressed: () {
                    /// you can also use a shorthand method fc<AuthController>()
                    /// to do the same. It calls findController internally
                    /// or just write a global function to get it.
                    /// e.g. right above AuthController declaration
                    /// AuthController get authController {
                    ///   return findController<AuthController>();
                    /// }
                    if (controller.isAuthorized) {
                      findController<AuthController>().logout();
                    } else {
                      findController<AuthController>().authorize();
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    left: 40.0,
                    right: 40.0,
                    top: 20.0,
                  ),
                  child: Text(
                    'Notice that your authorization is stored across sessions in a persistant local storage. Reload the app and you will see that authorization is still there',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

Controllers also allow you to easily store and restore 
data from shared preferences. When the local data is restored
a controller calls void onLocalStorageInitialied(); method.
You can override it in your controllers to know the exact time 
when your local data is ready.
This example shows how you can store and restore auth tokens

```dart
/// First you need to create a class that you want to
/// be storable / restorable. The class must implement 
/// LSJsonEncodable interface. It's very simple and is needed 
/// for a LiteState controller to determin if and instance of the 
/// class can be serialized according to its rules. 
/// The interface only contains one method: Map encode(); 
/// which must be overriden in your class
class AuthData implements LSJsonEncodable {
  String type;
  String token;
  String userName;
  AuthData({
    required this.type,
    required this.token,
    required this.userName,
  });

  @override
  Map encode() {
    return {
      'type': type,
      'token': token,
      'userName': userName,
    };
  }
  /// The static method is necessary as a decoder 
  /// so that a controller can understand how to work with your data
  /// when it meet the data in SharedPreferences
  /// You can see how it's used below
  static AuthData decode(Map map) {
    return AuthData(
      type: map['type'],
      token: map['token'],
      userName: map['userName'],
    );
  }
}

```

Now you need to initialize your decoders. The best place to do it is 
right before you initialize your controllers. Somewhere in the beginning of your app


```dart
@override
void initState() {
  
  /// Initialize decoders. In this case we only have AuthData decoder
  /// but you will need to add decoders for every class you want to be encodable / decodable
  initJsonDecoders({
    AuthData: AuthData.decode,
  });

  initControllersLazy({
    AuthController:() => AuthController(),
    LoaderController:() => LoaderController(),
  });
  super.initState();
}
```

That's basically it. Now you can simply use it in your controller. 

```dart
AuthController get authController {
  return findController<AuthController>();
}

class AuthController extends LiteStateController<AuthController> {
  
  AuthData? get authData {
    return getPersistentValue<AuthData>('authData');
  }
  set authData(AuthData? value) {
    setPersistentValue<AuthData>('authData', null);
  }

  String get userName {
    return authData?.userName ?? 'Guest';
  }
  ...
}

```

See example project for a complete source 


# Conditional rebuilds

If you want to rebuild only a particular builder, you can give this name to a LiteState instance amd pass the same name to the `rebuild('someBuilderName')` method. This will trigger only a particular builder. If you don't pass a name, all builders for this controllers that are currently in the widget tree will be rebuilt.

Here's the complete example. As you can see, it uses a few instances of LiteState with the same controller on the same page. But the instances have different names. And when you press a corresponding button, you will see only one print with the related information, which means that only that builder was triggered. 

```dart
import 'package:example/button.dart';
import 'package:flutter/material.dart';
import 'package:lite_state/lite_state.dart';

class NamedBuildersPage extends StatefulWidget {
  const NamedBuildersPage({super.key});

  @override
  State<NamedBuildersPage> createState() => _NamedBuildersPageState();
}

class _NamedBuildersPageState extends State<NamedBuildersPage> {
  final NamedBuilderController _controller = NamedBuilderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Named Builders Page'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              height: 100.0,
            ),

            /// Press one of two buttons and see how only a particular print will work
            /// While the builders use the same instance of controller
            LiteState<NamedBuilderController>(
              controller: _controller,
              builderName: 'text1',
              builder: (BuildContext c, NamedBuilderController controller) {
                debugPrint('REBUILD TEXT 1');
                return const Text('Text1');
              },
            ),
            const SizedBox(
              height: 20.0,
            ),
            LiteState<NamedBuilderController>(
              controller: _controller,
              builderName: 'text2',
              builder: (BuildContext c, NamedBuilderController controller) {
                debugPrint('REBUILD TEXT 2');
                return const Text('Text2');
              },
            ),
            const SizedBox(
              height: 20.0,
            ),
            Button(
              text: 'Rebuild Text1',
              onPressed: () {
                _controller.rebuild('text1');
              },
            ),
            Button(
              text: 'Rebuild Text2',
              onPressed: () {
                _controller.rebuild('text2');
              },
            ),
            Button(
              text: 'Unnamed Rebuild',
              onPressed: () {
                _controller.rebuild();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NamedBuilderController extends LiteStateController<NamedBuilderController> {
  @override
  void reset() {}
  @override
  void onLocalStorageInitialized() {}
}

```