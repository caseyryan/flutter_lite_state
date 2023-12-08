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
