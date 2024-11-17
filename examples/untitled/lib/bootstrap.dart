import 'dart:async';
import 'dart:developer' as developer;

import 'package:cfb/cfb.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  if (kDebugMode) {
    return print(message);
  }
  return developer.log(message);
}

class AppCFBObserver extends CFBObserver {
  const AppCFBObserver();

  @override
  void onEvent(CFB<dynamic, dynamic> cfb, Object? event) {
    super.onEvent(cfb, event);
    log('onEvent(${cfb.runtimeType}, $event)');
  }

  @override
  void onChange(CFBBase<dynamic> cfb, Change<dynamic> change) {
    super.onChange(cfb, change);
    log('onChange(${cfb.runtimeType}, $change)');
  }

  @override
  void onError(CFBBase<dynamic> cfb, Object error, StackTrace stackTrace) {
    log('onError(${cfb.runtimeType}, $error, $stackTrace)');
    super.onError(cfb, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  CFB.observer = const AppCFBObserver();

  // Add cross-flavor configuration here

  runApp(await builder());
}
