// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'टीम वर्कस्पेस';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get apply => 'लागू करें';

  @override
  String get all => 'सभी';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get language => 'भाषा';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get welcomeBack => 'वापसी पर स्वागत है';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get login => 'लॉगिन';

  @override
  String get email => 'ईमेल';

  @override
  String get emailHint => 'अपना ईमेल दर्ज करें';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get createAnAccount => 'खाता बनाएँ';

  @override
  String get alreadyHaveAccountLogin => 'पहले से खाता है? लॉगिन करें';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get emailInvalid => 'मान्य ईमेल दर्ज करें';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक है';

  @override
  String passwordMinLength(int min) {
    return 'पासवर्ड कम से कम $min अक्षरों का होना चाहिए';
  }

  @override
  String get confirmPasswordRequired => 'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String fieldRequired(String field) {
    return '$field आवश्यक है';
  }

  @override
  String get tasksTitle => 'कार्य';

  @override
  String get filters => 'फ़िल्टर';

  @override
  String get createTask => 'कार्य बनाएँ';

  @override
  String get editTask => 'कार्य संपादित करें';

  @override
  String get updateTask => 'कार्य अपडेट करें';

  @override
  String get taskDetails => 'कार्य विवरण';

  @override
  String get searchTasksHint => 'शीर्षक से कार्य खोजें';

  @override
  String get searchTasksSemantics => 'कार्य खोजें';

  @override
  String get clearSearch => 'खोज साफ़ करें';

  @override
  String get noTasksYet => 'अभी कोई कार्य नहीं है।';

  @override
  String get noTasksFound => 'कोई कार्य नहीं मिला';

  @override
  String get tryChangingSearchOrFilters => 'अपनी खोज या फ़िल्टर बदलकर देखें।';

  @override
  String get status => 'स्थिति';

  @override
  String get priority => 'प्राथमिकता';

  @override
  String get clearAll => 'सभी साफ़ करें';

  @override
  String get removeStatusFilter => 'स्थिति फ़िल्टर हटाएँ';

  @override
  String get removePriorityFilter => 'प्राथमिकता फ़िल्टर हटाएँ';

  @override
  String get dueDate => 'नियत तिथि';

  @override
  String duePrefix(String date) {
    return 'नियत $date';
  }

  @override
  String get waitingForSync => 'सिंक की प्रतीक्षा';

  @override
  String openTaskSemantics(String title) {
    return 'कार्य खोलें $title';
  }

  @override
  String get title => 'शीर्षक';

  @override
  String get description => 'विवरण';

  @override
  String get assignedUser => 'नियुक्त उपयोगकर्ता';

  @override
  String get lastUpdated => 'अंतिम अपडेट';

  @override
  String get markCompleted => 'पूर्ण चिह्नित करें';

  @override
  String get reopenTask => 'कार्य पुनः खोलें';

  @override
  String get editTaskTooltip => 'कार्य संपादित करें';

  @override
  String get titleRequired => 'शीर्षक आवश्यक है';

  @override
  String titleTooShort(int min) {
    return 'शीर्षक कम से कम $min अक्षरों का होना चाहिए';
  }

  @override
  String titleTooLong(int max) {
    return 'शीर्षक अधिकतम $max अक्षरों का होना चाहिए';
  }

  @override
  String get descriptionRequired => 'विवरण आवश्यक है';

  @override
  String descriptionTooShort(int min) {
    return 'विवरण कम से कम $min अक्षरों का होना चाहिए';
  }

  @override
  String get priorityRequired => 'प्राथमिकता आवश्यक है';

  @override
  String get dueDateRequired => 'नियत तिथि आवश्यक है';

  @override
  String get dueDateInvalid => 'मान्य नियत तिथि दर्ज करें';

  @override
  String get dueDateInPast => 'नियत तिथि अतीत में नहीं हो सकती';

  @override
  String get statusPending => 'लंबित';

  @override
  String get statusInProgress => 'प्रगति में';

  @override
  String get statusCompleted => 'पूर्ण';

  @override
  String get priorityLow => 'कम';

  @override
  String get priorityMedium => 'मध्यम';

  @override
  String get priorityHigh => 'उच्च';

  @override
  String get taskCreatedSuccess => 'कार्य सफलतापूर्वक बनाया गया';

  @override
  String get taskUpdatedSuccess => 'कार्य सफलतापूर्वक अपडेट किया गया';

  @override
  String get taskMarkedCompleted => 'कार्य पूर्ण चिह्नित किया गया';

  @override
  String get taskReopened => 'कार्य पुनः खोला गया';

  @override
  String get savedOfflineWaitingSync => 'ऑफ़लाइन सहेजा गया — सिंक की प्रतीक्षा';

  @override
  String get taskNotFound => 'कार्य नहीं मिला।';

  @override
  String get youAreOffline => 'आप ऑफ़लाइन हैं';

  @override
  String offlinePendingCount(int count) {
    return 'ऑफ़लाइन · $count सिंक की प्रतीक्षा में';
  }

  @override
  String get syncingChanges => 'परिवर्तन सिंक हो रहे हैं…';

  @override
  String pendingCountWaiting(int count) {
    return '$count सिंक की प्रतीक्षा में';
  }

  @override
  String get backOnline => 'फिर से ऑनलाइन';

  @override
  String syncedCount(int count) {
    return '$count परिवर्तन सिंक हुए';
  }

  @override
  String syncedPartialFailure(int synced, int failed) {
    return '$synced सिंक हुए, $failed विफल।';
  }

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get selectDate => 'तिथि चुनें';

  @override
  String get noDescription => 'कोई विवरण नहीं दिया गया।';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get theme => 'थीम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get openProfile => 'प्रोफ़ाइल खोलें';
}
