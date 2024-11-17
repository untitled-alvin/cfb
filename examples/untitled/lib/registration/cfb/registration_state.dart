part of 'registration_cfb.dart';

enum RegistrationStatus { editing, submitting, failed, succeeded }

class RegistrationState extends Equatable with BeautyStringMixin {
  const RegistrationState({
    required this.username,
    required this.isCheckingUsername,
    required this.status,
  });

  const RegistrationState.initial()
      : this(
          username: const UsernameInput.pure(),
          isCheckingUsername: false,
          status: RegistrationStatus.editing,
        );

  final UsernameInput username;
  final bool isCheckingUsername;
  final RegistrationStatus status;

  bool get isBusy {
    return isCheckingUsername || status == RegistrationStatus.submitting;
  }

  bool get canSubmit => Formz.validate([username]) == true && !isBusy;

  @override
  List<Object> get props => [username, isCheckingUsername, status];

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'username': username.toMap(),
      'isCheckingUsername': isCheckingUsername,
      'status': '$status',
    };
  }
}
