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
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1), // Modern indigo
                brightness: Brightness.light,
                primary: const Color(0xFF6366F1),
                secondary: const Color(0xFF8B5CF6),
                tertiary: const Color(0xFFEC4899),
                surface: const Color(0xFFFFFFFF),
                surfaceContainerHighest: const Color(0xFFF3F4F6),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: const Color(0xFF1F2937),
                onSurfaceVariant: const Color(0xFF6B7280),
              ),
              scaffoldBackgroundColor: const Color(0xFFF9FAFB),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: false,
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Color(0xFF6366F1),
                unselectedItemColor: Color(0xFF9CA3AF),
                elevation: 8,
                type: BottomNavigationBarType.fixed,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                elevation: 4,
                backgroundColor: Color(0xFF6366F1),
                foregroundColor: Colors.white,
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
