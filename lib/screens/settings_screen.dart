// lib/screens/settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fasting_tracker/providers/theme_provider.dart';
import 'package:fasting_tracker/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Helper function to get the full language name from its code
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'ru': // Add the new case for Russian
        return 'Русский';
      default:
        return languageCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('Language'), // This could also be localized!
          trailing: DropdownButton<Locale>(
            value: themeProvider.appLocale ?? Localizations.localeOf(context),
            items: AppLocalizations.supportedLocales.map((Locale locale) {
              // Use the helper function here
              final languageName = getLanguageName(locale.languageCode);
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(languageName),
              );
            }).toList(),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                themeProvider.setLocale(newLocale);
              }
            },
          ),
        ),
        const Divider(),

        // --- Theme and Logout sections remain the same ---
        const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async { /* ... */ },
        ),
      ],
    );
  }
}