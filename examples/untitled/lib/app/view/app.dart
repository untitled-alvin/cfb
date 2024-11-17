import 'package:flutter/material.dart';
import 'package:untitled/l10n/l10n.dart';
// import 'package:untitled/profile/profile_view.dart';
import 'package:untitled/registration/view/registration_view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Registration(),
    );
  }
}
