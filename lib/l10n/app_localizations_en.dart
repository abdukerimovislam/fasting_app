// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeMessage => 'Welcome Back!';

  @override
  String get createAccount => 'Create Account';

  @override
  String currentPlan(Object planName) {
    return 'Current Plan: $planName';
  }

  @override
  String get fastingHistory => 'Fasting History';

  @override
  String get longestFast => 'Longest Fast';

  @override
  String get averageFast => 'Average Fast';
}
