# Cfb

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]


Package manages state in the application copied from BLOC .

### CFB

![CFB Architecture]

A `CFB` is a more advanced class which relies on `events` to trigger `state` changes rather than functions. `CFB` also extends `CFBBase` which means it has a similar public API as `Cubit`. However, rather than calling a `function` on a `CFB` and directly emitting a new `state`, `CFBs` receive `events` and convert the incoming `events` into outgoing `states`.

![CFB Flow]

State changes in cfb begin when events are added which triggers `onEvent`. The events are then funnelled through an `EventTransformer`. By default, each event is processed concurrently but a custom `EventTransformer` can be provided to manipulate the incoming event stream. All registered `EventHandlers` for that event type are then invoked with the incoming event. Each `EventHandler` is responsible for emitting zero or more states in response to the event. Lastly, `onTransition` is called just before the state is updated and contains the current state, event, and next state.

#### Creating a CFB

```dart
/// The events which `CounterCFB` will react to.
sealed class CounterEvent {}

/// Notifies cfb to increment state.
final class CounterIncrementPressed extends CounterEvent {}

/// A `CounterCFB` which handles converting `CounterEvent`s into `int`s.
class CounterCFB extends CFB<CounterEvent, int> {
  /// The initial state of the `CounterCFB` is 0.
  CounterCFB() : super(0) {
    /// When a `CounterIncrementPressed` event is added,
    /// the current `state` of the cfb is accessed via the `state` property
    /// and a new state is emitted via `emit`.
    on<CounterIncrementPressed>((event, emit) => emit(state + 1));
  }
}
```

#### Using a CFB

```dart
Future<void> main() async {
  /// Create a `CounterCFB` instance.
  final cfb = CounterCFB();

  /// Access the state of the `cfb` via `state`.
  print(cfb.state); // 0

  /// Interact with the `cfb` to trigger `state` changes.
  cfb.add(CounterIncrementPressed());

  /// Wait for next iteration of the event-loop
  /// to ensure event has been processed.
  await Future.delayed(Duration.zero);

  /// Access the new `state`.
  print(cfb.state); // 1

  /// Close the `cfb` when it is no longer needed.
  await cfb.close();
}
```

#### Observing a CFB

Since all `CFBs` extend `CFBBase` just like `Cubit`, `onChange` and `onError` can be overridden in a `CFB` as well.

In addition, `CFBs` can also override `onEvent` and `onTransition`.

`onEvent` is called any time a new `event` is added to the `CFB`.

`onTransition` is similar to `onChange`, however, it contains the `event` which triggered the state change in addition to the `currentState` and `nextState`.

```dart
sealed class CounterEvent {}

final class CounterIncrementPressed extends CounterEvent {}

class CounterCFB extends CFB<CounterEvent, int> {
  CounterCFB() : super(0) {
    on<CounterIncrementPressed>((event, emit) => emit(state + 1));
  }

  @override
  void onEvent(CounterEvent event) {
    super.onEvent(event);
    print(event);
  }

  @override
  void onChange(Change<int> change) {
    super.onChange(change);
    print(change);
  }

  @override
  void onTransition(Transition<CounterEvent, int> transition) {
    super.onTransition(transition);
    print(transition);
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    print('$error, $stackTrace');
    super.onError(error, stackTrace);
  }
}
```

`CFBObserver` can be used to observe all `cfbs` as well.

```dart
class MyCFBObserver extends CFBObserver {
  @override
  void onCreate(CFBBase cfb) {
    super.onCreate(cfb);
    print('onCreate -- ${cfb.runtimeType}');
  }

  @override
  void onEvent(CFB cfb, Object? event) {
    super.onEvent(cfb, event);
    print('onEvent -- ${cfb.runtimeType}, $event');
  }

  @override
  void onChange(CFBBase cfb, Change change) {
    super.onChange(cfb, change);
    print('onChange -- ${cfb.runtimeType}, $change');
  }

  @override
  void onTransition(CFB cfb, Transition transition) {
    super.onTransition(cfb, transition);
    print('onTransition -- ${cfb.runtimeType}, $transition');
  }

  @override
  void onError(CFBBase cfb, Object error, StackTrace stackTrace) {
    print('onError -- ${cfb.runtimeType}, $error');
    super.onError(cfb, error, stackTrace);
  }

  @override
  void onClose(CFBBase cfb) {
    super.onClose(cfb);
    print('onClose -- ${cfb.runtimeType}');
  }
}
```

```dart
void main() {
  CFB.observer = MyCFBObserver();
  // Use cfbs...
}
```

## Dart Versions

- Dart 2: >= 2.12

## Examples
