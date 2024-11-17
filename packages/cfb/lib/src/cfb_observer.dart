import 'package:cfb/cfb.dart';
import 'package:meta/meta.dart';

/// {@template cfb_observer}
/// An interface for observing the behavior of [CFB] instances.
/// {@endtemplate}
abstract class CFBObserver {
  /// {@macro cfb_observer}
  const CFBObserver();

  /// Called whenever a [CFB] is instantiated.
  /// In many cases, a cfb may be lazily instantiated and
  /// [onCreate] can be used to observe exactly when the cfb
  /// instance is created.
  @protected
  @mustCallSuper
  void onCreate(CFBBase<dynamic> cfb) {}

  /// Called whenever an [event] is `added` to any [cfb] with the given [cfb]
  /// and [event].
  @protected
  @mustCallSuper
  void onEvent(CFB<dynamic, dynamic> cfb, Object? event) {}

  /// Called whenever a [Change] occurs in any [cfb]
  /// A [change] occurs when a new state is emitted.
  /// [onChange] is called before a cfb's state has been updated.
  @protected
  @mustCallSuper
  void onChange(CFBBase<dynamic> cfb, Change<dynamic> change) {}

  /// Called whenever a transition occurs in any [cfb] with the given [cfb]
  /// and [transition].
  /// A [transition] occurs when a new `event` is added
  /// and a new state is `emitted` from a corresponding [EventHandler].
  /// [onTransition] is called before a [cfb]'s state has been updated.
  @protected
  @mustCallSuper
  void onTransition(
    CFB<dynamic, dynamic> cfb,
    Transition<dynamic, dynamic> transition,
  ) {}

  /// Called whenever an [error] is thrown in any [CFB].
  /// The [stackTrace] argument may be [StackTrace.empty] if an error
  /// was received without a stack trace.
  @protected
  @mustCallSuper
  void onError(CFBBase<dynamic> cfb, Object error, StackTrace stackTrace) {}

  /// Called whenever a [CFB] is closed.
  /// [onClose] is called just before the [CFB] is closed
  /// and indicates that the particular instance will no longer
  /// emit new states.
  @protected
  @mustCallSuper
  void onClose(CFBBase<dynamic> cfb) {}
}
