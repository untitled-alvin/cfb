import 'package:flutter/material.dart';
import 'package:flutter_cfb/flutter_cfb.dart';
import 'package:untitled/l10n/l10n.dart';
import 'package:untitled/registration/registration.dart';

class Registration extends StatelessWidget {
  const Registration({super.key});

  @override
  Widget build(BuildContext context) {
    return CFBProvider(
      create: (_) => RegistrationCFB(
        registrationRepo: RegistrationRepo(),
      ),
      child: const RegistrationView(),
    );
  }
}

class RegistrationView extends StatelessWidget {
  const RegistrationView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.registrationViewTitleNew,
        ),
      ),
      body: CFBListener<RegistrationCFB, RegistrationState>(
        listenWhen: (previous, current) =>
            previous.status == RegistrationStatus.submitting &&
            current.status != RegistrationStatus.submitting,
        listener: (context, state) {
          final colorScheme = Theme.of(context).colorScheme;
          if (state.status == RegistrationStatus.failed) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.registrationViewError),
                  backgroundColor: colorScheme.error,
                ),
              );
          } else if (state.status == RegistrationStatus.succeeded) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.registrationViewSuccess),
                  backgroundColor: colorScheme.secondary,
                ),
              );
          }
        },
        child: const Form(
          child: Padding(
            padding: EdgeInsets.only(left: 32, right: 32, top: 32),
            child: Column(
              children: [UsernameField(), SubmitButton()],
            ),
          ),
        ),
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return CFBBuilder<RegistrationCFB, RegistrationState>(
      builder: (context, state) {
        if (state.status == RegistrationStatus.submitting) {
          return const CircularProgressIndicator();
        }

        return ElevatedButton(
          onPressed: state.canSubmit
              ? () => context
                  .read<RegistrationCFB>()
                  .add(const RegistrationSubmitted())
              : null,
          child: Text(l10n.registrationRegister),
        );
      },
    );
  }
}

class UsernameField extends StatelessWidget {
  const UsernameField({super.key});

  String? _usernameError(BuildContext context, UsernameInput username) {
    final l10n = context.l10n;
    final error = username.displayError;
    if (error == null) return null;
    if (error == UsernameInputError.empty) {
      return l10n.registrationUsernameEmpty;
    } else if (error == UsernameInputError.invalid) {
      return l10n.registrationUsernameInvalid;
    } else if (error == UsernameInputError.taken) {
      return l10n.registrationUsernameTaken(username.value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ConstrainedBox(
      constraints: BoxConstraints.tight(const Size.fromHeight(120)),
      child: CFBBuilder<RegistrationCFB, RegistrationState>(
        builder: (context, state) {
          return TextField(
            autocorrect: false,
            onChanged: (value) => context
                .read<RegistrationCFB>()
                .add(RegistrationUsernameChanged(username: value)),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(16),
              errorText: _usernameError(context, state.username),
              labelText: l10n.registrationUsername,
              helperText: state.canSubmit
                  ? l10n.registrationUsernameAvailable(state.username.value)
                  : null,
              filled: true,
              prefixIcon: const Icon(Icons.person),
              suffix: state.isCheckingUsername
                  ? ConstrainedBox(
                      constraints: BoxConstraints.tight(const Size(15, 15)),
                      child: const CircularProgressIndicator(strokeWidth: 3),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
