import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'CoachMaster'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @trainings.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get trainings;

  /// No description provided for @matches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @teamStatistics.
  ///
  /// In en, this message translates to:
  /// **'Team Statistics'**
  String get teamStatistics;

  /// No description provided for @topLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Top 5 Leaderboards'**
  String get topLeaderboards;

  /// No description provided for @topScorers.
  ///
  /// In en, this message translates to:
  /// **'Top Scorers'**
  String get topScorers;

  /// No description provided for @topAssistors.
  ///
  /// In en, this message translates to:
  /// **'Top Assistors'**
  String get topAssistors;

  /// No description provided for @highestRated.
  ///
  /// In en, this message translates to:
  /// **'Highest Rated'**
  String get highestRated;

  /// No description provided for @mostPresent.
  ///
  /// In en, this message translates to:
  /// **'Most Present'**
  String get mostPresent;

  /// No description provided for @temporarilyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disabled'**
  String get temporarilyDisabled;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'goals'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'assists'**
  String get assists;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'avg rating'**
  String get avgRating;

  /// No description provided for @goalsFor.
  ///
  /// In en, this message translates to:
  /// **'Goals For'**
  String get goalsFor;

  /// No description provided for @goalsAgainst.
  ///
  /// In en, this message translates to:
  /// **'Goals Against'**
  String get goalsAgainst;

  /// No description provided for @totalAssists.
  ///
  /// In en, this message translates to:
  /// **'Total Assists'**
  String get totalAssists;

  /// No description provided for @yellowCards.
  ///
  /// In en, this message translates to:
  /// **'Yellow Cards'**
  String get yellowCards;

  /// No description provided for @playerCount.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playerCount;

  /// No description provided for @matchCount.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchCount;

  /// No description provided for @addNewPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add New Player'**
  String get addNewPlayer;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @preferredFoot.
  ///
  /// In en, this message translates to:
  /// **'Preferred Foot'**
  String get preferredFoot;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @selectPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select Photo'**
  String get selectPhoto;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @trainingSession.
  ///
  /// In en, this message translates to:
  /// **'Training Session'**
  String get trainingSession;

  /// No description provided for @trainingObjectives.
  ///
  /// In en, this message translates to:
  /// **'Training Objectives'**
  String get trainingObjectives;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @noPlayersInTeam.
  ///
  /// In en, this message translates to:
  /// **'No players in this team'**
  String get noPlayersInTeam;

  /// No description provided for @editTraining.
  ///
  /// In en, this message translates to:
  /// **'Edit Training'**
  String get editTraining;

  /// No description provided for @deleteTraining.
  ///
  /// In en, this message translates to:
  /// **'Delete Training'**
  String get deleteTraining;

  /// No description provided for @deleteTrainingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this training?'**
  String get deleteTrainingConfirm;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @objectives.
  ///
  /// In en, this message translates to:
  /// **'Objectives (comma-separated)'**
  String get objectives;

  /// No description provided for @trainingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Training Not Found'**
  String get trainingNotFound;

  /// No description provided for @trainingNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Training with given ID not found.'**
  String get trainingNotFoundMessage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @goalkeeper.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeper'**
  String get goalkeeper;

  /// No description provided for @defender.
  ///
  /// In en, this message translates to:
  /// **'Defender'**
  String get defender;

  /// No description provided for @midfielder.
  ///
  /// In en, this message translates to:
  /// **'Midfielder'**
  String get midfielder;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @centerBack.
  ///
  /// In en, this message translates to:
  /// **'Center Back'**
  String get centerBack;

  /// No description provided for @leftBack.
  ///
  /// In en, this message translates to:
  /// **'Left Back'**
  String get leftBack;

  /// No description provided for @rightBack.
  ///
  /// In en, this message translates to:
  /// **'Right Back'**
  String get rightBack;

  /// No description provided for @defensiveMidfielder.
  ///
  /// In en, this message translates to:
  /// **'Defensive Midfielder'**
  String get defensiveMidfielder;

  /// No description provided for @centralMidfielder.
  ///
  /// In en, this message translates to:
  /// **'Central Midfielder'**
  String get centralMidfielder;

  /// No description provided for @attackingMidfielder.
  ///
  /// In en, this message translates to:
  /// **'Attacking Midfielder'**
  String get attackingMidfielder;

  /// No description provided for @leftWinger.
  ///
  /// In en, this message translates to:
  /// **'Left Winger'**
  String get leftWinger;

  /// No description provided for @rightWinger.
  ///
  /// In en, this message translates to:
  /// **'Right Winger'**
  String get rightWinger;

  /// No description provided for @striker.
  ///
  /// In en, this message translates to:
  /// **'Striker'**
  String get striker;

  /// No description provided for @leftFoot.
  ///
  /// In en, this message translates to:
  /// **'Left Foot'**
  String get leftFoot;

  /// No description provided for @rightFoot.
  ///
  /// In en, this message translates to:
  /// **'Right Foot'**
  String get rightFoot;

  /// No description provided for @bothFeet.
  ///
  /// In en, this message translates to:
  /// **'Both Feet'**
  String get bothFeet;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to {appName}!'**
  String welcomeTo(String appName);

  /// No description provided for @createFirstSeasonAndTeam.
  ///
  /// In en, this message translates to:
  /// **'Create your first season and team to get started'**
  String get createFirstSeasonAndTeam;

  /// No description provided for @noTeamsInSeason.
  ///
  /// In en, this message translates to:
  /// **'No teams in this season'**
  String get noTeamsInSeason;

  /// No description provided for @createFirstTeam.
  ///
  /// In en, this message translates to:
  /// **'Create your first team to start managing players'**
  String get createFirstTeam;

  /// No description provided for @addFirstPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add your first player to get started'**
  String get addFirstPlayer;

  /// No description provided for @addMatch.
  ///
  /// In en, this message translates to:
  /// **'Add Match'**
  String get addMatch;

  /// No description provided for @addTraining.
  ///
  /// In en, this message translates to:
  /// **'Add Training'**
  String get addTraining;

  /// No description provided for @addPlayer.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get addPlayer;

  /// No description provided for @season.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// No description provided for @trainingSessions.
  ///
  /// In en, this message translates to:
  /// **'Training Sessions'**
  String get trainingSessions;

  /// No description provided for @selectSeason.
  ///
  /// In en, this message translates to:
  /// **'Select Season'**
  String get selectSeason;

  /// No description provided for @selectTeam.
  ///
  /// In en, this message translates to:
  /// **'Select Team'**
  String get selectTeam;

  /// No description provided for @manageSeasons.
  ///
  /// In en, this message translates to:
  /// **'Manage Seasons'**
  String get manageSeasons;

  /// No description provided for @manageTeams.
  ///
  /// In en, this message translates to:
  /// **'Manage Teams'**
  String get manageTeams;

  /// No description provided for @languageAndPreferences.
  ///
  /// In en, this message translates to:
  /// **'Language & Preferences'**
  String get languageAndPreferences;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @useDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get useDarkTheme;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @receiveReminders.
  ///
  /// In en, this message translates to:
  /// **'Receive match and training reminders'**
  String get receiveReminders;

  /// No description provided for @teamManagement.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get teamManagement;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// No description provided for @sortByPosition.
  ///
  /// In en, this message translates to:
  /// **'Sort by Position'**
  String get sortByPosition;

  /// No description provided for @noPlayersInTeamYet.
  ///
  /// In en, this message translates to:
  /// **'No players in this team yet'**
  String get noPlayersInTeamYet;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
