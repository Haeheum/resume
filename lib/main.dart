import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:resume/src/config/theme_extension.dart';

import 'src/model/app_state_model.dart';
import 'src/presentation/scope/app_state_scope.dart';
import 'src/presentation/audio/audio_controller.dart';
import 'src/presentation/home/home.dart';

void main() {
  timeDilation = 1;
  runApp(
    const AudioController(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  static MainAppState of(BuildContext context) {
    return context.findAncestorStateOfType<MainAppState>()!;
  }

  @override
  State<MainApp> createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  static const _appSchemeColor = Color(0xFFA6C93C);
  final AppStateModel _appState = AppStateModel();

  void setLanguageCode(String newLanguageCode) {
    _appState.setLanguageCode(newLanguageCode);
  }

  void toggleThemeMode() {
    _appState.toggleThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: Builder(builder: (context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: Locale(AppStateScope.of(context).languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Home(),
          theme: ThemeData(
            colorSchemeSeed: _appSchemeColor,
            extensions: const [
              ExtensionColors(
                matrixTitleColor: Color(0xFF1B3F09),
                matrixShadowColor: Color(0xFF367523),
              ),
            ],
            fontFamily: 'Exo',
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: _appSchemeColor,
            ),
            extensions: const [
              ExtensionColors(
                matrixTitleColor: Color(0xFFF4F4F5),
                matrixShadowColor: Color(0xFF49C921),
              ),
            ],
            fontFamily: 'Exo',
          ),
          themeMode: AppStateScope.of(context).themeMode,
        );
      }),
    );
  }
}
