// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcomeMessage => '¡Bienvenido de nuevo!';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String currentPlan(Object planName) {
    return 'Plan Actual: $planName';
  }

  @override
  String get fastingHistory => 'Historial de Ayuno';

  @override
  String get longestFast => 'Ayuno Más Largo';

  @override
  String get averageFast => 'Ayuno Promedio';
}
