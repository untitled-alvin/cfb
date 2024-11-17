import 'package:cfb/cfb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// {@template cfb_provider}
/// Takes a [Create] function that is responsible for
/// creating the [CFB] and a [child] which will have access
/// to the instance via `CFBProvider.of(context)`.
/// It is used as a dependency injection (DI) widget so that a single instance
/// of a [CFB] can be provided to multiple widgets within a subtree.
///
/// ```dart
/// CFBProvider(
///   create: (BuildContext context) => CFBA(),
///   child: ChildA(),
/// );
/// ```
///
/// It automatically handles closing the instance when used with [Create].
/// By default, [Create] is called only when the instance is accessed.
/// To override this behavior, set [lazy] to `false`.
///
/// ```dart
/// CFBProvider(
///   lazy: false,
///   create: (BuildContext context) => CFBA(),
///   child: ChildA(),
/// );
/// ```
///
/// {@endtemplate}
class CFBProvider<T extends StateStreamableSource<Object?>>
    extends SingleChildStatelessWidget {
  /// {@macro cfb_provider}
  const CFBProvider({
    required Create<T> create,
    Key? key,
    this.child,
    this.lazy = true,
  })  : _create = create,
        _value = null,
        super(key: key, child: child);

  /// Takes a [value] and a [child] which will have access to the [value] via
  /// `CFBProvider.of(context)`.
  /// When `CFBProvider.value` is used, the [CFB]
  /// will not be automatically closed.
  /// As a result, `CFBProvider.value` should only be used for providing
  /// existing instances to new subtrees.
  ///
  /// A new [CFB] should not be created in `CFBProvider.value`.
  /// New instances should always be created using the
  /// default constructor within the [Create] function.
  ///
  /// ```dart
  /// CFBProvider.value(
  ///   value: CFBProvider.of<CFBA>(context),
  ///   child: ScreenA(),
  /// );
  /// ```
  const CFBProvider.value({
    required T value,
    Key? key,
    this.child,
  })  : _value = value,
        _create = null,
        lazy = true,
        super(key: key, child: child);

  /// Widget which will have access to the [CFB].
  final Widget? child;

  /// Whether the [CFB] should be created lazily.
  /// Defaults to `true`.
  final bool lazy;

  final Create<T>? _create;

  final T? _value;

  /// Method that allows widgets to access a [CFB] instance
  /// as long as their `BuildContext` contains a [CFBProvider] instance.
  ///
  /// If we want to access an instance of `CFBA` which was provided higher up
  /// in the widget tree we can do so via:
  ///
  /// ```dart
  /// CFBProvider.of<CFBA>(context);
  /// ```
  static T of<T extends StateStreamableSource<Object?>>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError(
        '''
        CFBProvider.of() called with a context that does not contain a $T.
        No ancestor could be found starting from the context that was passed to CFBProvider.of<$T>().

        This can happen if the context you used comes from a widget above the CFBProvider.

        The context used was: $context
        ''',
      );
    }
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    assert(
      child != null,
      '$runtimeType used outside of MultiCFBProvider must specify a child',
    );
    final value = _value;
    return value != null
        ? InheritedProvider<T>.value(
            value: value,
            startListening: _startListening,
            lazy: lazy,
            child: child,
          )
        : InheritedProvider<T>(
            create: _create,
            dispose: (_, cfb) => cfb.close(),
            startListening: _startListening,
            lazy: lazy,
            child: child,
          );
  }

  static VoidCallback _startListening(
    InheritedContext<StateStreamable<dynamic>?> e,
    StateStreamable<dynamic> value,
  ) {
    final subscription = value.stream.listen(
      (dynamic _) => e.markNeedsNotifyDependents(),
    );
    return subscription.cancel;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('lazy', lazy));
  }
}
