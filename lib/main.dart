import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:deltabooks/l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/invitation_provider.dart';
import 'providers/library_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const DeltaBooksApp());
}

class DeltaBooksApp extends StatelessWidget {
  const DeltaBooksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            title: 'DeltaBooks',
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ro'),
            ],
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: AppColors.deepSeaBlue,
                secondary: AppColors.riverMist,
                tertiary: AppColors.goldLeaf,
                surface: AppColors.white,
                surfaceContainerHighest: AppColors.riverMist,
                onPrimary: AppColors.white,
                onSecondary: AppColors.deltaTeal,
                onSurface: AppColors.deltaTeal,
                onSurfaceVariant: AppColors.textSecondary,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: Colors.white,
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.borderLight, width: 1),
                ),
                color: AppColors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shadowColor: AppColors.deltaTeal.withOpacity(0.1),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: false,
                backgroundColor: AppColors.deepSeaBlue,
                foregroundColor: AppColors.white,
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: AppColors.white),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.deepSeaBlue,
                  foregroundColor: AppColors.white,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.riverMist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.deepSeaBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: AppColors.white,
                selectedItemColor: AppColors.deepSeaBlue,
                unselectedItemColor: AppColors.textTertiary,
                elevation: 8,
                type: BottomNavigationBarType.fixed,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                elevation: 4,
                backgroundColor: AppColors.goldLeaf,
                foregroundColor: AppColors.white,
              ),
              tabBarTheme: const TabBarThemeData(
                labelColor: AppColors.deepSeaBlue,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.white,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return authProvider.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
