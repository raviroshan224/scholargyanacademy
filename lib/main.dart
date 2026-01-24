
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- IMPORTANT (SystemChrome import)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholarsgyanacademy/config/services/navigation_service.dart';
import 'package:scholarsgyanacademy/config/themes/app_themes.dart';
import 'package:scholarsgyanacademy/features/auth/view/pages/login_page.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/auth_state.dart';
import 'package:scholarsgyanacademy/features/auth/view_model/providers/auth_providers.dart';
import 'package:scholarsgyanacademy/features/dashboard/presentation/pages/dashboard.dart';
import 'package:scholarsgyanacademy/server_config/config.dart';
import 'package:upgrader/upgrader.dart';

import 'config/dependencies/dependency_injection.dart';
import 'config/dependencies/notification/local_notification_manager.dart';
import 'config/local_db/hive/hive_setup.dart';


import 'network_layer/src/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ----------- NEW: Fix UI cut off (Full screen mode) ---------------
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  // -----------------------------------------------------------------

  Config.setEnvironment(env: Env.PROD);

  await setup();

  runApp(const RootApp());
}

Future<void> setup() async {
  ApiConfig().setApiAuthority(baseUrl: Config.OLP_SERVER);



  // Initialize local persistence (Hive)
  await HiveSetup.initializeHive();

  // Initialize local notifications
  try {
    await LocalNotificationManager.initialize();
  } catch (e, stackTrace) {
    debugPrint('Warning: local notification initialization failed: $e');
    debugPrint(stackTrace.toString());
  }

  DependencyInjection.init();
}

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  Key _providerKey = UniqueKey();

  void resetProviders() {
    setState(() {
      _providerKey = UniqueKey(); // 🔥 disposes ALL providers
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _providerKey,
      child: MyApp(onLogout: resetProviders),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key, required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    ref.read(authNotifierProvider.notifier).setLogoutCallback(onLogout);

    return UpgradeAlert(
      child: Consumer(
        builder: (context, ref, _) {
          final navService = ref.read(navigationServiceProvider);

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "OLP",
            theme: AppThemes.lightTheme,
            navigatorKey: navService.navigatorKey,
            home: _resolveHome(authState),
            builder: (context, child) {
              return SafeArea(
                top: true,
                bottom: true,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }

  Widget _resolveHome(AuthState authState) {
    if (!authState.hasCompletedStartupCheck) {
      return const SplashPage();
    }

    final bool shouldShowDashboard =
        authState.user != null &&
        authState.status != AuthStatus.unauthenticated;

    if (shouldShowDashboard) {
      return const Dashboard();
    }

    return const LoginScreen();
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).checkAuthenticationOnStartup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
