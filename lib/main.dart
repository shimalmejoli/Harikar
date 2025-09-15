// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final prefs = await SharedPreferences.getInstance();
    final String? lastError = prefs.getString('last_error');
    if (lastError != null) {
      await prefs.remove('last_error');
    }

    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.presentError(details);
      if (kReleaseMode) {
        await prefs.setString('last_error', details.exceptionAsString());
      }
    };

    runApp(AppRoot(initialError: lastError));
  }, (error, stack) async {
    final prefs = await SharedPreferences.getInstance();
    if (kReleaseMode) {
      await prefs.setString('last_error', error.toString());
    }
  });
}

class AppRoot extends StatelessWidget {
  final String? initialError;
  const AppRoot({this.initialError, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => UserModel()..loadUserFromPreferences()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: ErrorHandler(initialError: initialError, child: HarikarApp()),
    );
  }
}

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
        showDialog(
          context: navigatorKey.currentState!.overlay!.context,
          builder: (_) => AlertDialog(
            title: const Text('Unexpected Error'),
            content: SingleChildScrollView(child: Text(widget.initialError!)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
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

class LocaleProvider extends ChangeNotifier {
  Locale _locale;
  LocaleProvider([String code = 'en'])
      : _locale = Locale(code, code == 'en' ? 'IQ' : '');

  Locale get locale => _locale;

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
    notifyListeners();
  }
}

class HarikarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'ليگريان كارێ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoKufi',
        primarySwatch: Colors.deepPurple,
      ),
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en', 'IQ'),
        Locale('ar', 'IQ'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale != null) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode) {
              return supportedLocale;
            }
          }
        }
        return const Locale('en', 'IQ');
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: SplashScreen(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/dashboard': (_) => DashboardScreen(),
        '/add_category': (_) => AddCategoryScreen(),
        '/add_subcategory': (_) => AddSubCategoryScreen(),
        '/view_users': (_) => ViewUsersScreen(),
        '/show_work': (_) => WorkDetailsPage(),
        '/register': (_) => RegisterScreen(),
        '/forget_password': (_) => ForgetPasswordScreen(),
        '/show_details': (_) => DetailsPage(),
        '/insert_details': (_) => InsertDetailsPage(),
        '/user2': (_) => UsersPage(),
        '/ads': (_) => AdsManagementPage(),
        '/about': (_) => AboutUsPage(),
      },
    );
  }
}
