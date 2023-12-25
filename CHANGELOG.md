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
