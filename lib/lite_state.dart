// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'lite_repo.dart';
import 'on_postframe.dart';

export 'lite_repo.dart';
export 'on_postframe.dart';

part '_controller.dart';

typedef ControllerInitializer = LiteStateController Function();

Map<String, ControllerInitializer> _lazyControllerInitializers = {};
Map<String, LiteStateController> _controllers = {};

/// just calls a reset() method on all initialized controllers
/// what this method should / should not do is up to you. Just write
/// your own implementation if you need it
void resetAllControllers({
  bool dispose = false,
}) {
  for (var controller in _controllers.values) {
    if (dispose) {
      controller.clearPersistentData();
      controller._disposeStream();
    } else {
      controller.reset();
    }
  }
  if (dispose) {
    _controllers.clear();
  }
}

void initControllersLazy(
  Map<Type, ControllerInitializer> controllerInitializers,
) {
  for (var kv in controllerInitializers.entries) {
    final typeKey = kv.key.toString();
    if (!_controllers.containsKey(typeKey)) {
      _lazyControllerInitializers[typeKey] = kv.value;
    }
  }
}

void disposeControllerByType(Type controllerType) {
  final typeKey = controllerType.toString();
  final controller = _controllers[typeKey];
  if (controller != null) {
    controller.reset();
    controller.clearPersistentData();
    controller._disposeStream();
    _controllers.remove(typeKey);
  }
}

void initControllers(
  Map<Type, ControllerInitializer> controllerInitializers,
) {
  controllerInitializers.forEach((key, value) {
    final typeKey = key.toString();
    if (!_controllers.containsKey(typeKey)) {
      _controllers[typeKey] = value.call();
      debugPrint('LiteState: INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
    }
  });
}

String _getNoControllerErrorText(String typeKey) {
  return '''
          No controller initializer for $typeKey is found.
          You need to call initializer somewhere before using LiteState
          e.g. if you need your controllers to be "lazily" initialized on demand
          initControllersLazy({
            AppBarController: () => AppBarController(),
            ThemeController: () => ThemeController(),
          });
          or 
          initControllers({
            AppBarController: () => AppBarController(),
            ThemeController: () => ThemeController(),
          });
          if you need to initialized them all at ones. 
          You can use both initControllersLazy() and initControllers()
          together. Don't worry, a controller can still be initialized 
          only once
        ''';
}

void _lazilyInitializeController(String typeKey) {
  if (_controllers.containsKey(typeKey)) {
    return;
  }
  final initializer = _lazyControllerInitializers[typeKey];
  _controllers[typeKey] = initializer!();
  _controllers[typeKey]!.rebuild();
  debugPrint(
      'LiteState: LAZILY INITIALIZED CONTROLLER: ${_controllers[typeKey]}');
}

void _addTemporaryController<T>(
  LiteStateController<T> controller,
) {
  final typeKey = T.toString();
  _controllers[typeKey] = controller;
}

/// fc - short for Find Controller
T fc<T extends LiteStateController>() {
  return findController<T>();
}

T findController<T extends LiteStateController>() {
  final typeKey = T.toString();
  if (_controllers.containsKey(typeKey)) {
    return _controllers[typeKey] as T;
  }
  if (_lazyControllerInitializers.containsKey(typeKey)) {
    _lazilyInitializeController(typeKey);
    return _controllers[typeKey] as T;
  } else {
    throw _getNoControllerErrorText(typeKey);
  }
}

bool _hasControllerInitializer<T extends LiteStateController>() {
  final typeKey = T.toString();
  return _controllers.containsKey(typeKey) ||
      _lazyControllerInitializers.containsKey(typeKey);
}

typedef LiteStateBuilder<T extends LiteStateController> = Widget Function(
  BuildContext context,
  T controller,
);

class LiteState<T extends LiteStateController> extends StatefulWidget {
  /// [builder] a function that will be called every time
  /// you call rebuild in your controller
  /// [controller] if you don't need a persistent controller
  /// pass a new instance of controller here and it will be disposed
  /// as soon as your LiteState widget is disposed
  /// [onReady] this callback is guaranteed to be called after
  /// [LiteState] has completed initialization and local storage
  /// already can be used
  const LiteState({
    required this.builder,
    this.controller,
    this.onReady,
    this.isSliver = false,
    this.useIsolatedController = false,
    Key? key,
  })  : assert(
          (useIsolatedController == true && controller != null) ||
              useIsolatedController == false,
          '`useIsolatedController` can be `true` only if a controller is provided',
        ),
        super(key: key);

  final LiteStateBuilder<T> builder;
  final LiteStateController<T>? controller;

  /// [useIsolatedController] can be useful if you need to use the
  /// same controller type for many widgets but the controller instances
  /// must be different. In this case pass an instance of the controller and
  /// set [useIsolatedController] to true. If it's set to true but a controller
  /// is not provided, you will get an exception.
  /// IMPORTANT: it it's set to true, then the controller is not available via
  /// findController and cannot be disposed of manually. It's completely bound
  /// to the instance of LiteState
  final bool useIsolatedController;
  final ValueChanged<T>? onReady;
  final bool isSliver;

  @override
  State<LiteState> createState() => _LiteStateState<T>();
}

class _LiteStateState<T extends LiteStateController>
    extends State<LiteState<T>> {
  Widget? _child;
  bool _isReady = false;

  @override
  void initState() {
    /// this flag [true] will mean that
    /// the controller instance is not added to the map
    /// thus it can't be found by findController<T>()
    /// and cannot (and must not) be disposed of manually
    if (widget.useIsolatedController == false) {
      if (widget.controller != null) {
        if (_hasControllerInitializer<T>()) {
          /// just to make sure the controller did not exist
          disposeControllerByType(T);
        }
        _addTemporaryController(widget.controller!);
      }
    }
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LiteState<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      if (widget.useIsolatedController == false) {
        disposeControllerByType(T);
      } else {
        widget.controller!.reset();
        widget.controller!._disposeStream();
      }
    }
    super.dispose();
  }

  void _tryCallOnReady() {
    if (_isReady == true || _controller == null) {
      return;
    }
    _isReady = true;
    widget.onReady?.call(_controller! as T);
  }

  Widget _streamBuilder() {
    return StreamBuilder<T>(
      key: widget.controller != null ? ValueKey(widget.controller) : null,
      stream: _controller!._getStream(
        useIsolatedController: widget.useIsolatedController,
      ),
      initialData: _controller as T,
      builder: (BuildContext c, AsyncSnapshot<T> snapshot) {
        if (_controller?.useLocalStorage == true) {
          if (!_controller!.isLocalStorageInitialized) {
            if (widget.isSliver) {
              return const SliverToBoxAdapter();
            }
            return const SizedBox.shrink();
          }
        }
        if (snapshot.hasData) {
          _child = widget.builder(
            c,
            snapshot.data!,
          );
        }
        if (_child != null && widget.onReady != null) {
          onPostframe(() {
            _tryCallOnReady();
          });
        }
        return _child ??
            (widget.isSliver
                ? const SliverToBoxAdapter()
                : const SizedBox.shrink());
      },
    );
  }

  LiteStateController<T>? get _controller {
    if (widget.controller != null) {
      return widget.controller!;
    }
    final key = T.toString();
    return _controllers[key] as LiteStateController<T>?;
  }

  void _ensureControllerInitialized() {
    if (_controller == null) {
      final typeKey = T.toString();
      if (!_lazyControllerInitializers.containsKey(typeKey)) {
        throw _getNoControllerErrorText(typeKey);
      } else {
        _lazilyInitializeController(typeKey);
      }
    }
  }

  bool get _hasStream {
    _ensureControllerInitialized();
    return _controller?._getStream(
          useIsolatedController: widget.useIsolatedController,
        ) !=
        null;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasStream) {
      return _streamBuilder();
    }
    return Container(
      color: Colors.transparent,
    );
  }
}
