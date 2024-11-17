# Flutter Cfb

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

Widgets that make it easy to integrate cfb into Flutter. Built to work with cfb.

_\*Note: All widgets exported by the `flutter_cfb` package integrate with `CFB` instances._

## CFB Widgets

### CFBBuilder

**CFBBuilder** is a Flutter widget which requires a `cfb` and a `builder` function. `CFBBuilder` handles building the widget in response to new states. `CFBBuilder` is very similar to `StreamBuilder` but has a more simple API to reduce the amount of boilerplate code needed. The `builder` function will potentially be called many times and should be a [pure function](https://en.wikipedia.org/wiki/Pure_function) that returns a widget in response to the state.

See `CFBListener` if you want to "do" anything in response to state changes such as navigation, showing a dialog, etc...

If the `cfb` parameter is omitted, `CFBBuilder` will automatically perform a lookup using `CFBProvider` and the current `BuildContext`.

```dart
CFBBuilder<CFBA, CFBAState>(
  builder: (context, state) {
    // return widget here based on CFBA's state
  }
)
```

Only specify the cfb if you wish to provide a cfb that will be scoped to a single widget and isn't accessible via a parent `CFBProvider` and the current `BuildContext`.

```dart
CFBBuilder<CFBA, CFBAState>(
  cfb: cfbA, // provide the local cfb instance
  builder: (context, state) {
    // return widget here based on CFBA's state
  }
)
```

For fine-grained control over when the `builder` function is called an optional `buildWhen` can be provided. `buildWhen` takes the previous cfb state and current cfb state and returns a boolean. If `buildWhen` returns true, `builder` will be called with `state` and the widget will rebuild. If `buildWhen` returns false, `builder` will not be called with `state` and no rebuild will occur.

```dart
CFBBuilder<CFBA, CFBAState>(
  buildWhen: (previousState, state) {
    // return true/false to determine whether or not
    // to rebuild the widget with state
  },
  builder: (context, state) {
    // return widget here based on CFBA's state
  }
)
```

### CFBSelector

**CFBSelector** is a Flutter widget which is analogous to `CFBBuilder` but allows developers to filter updates by selecting a new value based on the current cfb state. Unnecessary builds are prevented if the selected value does not change. The selected value must be immutable in order for `CFBSelector` to accurately determine whether `builder` should be called again.

If the `cfb` parameter is omitted, `CFBSelector` will automatically perform a lookup using `CFBProvider` and the current `BuildContext`.

```dart
CFBSelector<CFBA, CFBAState, SelectedState>(
  selector: (state) {
    // return selected state based on the provided state.
  },
  builder: (context, state) {
    // return widget here based on the selected state.
  },
)
```

### CFBProvider

**CFBProvider** is a Flutter widget which provides a cfb to its children via `CFBProvider.of<T>(context)`. It is used as a dependency injection (DI) widget so that a single instance of a cfb can be provided to multiple widgets within a subtree.

In most cases, `CFBProvider` should be used to create new cfbs which will be made available to the rest of the subtree. In this case, since `CFBProvider` is responsible for creating the cfb, it will automatically handle closing it.

```dart
CFBProvider(
  create: (BuildContext context) => CFBA(),
  child: ChildA(),
);
```

By default, CFBProvider will create the cfb lazily, meaning `create` will get executed when the cfb is looked up via `CFBProvider.of<CFBA>(context)`.

To override this behavior and force `create` to be run immediately, `lazy` can be set to `false`.

```dart
CFBProvider(
  lazy: false,
  create: (BuildContext context) => CFBA(),
  child: ChildA(),
);
```

In some cases, `CFBProvider` can be used to provide an existing cfb to a new portion of the widget tree. This will be most commonly used when an existing `cfb` needs to be made available to a new route. In this case, `CFBProvider` will not automatically close the cfb since it did not create it.

```dart
CFBProvider.value(
  value: CFBProvider.of<CFBA>(context),
  child: ScreenA(),
);
```

then from either `ChildA`, or `ScreenA` we can retrieve `CFBA` with:

```dart
// with extensions
context.read<CFBA>();

// without extensions
CFBProvider.of<CFBA>(context);
```

The above snippets result in a one time lookup and the widget will not be notified of changes. To retrieve the instance and subscribe to subsequent state changes use:

```dart
// with extensions
context.watch<CFBA>();

// without extensions
CFBProvider.of<CFBA>(context, listen: true);
```

In addition, `context.select` can be used to retrieve part of a state and react to changes only when the selected part changes.

```dart
final isPositive = context.select((CounterCFB b) => b.state >= 0);
```

The snippet above will only rebuild if the state of the `CounterCFB` changes from positive to negative or vice versa and is functionally identical to using a `CFBSelector`.

### CFBListener

**CFBListener** is a Flutter widget which takes a `CFBWidgetListener` and an optional `cfb` and invokes the `listener` in response to state changes in the cfb. It should be used for functionality that needs to occur once per state change such as navigation, showing a `SnackBar`, showing a `Dialog`, etc...

`listener` is only called once for each state change (**NOT** including the initial state) unlike `builder` in `CFBBuilder` and is a `void` function.

If the cfb parameter is omitted, `CFBListener` will automatically perform a lookup using `CFBProvider` and the current `BuildContext`.

```dart
CFBListener<CFBA, CFBAState>(
  listener: (context, state) {
    // do stuff here based on CFBA's state
  },
  child: Container(),
)
```

Only specify the cfb if you wish to provide a cfb that is otherwise not accessible via `CFBProvider` and the current `BuildContext`.

```dart
CFBListener<CFBA, CFBAState>(
  cfb: cfbA,
  listener: (context, state) {
    // do stuff here based on CFBA's state
  }
)
```

For fine-grained control over when the `listener` function is called an optional `listenWhen` can be provided. `listenWhen` takes the previous cfb state and current cfb state and returns a boolean. If `listenWhen` returns true, `listener` will be called with `state`. If `listenWhen` returns false, `listener` will not be called with `state`.

```dart
CFBListener<CFBA, CFBAState>(
  listenWhen: (previousState, state) {
    // return true/false to determine whether or not
    // to call listener with state
  },
  listener: (context, state) {
    // do stuff here based on CFBA's state
  },
  child: Container(),
)
```

## Dart Versions

- Dart 2: >= 2.12


## Examples

- [Untitled](https://github.com/untitled-alvin/cfb/tree/main/examples/untitled) - an example of how to use a `CFB` in a pure Dart app.
