import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import 'language_state.dart';

final languageNotifierProvider = NotifierProvider<LanguageNotifier, LanguageState>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<LanguageState> {
  @override
  LanguageState build() {
    final sharedPrefs = ref.watch(sharedPreferencesProvider);
    final langCode = sharedPrefs.getString('language_code') ?? 'id';
    return LanguageState(locale: Locale(langCode));
  }

  void setLanguage(String languageCode) async {
    final sharedPrefs = ref.read(sharedPreferencesProvider);
    await sharedPrefs.setString('language_code', languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }
}
