import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  String _currency = 'RON';

  Locale get locale => _locale;
  String get currency => _currency;

  LocaleProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale') ?? 'en';
    final currencyCode = prefs.getString('currency') ?? 'RON';
    _locale = Locale(localeCode);
    _currency = currencyCode;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    if (_currency == currency) return;
    
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  Future<void> initializeFromUser(String? language, String? currency) async {
    final prefs = await SharedPreferences.getInstance();
    bool changed = false;

    if (language != null && language.isNotEmpty) {
      final localeCode = language.toLowerCase();
      if (localeCode != _locale.languageCode) {
        _locale = Locale(localeCode);
        await prefs.setString('locale', localeCode);
        changed = true;
      }
    }

    if (currency != null && currency.isNotEmpty) {
      if (currency != _currency) {
        _currency = currency;
        await prefs.setString('currency', currency);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  void toggleLocale() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('ro'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}
