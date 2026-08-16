// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_constants.dart';
import 'core/app_info.dart';
import 'core/app_logger.dart';
import 'core/app_theme.dart';
import 'models/user_model.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_category_screen.dart';
import 'screens/add_subcategory_screen.dart';
import 'screens/view_users_screen.dart';
import 'screens/work_details_page.dart';
import 'screens/register_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/AboutUsPage.dart';
import 'screens/AdsManagementPage.dart';
import 'screens/DetailsPage.dart';
import 'screens/InsertDetailsPage.dart';
import 'screens/UsersPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.info('App starting — ${AppConstants.appName}', tag: 'MAIN');
    AppLogger.info('Base URL: ${AppConstants.baseUrl}', tag: 'MAIN');

    // Load app version from pubspec.yaml so any UI (drawer footer,
    // about page, etc.) can read it synchronously via AppInfo.version.
    await AppInfo.load();

    // Load saved language BEFORE runApp so locale is correct from frame 1
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('selectedLanguage') ?? 'ku';
    final savedError = prefs.getString(AppConstants.prefLastError);

    if (savedError != null) {
      AppLogger.warning('Last session error: $savedError', tag: 'MAIN');
      await prefs.remove(AppConstants.prefLastError);
    }

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      AppLogger.error('Flutter error caught',
          exception: details.exception, stack: details.stack, tag: 'MAIN');
      if (kReleaseMode) {
        await prefs.setString(
            AppConstants.prefLastError, details.exceptionAsString());
      }
    };

    runApp(AppRoot(initialError: savedError, initialLang: savedLang));
  }, (error, stack) async {
    AppLogger.error('Unhandled zone error',
        exception: error, stack: stack, tag: 'MAIN');
    final prefs = await SharedPreferences.getInstance();
    if (kReleaseMode) {
      await prefs.setString(AppConstants.prefLastError, error.toString());
    }
  });
}

// ── AppRoot ────────────────────────────────────────────────────

class AppRoot extends StatelessWidget {
  final String? initialError;
  final String initialLang;

  const AppRoot({
    this.initialError,
    this.initialLang = 'ku',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => UserModel()..loadUserFromPreferences()),
        ChangeNotifierProvider(create: (_) => LocaleProvider(initialLang)),
      ],
      child:
          ErrorHandler(initialError: initialError, child: const HarikarApp()),
    );
  }
}

// ── Error handler ──────────────────────────────────────────────

class ErrorHandler extends StatefulWidget {
  final String? initialError;
  final Widget child;
  const ErrorHandler(
      {required this.initialError, required this.child, Key? key})
      : super(key: key);

  @override
  _ErrorHandlerState createState() => _ErrorHandlerState();
}

class _ErrorHandlerState extends State<ErrorHandler> {
  @override
  void initState() {
    super.initState();
    if (widget.initialError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Unexpected Error',
                style: TextStyle(fontFamily: 'NotoKufi')),
            content: SingleChildScrollView(child: Text(widget.initialError!)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK',
                    style: TextStyle(
                        fontFamily: 'NotoKufi', color: AppTheme.primary)),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── LocaleProvider ─────────────────────────────────────────────
//
// KEY FIX:
// Flutter's built-in Material/Cupertino delegates do NOT support 'ku'.
// They support 'ar' fully (RTL, date formats, etc).
//
// Solution: we always use Locale('ar') as the actual Flutter locale for
// BOTH Kurdish and Arabic — this gives us RTL layout and proper delegates.
// The language displayed in the UI (Kurdish vs Arabic text) is controlled
// separately by checking SharedPreferences key 'selectedLanguage' directly
// in each screen via: Localizations.localeOf(context).languageCode
// — which we keep as 'ku' or 'ar' by storing it in prefs.
//
// This is the correct approach for unsupported locales in Flutter.

class LocaleProvider extends ChangeNotifier {
  // The actual Flutter locale used for delegates (always 'ar' for RTL)
  Locale _locale;

  // The display language code ('ku' or 'ar') — used by screens to pick text
  String _langCode;

  LocaleProvider([String code = 'ku'])
      : _locale = const Locale('ar', 'IQ'), // always ar for delegates
        _langCode = code;

  Locale get locale => _locale;
  String get langCode => _langCode;

  /// Switches the display language. [persist] writes the choice to
  /// SharedPreferences — pass false to apply a language for this session
  /// only, which the splash screen does while the first-launch picker is
  /// still on screen (saving there would count as a choice the user
  /// never made, and the picker would never appear again).
  Future<void> setLocale(Locale locale, {bool persist = true}) async {
    // locale.languageCode will be 'ku' or 'ar' (passed from splash screen)
    _langCode = locale.languageCode;
    // Keep actual Flutter locale as 'ar' always — gives us RTL + delegates
    _locale = const Locale('ar', 'IQ');

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selectedLanguage', _langCode);
    }
    AppLogger.info('Language set to $_langCode (saved: $persist)', tag: 'MAIN');
    notifyListeners();
  }
}

// ── HarikarApp ─────────────────────────────────────────────────

class HarikarApp extends StatelessWidget {
  const HarikarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Always use Arabic locale for Flutter's delegate system.
      // This gives us RTL layout and supported localizations.
      // The UI language (Kurdish vs Arabic text) is read from
      // LocaleProvider.langCode or SharedPreferences in each screen.
      locale: localeProvider.locale, // always Locale('ar','IQ')

      supportedLocales: const [
        Locale('ar', 'IQ'), // covers both Kurdish and Arabic UI
      ],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      localeResolutionCallback: (locale, supported) {
        // Always resolve to Arabic — Flutter supports it fully
        return const Locale('ar', 'IQ');
      },

      // SplashScreen is ALWAYS the first screen on every launch
      home: const SplashScreen(),

      routes: {
        '/splash': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forget_password': (_) => const ForgetPasswordScreen(),
        '/add_category': (_) => const AddCategoryScreen(),
        '/add_subcategory': (_) => const AddSubCategoryScreen(),
        '/view_users': (_) => const ViewUsersScreen(),
        '/show_work': (_) => const WorkDetailsPage(),
        '/show_details': (_) => const DetailsPage(),
        '/insert_details': (_) => const InsertDetailsPage(),
        '/user2': (_) => const UsersPage(),
        '/ads': (_) => const AdsManagementPage(),
        '/about': (_) => const AboutUsPage(),
      },
    );
  }
}

// ── Helper — use this in every screen instead of Localizations.localeOf ──
//
// OLD (broken for Kurdish):
//   final isArabic = Localizations.localeOf(context).languageCode == 'ar';
//
// NEW (correct):
//   final isArabic = context.isArabic;
//
// Add this extension to main.dart — it reads from LocaleProvider.langCode

extension LocaleContext on BuildContext {
  /// Returns true if the selected UI language is Arabic.
  /// Returns false if Kurdish (or any other language).
  ///
  /// IMPORTANT: this WATCHES [LocaleProvider] (default `listen: true`)
  /// so any widget that calls `context.isArabic` from its `build()`
  /// method will automatically rebuild when the user switches language
  /// from the drawer. Do not call from outside `build()` — capture the
  /// value into a local variable in `build()` and pass it down instead.
  bool get isArabic {
    try {
      return Provider.of<LocaleProvider>(this).langCode == 'ar';
    } catch (_) {
      return false;
    }
  }

  /// Returns the selected language code: 'ku' or 'ar'.
  /// Watches [LocaleProvider] — see notes on [isArabic].
  String get langCode {
    try {
      return Provider.of<LocaleProvider>(this).langCode;
    } catch (_) {
      return 'ku';
    }
  }
}
