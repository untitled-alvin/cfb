import 'package:cfb/cfb.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:rxdart/rxdart.dart';
import 'package:untitled/extensions/extensions.dart';
import 'package:untitled/registration/registration.dart';

part 'registration_events.dart';
part 'registration_state.dart';

class RegistrationCFB extends CFB<RegistrationEvent, RegistrationState> {
  RegistrationCFB({
    required this.registrationRepo,
  }) : super(const RegistrationState.initial()) {
    on<RegistrationUsernameChanged>(
      _onRegistrationUsernameChanged,
      transformer: debounceRestartable(
        RegistrationCFB.debounceUsernameDuration,
      ),
    );
    on<RegistrationSubmitted>(
      _onRegistrationSubmitted,
      transformer: sequential(),
    );
  }

  final RegistrationRepo registrationRepo;

  // How long to wait after the last key press event before checking
  // username availability.
  static const debounceUsernameDuration = Duration(milliseconds: 400);

  EventTransformer<RegistrationEvent> debounceRestartable<RegistrationEvent>(
    Duration duration,
  ) {
    return (events, mapper) => restartable<RegistrationEvent>()
        .call(events.debounceTime(duration), mapper);
  }

  Future<void> _onRegistrationUsernameChanged(
    RegistrationUsernameChanged event,
    Emitter<RegistrationState> emit,
  ) async {
    var username = UsernameInput.dirty(value: event.username);
    emit(
      RegistrationState(
        username: username,
        isCheckingUsername: username.isValid,
        status: state.status,
      ),
    );
    if (username.isValid) {
      final isUsernameAvailable =
          await registrationRepo.isUsernameAvailable(username.value);
      if (!isUsernameAvailable) {
        username = UsernameInput.dirty(
          value: event.username,
          serverError: UsernameInputError.taken,
        );
      }
      emit(
        RegistrationState(
          username: username,
          isCheckingUsername: false,
          status: state.status,
        ),
      );
    }
  }

  Future<void> _onRegistrationSubmitted(
    RegistrationSubmitted event,
    Emitter<RegistrationState> emit,
  ) async {
    final username = state.username.value;
    try {
      emit(
        RegistrationState(
          username: state.username,
          isCheckingUsername: false,
          status: RegistrationStatus.submitting,
        ),
      );
      await registrationRepo.register(
        username: username,
      );
      emit(
        RegistrationState(
          username: state.username,
          isCheckingUsername: false,
          status: RegistrationStatus.succeeded,
        ),
      );
    } catch (e) {
      // Check for specific backend error that indicates a taken username.
      if (e is ArgumentError && state.username.value == username) {
        emit(
          RegistrationState(
            username: UsernameInput.dirty(
              value: username,
              serverError: UsernameInputError.taken,
            ),
            isCheckingUsername: state.isCheckingUsername,
            status: RegistrationStatus.failed,
          ),
        );
      } else {
        emit(
          RegistrationState(
            username: state.username,
            isCheckingUsername: state.isCheckingUsername,
            status: RegistrationStatus.failed,
          ),
        );
      }
    }
  }
}
