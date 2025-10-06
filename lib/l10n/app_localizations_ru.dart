// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get welcomeMessage => 'Приветствую!';

  @override
  String get createAccount => 'Создать аккаунт!';

  @override
  String currentPlan(Object planName) {
    return 'Текущий план: $planName';
  }

  @override
  String get fastingHistory => 'История голодания';

  @override
  String get longestFast => 'Рекорд голодания';

  @override
  String get averageFast => 'Голодание в среднем';
}
