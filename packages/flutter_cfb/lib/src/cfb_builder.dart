import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cfb/flutter_cfb.dart';

/// Signature for the `builder` function which takes the `BuildContext` and
/// [state] and is responsible for returning a widget which is to be rendered.
/// This is analogous to the `builder` function in [StreamBuilder].
typedef CFBWidgetBuilder<S> = Widget Function(BuildContext context, S state);

/// Signature for the `buildWhen` function which takes the previous `state` and
/// the current `state` and is responsible for returning a [bool] which
/// determines whether to rebuild [CFBBuilder] with the current `state`.
typedef CFBBuilderCondition<S> = bool Function(S previous, S current);

/// {@template cfb_builder}
/// [CFBBuilder] handles building a widget in response to new `states`.
/// [CFBBuilder] is analogous to [StreamBuilder] but has simplified API to
/// reduce the amount of boilerplate code needed as well as [cfb]-specific
/// performance improvements.

/// Please refer to [CFBListener] if you want to "do" anything in response to
/// `state` changes such as navigation, showing a dialog, etc...
///
/// If the [cfb] parameter is omitted, [CFBBuilder] will automatically
/// perform a lookup using [CFBProvider] and the current [BuildContext].
///
/// ```dart
/// CFBBuilder<CFBA, CFBAState>(
///   builder: (context, state) {
///   // return widget here based on CFBA's state
///   }
/// )
/// ```
///
/// Only specify the [cfb] if you wish to provide a [cfb] that is otherwise
/// not accessible via [CFBProvider] and the current [BuildContext].
///
/// ```dart
/// CFBBuilder<CFBA, CFBAState>(
///   cfb: cfbA,
///   builder: (context, state) {
///   // return widget here based on CFBA's state
///   }
/// )
/// ```
/// {@endtemplate}
///
/// {@template cfb_builder_build_when}
/// An optional [buildWhen] can be implemented for more granular control over
/// how often [CFBBuilder] rebuilds.
/// [buildWhen] should only be used for performance optimizations as it
/// provides no security about the state passed to the [builder] function.
/// [buildWhen] will be invoked on each [cfb] `state` change.
/// [buildWhen] takes the previous `state` and current `state` and must
/// return a [bool] which determines whether or not the [builder] function will
/// be invoked.
/// The previous `state` will be initialized to the `state` of the [cfb] when
/// the [CFBBuilder] is initialized.
/// [buildWhen] is optional and if omitted, it will default to `true`.
///
/// ```dart
/// CFBBuilder<CFBA, CFBAState>(
///   buildWhen: (previous, current) {
///     // return true/false to determine whether or not
///     // to rebuild the widget with state
///   },
///   builder: (context, state) {
///     // return widget here based on CFBA's state
///   }
/// )
/// ```
/// {@endtemplate}
class CFBBuilder<B extends StateStreamable<S>, S> extends CFBBuilderBase<B, S> {
  /// {@macro cfb_builder}
  /// {@macro cfb_builder_build_when}
  const CFBBuilder({
    required this.builder,
    Key? key,
    B? cfb,
    CFBBuilderCondition<S>? buildWhen,
  }) : super(key: key, cfb: cfb, buildWhen: buildWhen);

  /// The [builder] function which will be invoked on each widget build.
  /// The [builder] takes the `BuildContext` and current `state` and
  /// must return a widget.
  /// This is analogous to the [builder] function in [StreamBuilder].
  final CFBWidgetBuilder<S> builder;

  @override
  Widget build(BuildContext context, S state) => builder(context, state);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      ObjectFlagProperty<CFBWidgetBuilder<S>>.has('builder', builder),
    );
  }
}

/// {@template cfb_builder_base}
/// Base class for widgets that build themselves based on interaction with
/// a specified [cfb].
///
/// A [CFBBuilderBase] is stateful and maintains the state of the interaction
/// so far. The type of the state and how it is updated with each interaction
/// is defined by sub-classes.
/// {@endtemplate}
abstract class CFBBuilderBase<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  /// {@macro cfb_builder_base}
  const CFBBuilderBase({Key? key, this.cfb, this.buildWhen}) : super(key: key);

  /// The [cfb] that the [CFBBuilderBase] will interact with.
  /// If omitted, [CFBBuilderBase] will automatically perform a lookup using
  /// [CFBProvider] and the current `BuildContext`.
  final B? cfb;

  /// {@macro cfb_builder_build_when}
  final CFBBuilderCondition<S>? buildWhen;

  /// Returns a widget based on the `BuildContext` and current [state].
  Widget build(BuildContext context, S state);

  @override
  State<CFBBuilderBase<B, S>> createState() => _CFBBuilderBaseState<B, S>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<CFBBuilderCondition<S>?>.has(
          'buildWhen',
          buildWhen,
        ),
      )
      ..add(DiagnosticsProperty<B?>('cfb', cfb));
  }
}

class _CFBBuilderBaseState<B extends StateStreamable<S>, S>
    extends State<CFBBuilderBase<B, S>> {
  late B _cfb;
  late S _state;

  @override
  void initState() {
    super.initState();
    _cfb = widget.cfb ?? context.read<B>();
    _state = _cfb.state;
  }

  @override
  void didUpdateWidget(CFBBuilderBase<B, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCFB = oldWidget.cfb ?? context.read<B>();
    final currentCFB = widget.cfb ?? oldCFB;
    if (oldCFB != currentCFB) {
      _cfb = currentCFB;
      _state = _cfb.state;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cfb = widget.cfb ?? context.read<B>();
    if (_cfb != cfb) {
      _cfb = cfb;
      _state = _cfb.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cfb == null) {
      // Trigger a rebuild if the cfb reference has changed.
      // See https://github.com/felangel/cfb/issues/2127.
      context.select<B, bool>((cfb) => identical(_cfb, cfb));
    }
    return CFBListener<B, S>(
      cfb: _cfb,
      listenWhen: widget.buildWhen,
      listener: (context, state) => setState(() => _state = state),
      child: widget.build(context, _state),
    );
  }
}
