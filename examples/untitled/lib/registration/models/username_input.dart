// Extend FormzInput and provide the input type and error type.
import 'package:formz/formz.dart';
import 'package:untitled/extensions/extensions.dart';

enum UsernameInputError { empty, invalid, taken }

class UsernameInput extends FormzInput<String, UsernameInputError>
    with BeautyStringMixin {
  // Call super.pure to represent an unmodified form input.
  const UsernameInput.pure({String value = '', this.serverError})
      : super.pure(value);

  // Call super.dirty to represent a modified form input.
  const UsernameInput.dirty({String value = '', this.serverError})
      : super.dirty(value);

  final UsernameInputError? serverError;

  @override
  UsernameInputError? get displayError => isPure ? null : super.error;

  // Override validator to handle validating a given input value.
  @override
  UsernameInputError? validator(String value) {
    final error = serverError;
    if (error != null) return error;
    if (value.isEmpty) return UsernameInputError.empty;
    if (value.length < 4) return UsernameInputError.invalid;
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'value': value,
      'isPure': isPure,
      'displayError': displayError?.toString(),
      'error': error.toString(),
      'isValid': isValid,
    };
  }
}
