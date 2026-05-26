import 'dart:async';
import 'dart:ui';

import 'package:ad_manager/ad_manager.dart';
import 'package:spin_craze/db/app_db.dart';
import 'package:spin_craze/di/injector.dart';
import 'package:spin_craze/features/home_module/provider/home_provider.dart';
import 'package:spin_craze/firebase_options.dart';
import 'package:spin_craze/l10n/app_localizations.dart';
import 'package:spin_craze/res/theme_dark.dart';
import 'package:spin_craze/res/theme_light.dart';
import 'package:spin_craze/routes/app_router.dart';
import 'package:spin_craze/services/notification_service/notification_helper.dart';
import 'package:spin_craze/utils/crashlytics_manager.dart';
import 'package:spin_craze/utils/remote_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FlutterError.onError = (details) {
    unawaited(CrashlyticsManager.instance.logFlutterError(details));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      CrashlyticsManager.instance.logHandledDartError(
        error: error,
        stackTrace: stack,
      ),
    );
    return true;
  };
  await NotificationHelper.initializeNotification();
  await Hive.initFlutter();
  Injector.initModules();

  await Injector.instance.isReady<AppDB>();
  await GoogleSignIn.instance.initialize();
  await RemoteConfigService.instance.init();
  await MobileAds.instance.initialize();
  await GmaMediationUnity().setCCPAConsent(true);
  await GmaMediationUnity().setGDPRConsent(true);
  // Lock orientation (portrait only)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ClipEarnApp());
}

class ClipEarnApp extends StatefulWidget {
  const ClipEarnApp({super.key});

  @override
  State<ClipEarnApp> createState() => _ClipEarnAppState();
}

class _ClipEarnAppState extends State<ClipEarnApp> {
  final AppDB _db = Injector.instance<AppDB>();
  late StreamSubscription<dynamic> _languageSub;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _db.selectedLanguage;
    // Listen to Hive changes on the selectedLanguage key so the app rebuilds
    // with the new locale immediately when the user picks a language.
    _languageSub = _db.languageListenable().listen((event) {
      final newLang = _db.selectedLanguage;
      if (newLang != _selectedLanguage) {
        setState(() {
          _selectedLanguage = newLang;
        });
      }
    });
  }

  @override
  void dispose() {
    _languageSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale =
        _selectedLanguage != null ? Locale(_selectedLanguage!) : null;

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => HomeProvider())],
      child: ScreenUtilInit(
        designSize: const Size(375, 843),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Spin Craze',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            routerConfig: appRouter,
            scaffoldMessengerKey: sfMessengerKey,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('es'), // Español
              Locale('de'), // Deutsch
              Locale('fr'), // Français
              Locale('ar'), // العربية
              Locale('hi'), // हिन्दी
              Locale('pt'), // Português
              Locale('nl'), // Nederlands
              Locale('sw'), // Kiswahili
              Locale('fil'), // Filipino
              Locale('ms'), // Bahasa Melayu
            ],
          );
        },
      ),
    );
  }
}
