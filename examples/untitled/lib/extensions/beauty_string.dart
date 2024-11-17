import 'dart:convert';

abstract class Mapable {
  Map<String, dynamic> toMap();
}

mixin BeautyStringMixin implements Mapable {
  static JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  // static JsonDecoder decoder = const JsonDecoder();

  @override
  Map<String, dynamic> toMap();

  // @override
  // String toString() => json.encode(toMap());

  @override
  String toString() => encoder.convert(toMap());
}
