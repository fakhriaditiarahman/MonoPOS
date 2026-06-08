import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../generated/app_localizations.dart';

class AppLocale {
  AppLocale._();

  static const String defaultPhoneCode = '+62';
  static const String defaultCurrencyCode = 'Rp';

  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('en', 'EN'),
  ];

  static const List<LocalizationsDelegate> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
