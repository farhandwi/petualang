import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/community_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/rental_provider.dart';
import 'providers/explore_provider.dart';
import 'providers/open_trip_provider.dart';
import 'screens/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/main_wrapper.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Status bar style — will be overridden per-theme in the app
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Lock to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const PetualangApp());
}

class PetualangApp extends StatelessWidget {
  const PetualangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProxyProvider<AuthProvider, BookingProvider>(
          create: (context) => BookingProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) => BookingProvider(authProvider: auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CommunityProvider>(
          create: (_) => CommunityProvider(),
          update: (context, auth, provider) {
            provider!.setToken(auth.token);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => RentalProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (context, auth, provider) {
            provider!.setUser(
              token: auth.token,
              userId: auth.user?.id,
              name: auth.user?.name,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OpenTripProvider>(
          create: (context) => OpenTripProvider(authProvider: context.read<AuthProvider>()),
          update: (context, auth, previous) => OpenTripProvider(authProvider: auth),
        ),
        ChangeNotifierProvider(create: (_) => ExploreProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Make status bar icons adaptive to the current theme
          final isDark = themeProvider.themeMode == ThemeMode.dark ||
              (themeProvider.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );
          return MaterialApp(
            title: 'Petualang - Tiket Gunung & Sewa Alat',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const _AppEntry(),
          );
        },
      ),
    );
  }
}

/// Handles initial routing based on auth status
class _AppEntry extends StatelessWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return switch (auth.status) {
      AuthStatus.initial || AuthStatus.loading => const _SplashScreen(),
      AuthStatus.onboarding => const OnboardingScreen(),
      AuthStatus.authenticated => const MainWrapper(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.primaryOrange,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.landscape_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: AppTheme.primaryOrange,
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
