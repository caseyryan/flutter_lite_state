## 2.1.0
* Added a single use controllers
## 2.0.2
* Removed throw when it's impossible to decode a data and added a description instead
## 2.0.1
* Added disposeControllerByType() global method which allows to completely kill a controller
## 2.0.0
* Drammatically simplified and improved a work with JSON encoders and decoders 
for local storage
* Added more information to the docs
## 1.0.4
* Added a global method resetAllControllers() which calls "reset()" method 
* on all initialized controllers. It's an abstract method and must be overriden in all the controllers
## 1.0.3
* Rebuild after setPersistentValue
## 1.0.2
* Added stopAllLoadings() to the LiteState to be able to stop 
all loaders at once
## 1.0.1
* Updated readme file
## 1.0.0
* Initial release of a very simple state controller
