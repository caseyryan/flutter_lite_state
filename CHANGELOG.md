## 4.0.0
- Named rebuilds. Now you can give each LiteState instance a name (if you want) and the just call `rebuild(''builderName)` by this name, and it will rebuild only the particular builder. 
if you don't pass a name, all builders for this controllers that are currently in the widget tree will be rebuilt. This is very important feature it you want to use the same controller for 
many builders at once but you don't want to rebuild all of them
- Updated flutter version to 3.29.2

## 3.2.4
* Changed 
```dart 
typedef ModelDecoderFunction = LSJsonEncodable Function(Map json);

///to

typedef ModelDecoderFunction = LSJsonEncodable Function(Map<String, dynamic> json);
```

To be compatible with `json_serializable`
## 3.2.2
* Added `stopAllLoadings` except parameter which allows to prevent some loaders from stopping
## 3.2.1
* Hotfix. Added check if controller is not closed before sending any events to it
## 3.2.0
* Added `useIsolatedController` parameter to `LiteState` which allows to use the same controller type for many widgets but the controller instances must be different. In this case pass an instance of the controller and set `useIsolatedController` to true.
See the example in `MultiControllerSetup` class in the example project
## 3.1.2
* Add possibility to reset and dispose all controllers in one call
just call `LiteState.resetAllControllers(dispose: true)`
## 3.1.1
* Added isSliver parameter
## 3.1.0
* `onReady` is now guaranteed to be called after frame
## 3.0.3
* Added rebuild to `setPersistentList()`
## 3.0.2
* Fix uncontrollable provided repo clearance
## 3.0.1
* added `repo` getter to a `LiteStateController`
* added `getList` and `setList` methods to `LiteRepo`
## 3.0.0
* Introduced LiteRepo. Now different controllers are able to use the same repository. See example project 
* All controller storages can now be encrypted by a password. You can pass it via LiteStateController constructor or to a repository itself
## 2.5.2
* nonEncodable null check
## 2.5.1
* Fixed Hive initialization on web
## 2.5.0
* Added `preserveLocalStorageOnControllerDispose` parameter to a controller. It allows 
for storing persistent data despite of the controller's lifecycle
If you still need to clear it's data for some reason, call `clearPersistentData(forceClearLocalStorage: true);` on the controller
## 2.4.8
* Maps can also now be stored in `Hive` based storage
## 2.4.7
* Clear persistent data on controller dispose
## 2.4.6
* `LiteState` constructor now can accept `onReady` callback which will be called 
when the controller has initialized it's local storage and `LiteState` has completed its first build. You can use this callback to start some operations that require local storage of the controller to be already initiated
## 2.4.5
* List storage
## 2.4.4
* Added generic type logging
## 2.4.3
* clearPersistentData() now has a parameter forceReBuild and does not kill a Hive box
## 2.4.2
* Fixed encoder and reviver
* Builder is not called until local storage is initialized
## 2.3.5
* Moved from SharedPreferences to Hive because SharedPreferences initialization is very slow on Android
## 2.3.4
* Added debugging of local storage
## 2.3.3
* Initialization of shared preferences fixed. Now the callback is guaranteed to be called
## 2.3.1
* Changed error background color from red to transparent
## 2.3.0
* Fixed not closed broadcast stream for a single use controller
## 2.2.0
* Breaking change. Corrected a typo.
Renamed onLocalStorageInitialied to onLocalStorageInitialized. 
## 2.1.0
* Added a single use controllers
## 2.0.2
* Removed throw when it's impossible to decode a data and added a description instead
## 2.0.1
* Added disposeControllerByType() global method which allows to completely kill a controller
## 2.0.0
* Dramatically simplified and improved a work with JSON encoders and decoders 
for local storage
* Added more information to the docs
## 1.0.4
* Added a global method resetAllControllers() which calls "reset()" method 
* on all initialized controllers. It's an abstract method and must be overridden in all the controllers
## 1.0.3
* Rebuild after setPersistentValue
## 1.0.2
* Added stopAllLoadings() to the LiteState to be able to stop 
all loaders at once
## 1.0.1
* Updated readme file
## 1.0.0
* Initial release of a very simple state controller
