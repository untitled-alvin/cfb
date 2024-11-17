import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cfb/flutter_cfb.dart';
import 'package:provider/single_child_widget.dart';

/// Signature for the `listener` function which takes the `BuildContext` along
/// with the `state` and is responsible for executing in response to
/// `state` changes.
typedef CFBWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for the `listenWhen` function which takes the previous `state`
/// and the current `state` and is responsible for returning a [bool] which
/// determines whether or not to call [CFBWidgetListener] of [CFBListener]
/// with the current `state`.
typedef CFBListenerCondition<S> = bool Function(S previous, S current);

/// {@template cfb_listener}
/// Takes a [CFBWidgetListener] and an optional [cfb] and invokes
/// the [listener] in response to `state` changes in the [cfb].
/// It should be used for functionality that needs to occur only in response to
/// a `state` change such as navigation, showing a `SnackBar`, showing
/// a `Dialog`, etc...
/// The [listener] is guaranteed to only be called once for each `state` change
/// unlike the `builder` in `CFBBuilder`.
///
/// If the [cfb] parameter is omitted, [CFBListener] will automatically
/// perform a lookup using [CFBProvider] and the current `BuildContext`.
///
/// ```dart
/// CFBListener<CFBA, CFBAState>(
///   listener: (context, state) {
///     // do stuff here based on CFBA's state
///   },
///   child: Container(),
/// )
/// ```
/// Only specify the [cfb] if you wish to provide a [cfb] that is otherwise
/// not accessible via [CFBProvider] and the current `BuildContext`.
///
/// ```dart
/// CFBListener<CFBA, CFBAState>(
///   value: cfbA,
///   listener: (context, state) {
///     // do stuff here based on CFBA's state
///   },
///   child: Container(),
/// )
/// ```
/// {@endtemplate}
///
/// {@template cfb_listener_listen_when}
/// An optional [listenWhen] can be implemented for more granular control
/// over when [listener] is called.
/// [listenWhen] will be invoked on each [cfb] `state` change.
/// [listenWhen] takes the previous `state` and current `state` and must
/// return a [bool] which determines whether or not the [listener] function
/// will be invoked.
/// The previous `state` will be initialized to the `state` of the [cfb]
/// when the [CFBListener] is initialized.
/// [listenWhen] is optional and if omitted, it will default to `true`.
///
/// ```dart
/// CFBListener<CFBA, CFBAState>(
///   listenWhen: (previous, current) {
///     // return true/false to determine whether or not
///     // to invoke listener with state
///   },
///   listener: (context, state) {
///     // do stuff here based on CFBA's state
///   },
///   child: Container(),
/// )
/// ```
/// {@endtemplate}
class CFBListener<B extends StateStreamable<S>, S>
    extends CFBListenerBase<B, S> {
  /// {@macro cfb_listener}
  /// {@macro cfb_listener_listen_when}
  const CFBListener({
    required CFBWidgetListener<S> listener,
    Key? key,
    B? cfb,
    CFBListenerCondition<S>? listenWhen,
    Widget? child,
  }) : super(
          key: key,
          child: child,
          listener: listener,
          cfb: cfb,
          listenWhen: listenWhen,
        );
}

/// {@template cfb_listener_base}
/// Base class for widgets that listen to state changes in a specified [cfb].
///
/// A [CFBListenerBase] is stateful and maintains the state subscription.
/// The type of the state and what happens with each state change
/// is defined by sub-classes.
/// {@endtemplate}
abstract class CFBListenerBase<B extends StateStreamable<S>, S>
    extends SingleChildStatefulWidget {
  /// {@macro cfb_listener_base}
  const CFBListenerBase({
    required this.listener,
    Key? key,
    this.cfb,
    this.child,
    this.listenWhen,
  }) : super(key: key, child: child);

  /// The widget which will be rendered as a descendant of the
  /// [CFBListenerBase].
  final Widget? child;

  /// The [cfb] whose `state` will be listened to.
  /// Whenever the [cfb]'s `state` changes, [listener] will be invoked.
  final B? cfb;

  /// The [CFBWidgetListener] which will be called on every `state` change.
  /// This [listener] should be used for any code which needs to execute
  /// in response to a `state` change.
  final CFBWidgetListener<S> listener;

  /// {@macro cfb_listener_listen_when}
  final CFBListenerCondition<S>? listenWhen;

  @override
  SingleChildState<CFBListenerBase<B, S>> createState() =>
      _CFBListenerBaseState<B, S>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<B?>('cfb', cfb))
      ..add(ObjectFlagProperty<CFBWidgetListener<S>>.has('listener', listener))
      ..add(
        ObjectFlagProperty<CFBListenerCondition<S>?>.has(
          'listenWhen',
          listenWhen,
        ),
      );
  }
}

class _CFBListenerBaseState<B extends StateStreamable<S>, S>
    extends SingleChildState<CFBListenerBase<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _cfb;
  late S _previousState;

  @override
  void initState() {
    super.initState();
    _cfb = widget.cfb ?? context.read<B>();
    _previousState = _cfb.state;
    _subscribe();
  }

  @override
  void didUpdateWidget(CFBListenerBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCFB = oldWidget.cfb ?? context.read<B>();
    final currentCFB = widget.cfb ?? oldCFB;
    if (oldCFB != currentCFB) {
      if (_subscription != null) {
        _unsubscribe();
        _cfb = currentCFB;
        _previousState = _cfb.state;
      }
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cfb = widget.cfb ?? context.read<B>();
    if (_cfb != cfb) {
      if (_subscription != null) {
        _unsubscribe();
        _cfb = cfb;
        _previousState = _cfb.state;
      }
      _subscribe();
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '''${widget.runtimeType} used outside of MultiCFBListener must specify a child''',
    );
    if (widget.cfb == null) {
      // Trigger a rebuild if the cfb reference has changed.
      // See https://github.com/felangel/cfb/issues/2127.
      context.select<B, bool>((cfb) => identical(_cfb, cfb));
    }
    return child!;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _subscribe() {
    _subscription = _cfb.stream.listen((state) {
      if (!mounted) return;
      if (widget.listenWhen?.call(_previousState, state) ?? true) {
        widget.listener(context, state);
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }
}
