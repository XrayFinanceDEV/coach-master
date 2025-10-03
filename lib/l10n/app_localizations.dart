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
  /// **'players'**
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

  /// No description provided for @playersTitle.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get playersTitle;

  /// No description provided for @trainingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainings'**
  String get trainingsTitle;

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
  /// **'Goals'**
  String get goals;

  /// No description provided for @assists.
  ///
  /// In en, this message translates to:
  /// **'Assists'**
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

  /// No description provided for @fullBack.
  ///
  /// In en, this message translates to:
  /// **'Full-back'**
  String get fullBack;

  /// No description provided for @wingBack.
  ///
  /// In en, this message translates to:
  /// **'Wing-back'**
  String get wingBack;

  /// No description provided for @winger.
  ///
  /// In en, this message translates to:
  /// **'Winger'**
  String get winger;

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

  /// No description provided for @editPlayer.
  ///
  /// In en, this message translates to:
  /// **'Edit Player'**
  String get editPlayer;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change Photo'**
  String get changePhoto;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get deleteNoteConfirm;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @updateNote.
  ///
  /// In en, this message translates to:
  /// **'Update Note'**
  String get updateNote;

  /// No description provided for @matchNotFound.
  ///
  /// In en, this message translates to:
  /// **'Match Not Found'**
  String get matchNotFound;

  /// No description provided for @matchNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Match with given ID not found.'**
  String get matchNotFoundMessage;

  /// No description provided for @matchVs.
  ///
  /// In en, this message translates to:
  /// **'Match vs'**
  String get matchVs;

  /// No description provided for @matchStatus.
  ///
  /// In en, this message translates to:
  /// **'Match Status'**
  String get matchStatus;

  /// No description provided for @convocation.
  ///
  /// In en, this message translates to:
  /// **'Convocation'**
  String get convocation;

  /// No description provided for @matchConvocations.
  ///
  /// In en, this message translates to:
  /// **'Match Convocations'**
  String get matchConvocations;

  /// No description provided for @totalPlayers.
  ///
  /// In en, this message translates to:
  /// **'Total Players'**
  String get totalPlayers;

  /// No description provided for @matchStatistics.
  ///
  /// In en, this message translates to:
  /// **'Match Statistics'**
  String get matchStatistics;

  /// No description provided for @teamPerformance.
  ///
  /// In en, this message translates to:
  /// **'Team Performance'**
  String get teamPerformance;

  /// No description provided for @editConvocatedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Edit Convocated Players'**
  String get editConvocatedPlayers;

  /// No description provided for @convocatedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Convocated Players'**
  String get convocatedPlayers;

  /// No description provided for @deleteMatch.
  ///
  /// In en, this message translates to:
  /// **'Delete Match'**
  String get deleteMatch;

  /// No description provided for @deleteMatchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the match vs {opponent}?'**
  String deleteMatchConfirm(String opponent);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @saveConvocations.
  ///
  /// In en, this message translates to:
  /// **'Save Convocations'**
  String get saveConvocations;

  /// No description provided for @convocationsSaved.
  ///
  /// In en, this message translates to:
  /// **'Convocations saved successfully!'**
  String get convocationsSaved;

  /// No description provided for @errorSavingConvocations.
  ///
  /// In en, this message translates to:
  /// **'Error saving convocations'**
  String get errorSavingConvocations;

  /// No description provided for @trackPlayingTime.
  ///
  /// In en, this message translates to:
  /// **'Yes, track playing time'**
  String get trackPlayingTime;

  /// No description provided for @skipPlayingTime.
  ///
  /// In en, this message translates to:
  /// **'No, skip playing time'**
  String get skipPlayingTime;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @matchStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Match status updated successfully!'**
  String get matchStatusUpdated;

  /// No description provided for @startMatchStatusForm.
  ///
  /// In en, this message translates to:
  /// **'Start Match Status Form'**
  String get startMatchStatusForm;

  /// No description provided for @updateMatchStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Match Status'**
  String get updateMatchStatus;

  /// No description provided for @matchResult.
  ///
  /// In en, this message translates to:
  /// **'Match Result'**
  String get matchResult;

  /// No description provided for @enterFinalScore.
  ///
  /// In en, this message translates to:
  /// **'Enter the final score'**
  String get enterFinalScore;

  /// No description provided for @goalsDetail.
  ///
  /// In en, this message translates to:
  /// **'Goals Detail'**
  String get goalsDetail;

  /// No description provided for @whoScoredGoals.
  ///
  /// In en, this message translates to:
  /// **'Who scored the goals?'**
  String get whoScoredGoals;

  /// No description provided for @assistsCount.
  ///
  /// In en, this message translates to:
  /// **'Assists Count'**
  String get assistsCount;

  /// No description provided for @whoProvidedAssists.
  ///
  /// In en, this message translates to:
  /// **'Who provided the assists?'**
  String get whoProvidedAssists;

  /// No description provided for @cardsAndPenalties.
  ///
  /// In en, this message translates to:
  /// **'Cards & Penalties'**
  String get cardsAndPenalties;

  /// No description provided for @trackYellowRedCards.
  ///
  /// In en, this message translates to:
  /// **'Track yellow and red cards'**
  String get trackYellowRedCards;

  /// No description provided for @playingTime.
  ///
  /// In en, this message translates to:
  /// **'Playing Time'**
  String get playingTime;

  /// No description provided for @choosePlayingTimeTracking.
  ///
  /// In en, this message translates to:
  /// **'Choose playing time tracking'**
  String get choosePlayingTimeTracking;

  /// No description provided for @setMinutesEachPlayer.
  ///
  /// In en, this message translates to:
  /// **'Set minutes for each player'**
  String get setMinutesEachPlayer;

  /// No description provided for @playerRatings.
  ///
  /// In en, this message translates to:
  /// **'Player Ratings'**
  String get playerRatings;

  /// No description provided for @ratePlayerPerformance.
  ///
  /// In en, this message translates to:
  /// **'Rate each player\'s performance (1-10)'**
  String get ratePlayerPerformance;

  /// No description provided for @yesTrackPlayingTime.
  ///
  /// In en, this message translates to:
  /// **'Yes, track playing time'**
  String get yesTrackPlayingTime;

  /// No description provided for @noSkipPlayingTime.
  ///
  /// In en, this message translates to:
  /// **'No, skip playing time'**
  String get noSkipPlayingTime;

  /// No description provided for @trackIndividualPlayingTime.
  ///
  /// In en, this message translates to:
  /// **'Do you want to track individual playing time for each player?'**
  String get trackIndividualPlayingTime;

  /// No description provided for @setMinutesPlayedEachPlayer.
  ///
  /// In en, this message translates to:
  /// **'Set minutes played for each player'**
  String get setMinutesPlayedEachPlayer;

  /// No description provided for @totalGoalsMustEqual.
  ///
  /// In en, this message translates to:
  /// **'Total goals ({totalGoals}) must equal match result ({matchGoals})'**
  String totalGoalsMustEqual(Object matchGoals, Object totalGoals);

  /// No description provided for @totalAssistsCannotExceed.
  ///
  /// In en, this message translates to:
  /// **'Total assists ({totalAssists}) cannot be more than goals ({totalGoals})'**
  String totalAssistsCannotExceed(Object totalAssists, Object totalGoals);

  /// No description provided for @errorUpdatingMatch.
  ///
  /// In en, this message translates to:
  /// **'Error updating match status: {error}'**
  String errorUpdatingMatch(String error);

  /// No description provided for @savePerformance.
  ///
  /// In en, this message translates to:
  /// **'Save Performance'**
  String get savePerformance;

  /// No description provided for @playerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Player Not Found'**
  String get playerNotFound;

  /// No description provided for @playerNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Player with given ID not found.'**
  String get playerNotFoundMessage;

  /// No description provided for @deletePlayer.
  ///
  /// In en, this message translates to:
  /// **'Delete Player'**
  String get deletePlayer;

  /// No description provided for @deletePlayerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {firstName} {lastName}?'**
  String deletePlayerConfirm(String firstName, String lastName);

  /// No description provided for @invalidImageFormat.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid image format (JPG, PNG, WEBP)'**
  String get invalidImageFormat;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large ({size}MB). Please select an image smaller than 2MB.'**
  String imageTooLarge(String size);

  /// No description provided for @photoSelectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Photo selected successfully!'**
  String get photoSelectedSuccessfully;

  /// No description provided for @failedToSavePhoto.
  ///
  /// In en, this message translates to:
  /// **'Failed to save photo. Please try again.'**
  String get failedToSavePhoto;

  /// No description provided for @errorSelectingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error selecting photo: {error}'**
  String errorSelectingPhoto(String error);

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'current'**
  String get current;

  /// No description provided for @addTrainingSession.
  ///
  /// In en, this message translates to:
  /// **'Add Training Session'**
  String get addTrainingSession;

  /// No description provided for @createFirstTraining.
  ///
  /// In en, this message translates to:
  /// **'Create First Training'**
  String get createFirstTraining;

  /// No description provided for @saveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Save Attendance'**
  String get saveAttendance;

  /// No description provided for @deleteTrainingSession.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the training session on {date}?'**
  String deleteTrainingSession(String date);

  /// No description provided for @attendanceSaved.
  ///
  /// In en, this message translates to:
  /// **'Attendance saved successfully!'**
  String get attendanceSaved;

  /// No description provided for @vs.
  ///
  /// In en, this message translates to:
  /// **'vs'**
  String get vs;

  /// No description provided for @yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get yellow;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @redCards.
  ///
  /// In en, this message translates to:
  /// **'Red Cards'**
  String get redCards;

  /// No description provided for @wins.
  ///
  /// In en, this message translates to:
  /// **'Wins'**
  String get wins;

  /// No description provided for @draws.
  ///
  /// In en, this message translates to:
  /// **'Draws'**
  String get draws;

  /// No description provided for @losses.
  ///
  /// In en, this message translates to:
  /// **'Losses'**
  String get losses;

  /// No description provided for @goalDifference.
  ///
  /// In en, this message translates to:
  /// **'Goal Difference'**
  String get goalDifference;

  /// No description provided for @winRate.
  ///
  /// In en, this message translates to:
  /// **'Win Rate'**
  String get winRate;

  /// No description provided for @attack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attack;

  /// No description provided for @midfield.
  ///
  /// In en, this message translates to:
  /// **'Midfield'**
  String get midfield;

  /// No description provided for @defense.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get defense;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @noPlayersInCategory.
  ///
  /// In en, this message translates to:
  /// **'No players in this category'**
  String get noPlayersInCategory;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get stepOf;

  /// No description provided for @result.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get result;

  /// No description provided for @assistsDetail.
  ///
  /// In en, this message translates to:
  /// **'Assists Detail'**
  String get assistsDetail;

  /// No description provided for @cardsDetail.
  ///
  /// In en, this message translates to:
  /// **'Cards Detail'**
  String get cardsDetail;

  /// No description provided for @playingTimeChoice.
  ///
  /// In en, this message translates to:
  /// **'Playing Time Choice'**
  String get playingTimeChoice;

  /// No description provided for @playingTimeDetail.
  ///
  /// In en, this message translates to:
  /// **'Playing Time Detail'**
  String get playingTimeDetail;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @statsSaved.
  ///
  /// In en, this message translates to:
  /// **'Stats saved'**
  String get statsSaved;

  /// No description provided for @noMatchesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No Matches Scheduled'**
  String get noMatchesScheduled;

  /// No description provided for @createFirstMatchToStart.
  ///
  /// In en, this message translates to:
  /// **'Create your first match to start managing convocations and statistics'**
  String get createFirstMatchToStart;

  /// No description provided for @createFirstMatch.
  ///
  /// In en, this message translates to:
  /// **'Create First Match'**
  String get createFirstMatch;

  /// No description provided for @convocated.
  ///
  /// In en, this message translates to:
  /// **'convocated'**
  String get convocated;

  /// No description provided for @opponentTeam.
  ///
  /// In en, this message translates to:
  /// **'Opponent Team'**
  String get opponentTeam;

  /// No description provided for @pleaseEnterOpponentTeam.
  ///
  /// In en, this message translates to:
  /// **'Please enter the opponent team name'**
  String get pleaseEnterOpponentTeam;

  /// No description provided for @matchDate.
  ///
  /// In en, this message translates to:
  /// **'Match Date'**
  String get matchDate;

  /// No description provided for @pleaseEnterMatchLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter the match location'**
  String get pleaseEnterMatchLocation;

  /// No description provided for @matchType.
  ///
  /// In en, this message translates to:
  /// **'Match Type'**
  String get matchType;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @editMatch.
  ///
  /// In en, this message translates to:
  /// **'Edit Match'**
  String get editMatch;

  /// No description provided for @updateMatch.
  ///
  /// In en, this message translates to:
  /// **'Update Match'**
  String get updateMatch;

  /// No description provided for @createMatch.
  ///
  /// In en, this message translates to:
  /// **'Create Match'**
  String get createMatch;

  /// No description provided for @matchUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Match updated successfully!'**
  String get matchUpdatedSuccessfully;

  /// No description provided for @matchCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Match created successfully!'**
  String get matchCreatedSuccessfully;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @toBeDetermined.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get toBeDetermined;

  /// No description provided for @editConvocationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Edit convocations in case of errors or players not coming to the scheduled match.'**
  String get editConvocationsHelp;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard...'**
  String get loadingDashboard;

  /// No description provided for @settingUpTeams.
  ///
  /// In en, this message translates to:
  /// **'Setting up your teams and players'**
  String get settingUpTeams;

  /// No description provided for @loadingTeamData.
  ///
  /// In en, this message translates to:
  /// **'Loading team data...'**
  String get loadingTeamData;

  /// No description provided for @pleaseSelectTeamFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a team first!'**
  String get pleaseSelectTeamFirst;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get noPlayersFound;

  /// No description provided for @addPlayersToTeam.
  ///
  /// In en, this message translates to:
  /// **'Add players to your team to get started'**
  String get addPlayersToTeam;

  /// No description provided for @allPlayers.
  ///
  /// In en, this message translates to:
  /// **'All Players'**
  String get allPlayers;

  /// No description provided for @tutti.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tutti;

  /// No description provided for @attacco.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attacco;

  /// No description provided for @centrocampo.
  ///
  /// In en, this message translates to:
  /// **'Midfield'**
  String get centrocampo;

  /// No description provided for @difesa.
  ///
  /// In en, this message translates to:
  /// **'Defense'**
  String get difesa;

  /// No description provided for @altro.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get altro;

  /// No description provided for @player.
  ///
  /// In en, this message translates to:
  /// **'player'**
  String get player;

  /// No description provided for @giocatore.
  ///
  /// In en, this message translates to:
  /// **'player'**
  String get giocatore;

  /// No description provided for @giocatori.
  ///
  /// In en, this message translates to:
  /// **'players'**
  String get giocatori;

  /// No description provided for @syncData.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get syncData;

  /// No description provided for @dataSyncedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data synced successfully!'**
  String get dataSyncedSuccessfully;

  /// No description provided for @errorSyncingData.
  ///
  /// In en, this message translates to:
  /// **'Error syncing data'**
  String get errorSyncingData;

  /// No description provided for @errorLoadingPlayers.
  ///
  /// In en, this message translates to:
  /// **'Error loading players: {error}'**
  String errorLoadingPlayers(String error);

  /// No description provided for @errorLoadingPlayer.
  ///
  /// In en, this message translates to:
  /// **'Error loading player: {error}'**
  String errorLoadingPlayer(String error);

  /// No description provided for @errorLoadingNotes.
  ///
  /// In en, this message translates to:
  /// **'Error loading notes: {error}'**
  String errorLoadingNotes(String error);

  /// No description provided for @errorLoadingTeam.
  ///
  /// In en, this message translates to:
  /// **'Error loading team: {error}'**
  String errorLoadingTeam(String error);

  /// No description provided for @errorLoadingMatches.
  ///
  /// In en, this message translates to:
  /// **'Error loading matches: {error}'**
  String errorLoadingMatches(String error);

  /// No description provided for @errorLoadingAttendances.
  ///
  /// In en, this message translates to:
  /// **'Error loading attendances: {error}'**
  String errorLoadingAttendances(String error);

  /// No description provided for @errorLoadingConvocatedPlayers.
  ///
  /// In en, this message translates to:
  /// **'Error loading convocated players'**
  String get errorLoadingConvocatedPlayers;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @teamNotFound.
  ///
  /// In en, this message translates to:
  /// **'Team not found'**
  String get teamNotFound;

  /// No description provided for @noTrainingsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No trainings scheduled'**
  String get noTrainingsScheduled;

  /// No description provided for @createFirstTrainingToStart.
  ///
  /// In en, this message translates to:
  /// **'Create your first training to start tracking attendance'**
  String get createFirstTrainingToStart;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noDataYetShort.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYetShort;

  /// No description provided for @statsWillAppearAfterMatches.
  ///
  /// In en, this message translates to:
  /// **'Stats will appear after matches'**
  String get statsWillAppearAfterMatches;

  /// No description provided for @mostAbsences.
  ///
  /// In en, this message translates to:
  /// **'Most Absences'**
  String get mostAbsences;

  /// No description provided for @errorLoadingLeaderboards.
  ///
  /// In en, this message translates to:
  /// **'Error loading leaderboards. Please try again.'**
  String get errorLoadingLeaderboards;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @completeMatch.
  ///
  /// In en, this message translates to:
  /// **'Complete Match'**
  String get completeMatch;
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
