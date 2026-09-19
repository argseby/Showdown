import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en'),
  ];

  /// Application name shown in the browser tab and headers
  ///
  /// In en, this message translates to:
  /// **'Showdown'**
  String get appTitle;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'Texas Hold\'em for your private group.'**
  String get landingTagline;

  /// No description provided for @landingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Table link or code'**
  String get landingCodeLabel;

  /// No description provided for @landingCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/t/k7m2p9xq4w or k7m2p9xq4w'**
  String get landingCodePlaceholder;

  /// No description provided for @landingJoin.
  ///
  /// In en, this message translates to:
  /// **'Open table'**
  String get landingJoin;

  /// No description provided for @landingInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a table link or code.'**
  String get landingInvalidCode;

  /// Footer line naming the build the API reports
  ///
  /// In en, this message translates to:
  /// **'Server {version}'**
  String landingServerVersion(String version);

  /// No description provided for @landingSource.
  ///
  /// In en, this message translates to:
  /// **'Source on GitHub'**
  String get landingSource;

  /// Footer credit on the start screen
  ///
  /// In en, this message translates to:
  /// **'Created by {author}'**
  String landingCreatedBy(String author);

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundBody.
  ///
  /// In en, this message translates to:
  /// **'There is nothing at this address.'**
  String get notFoundBody;

  /// No description provided for @notFoundHome.
  ///
  /// In en, this message translates to:
  /// **'Back to start'**
  String get notFoundHome;

  /// No description provided for @themeToggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle light/dark theme'**
  String get themeToggle;

  /// No description provided for @languageToggle.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get languageToggle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageGerman;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join table'**
  String get joinTitle;

  /// No description provided for @joinSeats.
  ///
  /// In en, this message translates to:
  /// **'{seated} of {max} seats taken'**
  String joinSeats(int seated, int max);

  /// No description provided for @joinStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players'**
  String get joinStateWaiting;

  /// No description provided for @joinStateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get joinStateRunning;

  /// No description provided for @joinStatePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get joinStatePaused;

  /// No description provided for @joinStateEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get joinStateEnded;

  /// No description provided for @joinBlinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds {small}/{big}'**
  String joinBlinds(String small, String big);

  /// No description provided for @joinNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get joinNameLabel;

  /// No description provided for @joinNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'1-20 characters'**
  String get joinNamePlaceholder;

  /// No description provided for @joinPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Table password'**
  String get joinPasswordLabel;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @spectateButton.
  ///
  /// In en, this message translates to:
  /// **'Spectate'**
  String get spectateButton;

  /// No description provided for @joinNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1-20 letters, digits, spaces, _ - .'**
  String get joinNameInvalid;

  /// No description provided for @joinPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the table password.'**
  String get joinPasswordRequired;

  /// No description provided for @joinLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this table.'**
  String get joinLoadFailed;

  /// No description provided for @joinTableEnded.
  ///
  /// In en, this message translates to:
  /// **'This table has ended.'**
  String get joinTableEnded;

  /// No description provided for @joinClosed.
  ///
  /// In en, this message translates to:
  /// **'Joining is closed for this table.'**
  String get joinClosed;

  /// No description provided for @joinSpectatorsOff.
  ///
  /// In en, this message translates to:
  /// **'Spectators are not allowed at this table.'**
  String get joinSpectatorsOff;

  /// No description provided for @tableNotFound.
  ///
  /// In en, this message translates to:
  /// **'Table not found'**
  String get tableNotFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get errWrongPassword;

  /// No description provided for @errNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is already taken'**
  String get errNameTaken;

  /// No description provided for @errTableFull.
  ///
  /// In en, this message translates to:
  /// **'The table is full'**
  String get errTableFull;

  /// No description provided for @errJoinsClosed.
  ///
  /// In en, this message translates to:
  /// **'Joining is closed'**
  String get errJoinsClosed;

  /// No description provided for @errTableEnded.
  ///
  /// In en, this message translates to:
  /// **'The table has ended'**
  String get errTableEnded;

  /// No description provided for @errInvalidName.
  ///
  /// In en, this message translates to:
  /// **'Invalid name'**
  String get errInvalidName;

  /// No description provided for @errSpectatorsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Spectators are not allowed'**
  String get errSpectatorsDisabled;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, please try again shortly'**
  String get errRateLimited;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {message}'**
  String errGeneric(String message);

  /// No description provided for @errNotYourTurn.
  ///
  /// In en, this message translates to:
  /// **'It is not your turn'**
  String get errNotYourTurn;

  /// No description provided for @errIllegalAction.
  ///
  /// In en, this message translates to:
  /// **'That action is not allowed right now'**
  String get errIllegalAction;

  /// No description provided for @errAmountOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Amount out of range'**
  String get errAmountOutOfRange;

  /// No description provided for @handNumber.
  ///
  /// In en, this message translates to:
  /// **'Hand #{number}'**
  String handNumber(int number);

  /// No description provided for @blindsShort.
  ///
  /// In en, this message translates to:
  /// **'Blinds {small}/{big}'**
  String blindsShort(String small, String big);

  /// No description provided for @connConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connConnected;

  /// No description provided for @connConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connConnecting;

  /// No description provided for @connReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting... (attempt {attempt})'**
  String connReconnecting(int attempt);

  /// No description provided for @connDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get connDisconnected;

  /// No description provided for @replacedTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected elsewhere'**
  String get replacedTitle;

  /// No description provided for @replacedBody.
  ///
  /// In en, this message translates to:
  /// **'This seat is now used by another connection.'**
  String get replacedBody;

  /// No description provided for @reconnectHere.
  ///
  /// In en, this message translates to:
  /// **'Reconnect here'**
  String get reconnectHere;

  /// No description provided for @kickedTitle.
  ///
  /// In en, this message translates to:
  /// **'Removed from the table'**
  String get kickedTitle;

  /// No description provided for @kickedBody.
  ///
  /// In en, this message translates to:
  /// **'The admin removed you from this table.'**
  String get kickedBody;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Your session is no longer valid. Please join again.'**
  String get sessionExpiredBody;

  /// No description provided for @tableEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Table ended'**
  String get tableEndedTitle;

  /// No description provided for @finalStandings.
  ///
  /// In en, this message translates to:
  /// **'Final standings'**
  String get finalStandings;

  /// No description provided for @backToJoin.
  ///
  /// In en, this message translates to:
  /// **'Back to the table page'**
  String get backToJoin;

  /// No description provided for @newRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'New round started'**
  String get newRoundTitle;

  /// No description provided for @newRoundBody.
  ///
  /// In en, this message translates to:
  /// **'The host opened a new round on this table. Your seat is still yours.'**
  String get newRoundBody;

  /// No description provided for @backToTable.
  ///
  /// In en, this message translates to:
  /// **'Back to the table'**
  String get backToTable;

  /// No description provided for @lastRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Last round'**
  String get lastRoundTitle;

  /// No description provided for @lastRoundHands.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hand} other{{count} hands}}'**
  String lastRoundHands(int count);

  /// No description provided for @thisRound.
  ///
  /// In en, this message translates to:
  /// **'This round'**
  String get thisRound;

  /// No description provided for @serverRestarting.
  ///
  /// In en, this message translates to:
  /// **'The server is restarting, reconnecting shortly...'**
  String get serverRestarting;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @leaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the table?'**
  String get leaveConfirmTitle;

  /// No description provided for @leaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your seat will be freed. If a hand is running you fold.'**
  String get leaveConfirmBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accountSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignInTitle;

  /// No description provided for @accountSignInBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile keeps your statistics across tables. You can always play as a guest instead.'**
  String get accountSignInBody;

  /// No description provided for @accountCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a profile'**
  String get accountCreateTitle;

  /// No description provided for @accountCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a name and a password. No email, nothing to confirm — you get one recovery code instead.'**
  String get accountCreateBody;

  /// No description provided for @accountHandle.
  ///
  /// In en, this message translates to:
  /// **'Name (a–z, 0–9, _)'**
  String get accountHandle;

  /// No description provided for @accountPassword.
  ///
  /// In en, this message translates to:
  /// **'Password (at least 8 characters)'**
  String get accountPassword;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountCreate.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get accountCreate;

  /// No description provided for @accountNeedOne.
  ///
  /// In en, this message translates to:
  /// **'No profile yet? Create one'**
  String get accountNeedOne;

  /// No description provided for @accountHaveOne.
  ///
  /// In en, this message translates to:
  /// **'Already have a profile? Sign in'**
  String get accountHaveOne;

  /// No description provided for @accountMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in both fields.'**
  String get accountMissingFields;

  /// No description provided for @accountHandleTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is taken.'**
  String get accountHandleTaken;

  /// No description provided for @accountBadCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong name or password.'**
  String get accountBadCredentials;

  /// No description provided for @accountsOff.
  ///
  /// In en, this message translates to:
  /// **'This instance has no player profiles.'**
  String get accountsOff;

  /// No description provided for @accountRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Write this down'**
  String get accountRecoveryTitle;

  /// No description provided for @accountRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'This code is the only way back into your profile if you forget your password. It is shown once and never again — no email is sent.'**
  String get accountRecoveryBody;

  /// No description provided for @accountRecoveryDone.
  ///
  /// In en, this message translates to:
  /// **'I wrote it down'**
  String get accountRecoveryDone;

  /// No description provided for @accountRecoveryCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get accountRecoveryCopy;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountHandleLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountHandleLabel;

  /// No description provided for @accountDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Shown as'**
  String get accountDisplayName;

  /// No description provided for @accountStatsSoon.
  ///
  /// In en, this message translates to:
  /// **'Your profile marks your seat. Statistics, best hands and achievements follow.'**
  String get accountStatsSoon;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountChangePassword;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountCurrentPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// No description provided for @accountSavePassword.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get accountSavePassword;

  /// No description provided for @accountPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'A new password signs your other devices out and gives you a new recovery code.'**
  String get accountPasswordHint;

  /// No description provided for @accountMenu.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get accountMenu;

  /// No description provided for @accountMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Your profile, password and sign out'**
  String get accountMenuHint;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your statistics'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet — play a hand while signed in and it lands here.'**
  String get statsEmpty;

  /// No description provided for @statsOpen.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsOpen;

  /// No description provided for @statsSince.
  ///
  /// In en, this message translates to:
  /// **'Playing since {date}'**
  String statsSince(String date);

  /// No description provided for @statsVolume.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get statsVolume;

  /// No description provided for @statsHands.
  ///
  /// In en, this message translates to:
  /// **'Hands'**
  String get statsHands;

  /// No description provided for @statsMenuHint.
  ///
  /// In en, this message translates to:
  /// **'Your hands, results and the way you play'**
  String get statsMenuHint;

  /// No description provided for @statsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsTabOverview;

  /// No description provided for @statsTabHands.
  ///
  /// In en, this message translates to:
  /// **'Hands'**
  String get statsTabHands;

  /// No description provided for @statsOverHands.
  ///
  /// In en, this message translates to:
  /// **'over {hands} hands at {tables} tables'**
  String statsOverHands(String hands, String tables);

  /// No description provided for @statsFirstHand.
  ///
  /// In en, this message translates to:
  /// **'First hand'**
  String get statsFirstHand;

  /// No description provided for @statsBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get statsBest;

  /// No description provided for @statsBiggestPotHint.
  ///
  /// In en, this message translates to:
  /// **'the whole pot, your own chips included'**
  String get statsBiggestPotHint;

  /// No description provided for @statsBestRoundHint.
  ///
  /// In en, this message translates to:
  /// **'what you were up when a table ended'**
  String get statsBestRoundHint;

  /// No description provided for @statsRate.
  ///
  /// In en, this message translates to:
  /// **'Win rate'**
  String get statsRate;

  /// No description provided for @statsPer100Chips.
  ///
  /// In en, this message translates to:
  /// **'Per 100 hands'**
  String get statsPer100Chips;

  /// No description provided for @statsBbHint.
  ///
  /// In en, this message translates to:
  /// **'A big blind is the table\'s big forced bet. Counting in big blinds is how tables that play for different amounts compare.'**
  String get statsBbHint;

  /// No description provided for @statsShowdownGroup.
  ///
  /// In en, this message translates to:
  /// **'Showdowns'**
  String get statsShowdownGroup;

  /// No description provided for @statsNoHandsYet.
  ///
  /// In en, this message translates to:
  /// **'No hand of yours has reached the end yet.'**
  String get statsNoHandsYet;

  /// No description provided for @statsTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get statsTables;

  /// No description provided for @statsRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get statsRounds;

  /// No description provided for @statsMoney.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get statsMoney;

  /// No description provided for @statsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get statsNet;

  /// No description provided for @statsNetBB.
  ///
  /// In en, this message translates to:
  /// **'In big blinds'**
  String get statsNetBB;

  /// No description provided for @statsPer100.
  ///
  /// In en, this message translates to:
  /// **'Per 100 hands in bb'**
  String get statsPer100;

  /// No description provided for @statsBiggestPot.
  ///
  /// In en, this message translates to:
  /// **'Biggest pot won'**
  String get statsBiggestPot;

  /// No description provided for @statsBiggestWin.
  ///
  /// In en, this message translates to:
  /// **'Biggest hand'**
  String get statsBiggestWin;

  /// No description provided for @statsBestRound.
  ///
  /// In en, this message translates to:
  /// **'Best round'**
  String get statsBestRound;

  /// No description provided for @statsHandsWon.
  ///
  /// In en, this message translates to:
  /// **'Hands won'**
  String get statsHandsWon;

  /// No description provided for @statsRoundsWon.
  ///
  /// In en, this message translates to:
  /// **'Rounds won'**
  String get statsRoundsWon;

  /// No description provided for @statsPodiums.
  ///
  /// In en, this message translates to:
  /// **'Top three'**
  String get statsPodiums;

  /// No description provided for @statsTournaments.
  ///
  /// In en, this message translates to:
  /// **'Tournaments'**
  String get statsTournaments;

  /// No description provided for @statsStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get statsStyle;

  /// No description provided for @statsVpip.
  ///
  /// In en, this message translates to:
  /// **'Played the hand'**
  String get statsVpip;

  /// No description provided for @statsShowdowns.
  ///
  /// In en, this message translates to:
  /// **'Showdowns won'**
  String get statsShowdowns;

  /// No description provided for @statsNoShowdown.
  ///
  /// In en, this message translates to:
  /// **'Won without showdown'**
  String get statsNoShowdown;

  /// No description provided for @statsFolded.
  ///
  /// In en, this message translates to:
  /// **'Folded'**
  String get statsFolded;

  /// No description provided for @statsAllIns.
  ///
  /// In en, this message translates to:
  /// **'All-ins'**
  String get statsAllIns;

  /// No description provided for @statsHandClasses.
  ///
  /// In en, this message translates to:
  /// **'Hands made'**
  String get statsHandClasses;

  /// No description provided for @statsShownOf.
  ///
  /// In en, this message translates to:
  /// **'{shown} shown'**
  String statsShownOf(String shown);

  /// No description provided for @statsCountedNote.
  ///
  /// In en, this message translates to:
  /// **'Counted: {counted} of {hands} hands were played with three or more profiles and no chip adjustments — only those may ever stand in a public total.'**
  String statsCountedNote(String counted, String hands);

  /// No description provided for @statsTabAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get statsTabAwards;

  /// No description provided for @statsBestHands.
  ///
  /// In en, this message translates to:
  /// **'Best hands'**
  String get statsBestHands;

  /// No description provided for @statsBiggestPots.
  ///
  /// In en, this message translates to:
  /// **'Biggest pots'**
  String get statsBiggestPots;

  /// No description provided for @statsHandAt.
  ///
  /// In en, this message translates to:
  /// **'{table} · hand {number}'**
  String statsHandAt(String table, String number);

  /// No description provided for @statsMucked.
  ///
  /// In en, this message translates to:
  /// **'mucked'**
  String get statsMucked;

  /// No description provided for @statsShownAtTable.
  ///
  /// In en, this message translates to:
  /// **'shown'**
  String get statsShownAtTable;

  /// No description provided for @statsAwardsAhead.
  ///
  /// In en, this message translates to:
  /// **'Still ahead'**
  String get statsAwardsAhead;

  /// No description provided for @statsProgressOf.
  ///
  /// In en, this message translates to:
  /// **'{progress} of {goal}'**
  String statsProgressOf(String progress, String goal);

  /// No description provided for @statsNoAwardsYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing earned yet — every milestone below is still open.'**
  String get statsNoAwardsYet;

  /// No description provided for @achRoyalFlushTitle.
  ///
  /// In en, this message translates to:
  /// **'Royal flush'**
  String get achRoyalFlushTitle;

  /// No description provided for @achRoyalFlushBody.
  ///
  /// In en, this message translates to:
  /// **'Made the best hand in poker.'**
  String get achRoyalFlushBody;

  /// No description provided for @achStraightFlushTitle.
  ///
  /// In en, this message translates to:
  /// **'Straight flush'**
  String get achStraightFlushTitle;

  /// No description provided for @achStraightFlushBody.
  ///
  /// In en, this message translates to:
  /// **'Five in a row, all of one suit.'**
  String get achStraightFlushBody;

  /// No description provided for @achQuadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Four of a kind'**
  String get achQuadsTitle;

  /// No description provided for @achQuadsBody.
  ///
  /// In en, this message translates to:
  /// **'All four cards of a rank.'**
  String get achQuadsBody;

  /// No description provided for @achFullHouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Full house'**
  String get achFullHouseTitle;

  /// No description provided for @achFullHouseBody.
  ///
  /// In en, this message translates to:
  /// **'Three of a kind and a pair.'**
  String get achFullHouseBody;

  /// No description provided for @achBigPotTitle.
  ///
  /// In en, this message translates to:
  /// **'Big pot'**
  String get achBigPotTitle;

  /// No description provided for @achBigPotBody.
  ///
  /// In en, this message translates to:
  /// **'Won a pot of 100 big blinds or more.'**
  String get achBigPotBody;

  /// No description provided for @achAllInWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Survived the shove'**
  String get achAllInWinTitle;

  /// No description provided for @achAllInWinBody.
  ///
  /// In en, this message translates to:
  /// **'Won a hand with your whole stack in the middle.'**
  String get achAllInWinBody;

  /// No description provided for @achHands100Title.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get achHands100Title;

  /// No description provided for @achHands100Body.
  ///
  /// In en, this message translates to:
  /// **'Played 100 hands.'**
  String get achHands100Body;

  /// No description provided for @achHands1000Title.
  ///
  /// In en, this message translates to:
  /// **'Veteran'**
  String get achHands1000Title;

  /// No description provided for @achHands1000Body.
  ///
  /// In en, this message translates to:
  /// **'Played 1,000 hands.'**
  String get achHands1000Body;

  /// No description provided for @achBluffs25Title.
  ///
  /// In en, this message translates to:
  /// **'No cards needed'**
  String get achBluffs25Title;

  /// No description provided for @achBluffs25Body.
  ///
  /// In en, this message translates to:
  /// **'Won 25 hands without a showdown.'**
  String get achBluffs25Body;

  /// No description provided for @achRoundWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Last one standing'**
  String get achRoundWinTitle;

  /// No description provided for @achRoundWinBody.
  ///
  /// In en, this message translates to:
  /// **'Won a round.'**
  String get achRoundWinBody;

  /// No description provided for @achPodium3Title.
  ///
  /// In en, this message translates to:
  /// **'Podium'**
  String get achPodium3Title;

  /// No description provided for @achPodium3Body.
  ///
  /// In en, this message translates to:
  /// **'Finished in the top three of three rounds.'**
  String get achPodium3Body;

  /// No description provided for @achTournamentWinTitle.
  ///
  /// In en, this message translates to:
  /// **'Tournament winner'**
  String get achTournamentWinTitle;

  /// No description provided for @achTournamentWinBody.
  ///
  /// In en, this message translates to:
  /// **'Won a tournament.'**
  String get achTournamentWinBody;

  /// No description provided for @visTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see'**
  String get visTitle;

  /// No description provided for @visBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile is private until you say otherwise. Sharing with friends only comes when friends do.'**
  String get visBody;

  /// No description provided for @visOpen.
  ///
  /// In en, this message translates to:
  /// **'Who can see'**
  String get visOpen;

  /// No description provided for @visMenuHint.
  ///
  /// In en, this message translates to:
  /// **'What a public profile would show'**
  String get visMenuHint;

  /// No description provided for @visPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visPublic;

  /// No description provided for @visPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visPrivate;

  /// No description provided for @visProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get visProfile;

  /// No description provided for @visProfileHint.
  ///
  /// In en, this message translates to:
  /// **'your name and when you started playing'**
  String get visProfileHint;

  /// No description provided for @visWinnings.
  ///
  /// In en, this message translates to:
  /// **'Winnings'**
  String get visWinnings;

  /// No description provided for @visWinningsHint.
  ///
  /// In en, this message translates to:
  /// **'hands, tables and what you are up'**
  String get visWinningsHint;

  /// No description provided for @visBestHands.
  ///
  /// In en, this message translates to:
  /// **'Best hands'**
  String get visBestHands;

  /// No description provided for @visBestHandsHint.
  ///
  /// In en, this message translates to:
  /// **'the hands you made, as the table saw them'**
  String get visBestHandsHint;

  /// No description provided for @visAchievements.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get visAchievements;

  /// No description provided for @visAchievementsHint.
  ///
  /// In en, this message translates to:
  /// **'the milestones you reached'**
  String get visAchievementsHint;

  /// No description provided for @visActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get visActivity;

  /// No description provided for @visActivityHint.
  ///
  /// In en, this message translates to:
  /// **'when you last played'**
  String get visActivityHint;

  /// No description provided for @visAllPrivate.
  ///
  /// In en, this message translates to:
  /// **'Nothing is public yet.'**
  String get visAllPrivate;

  /// No description provided for @visSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save that.'**
  String get visSaveFailed;

  /// No description provided for @handRoyalFlush.
  ///
  /// In en, this message translates to:
  /// **'Royal flush'**
  String get handRoyalFlush;

  /// No description provided for @handStraightFlush.
  ///
  /// In en, this message translates to:
  /// **'Straight flush'**
  String get handStraightFlush;

  /// No description provided for @handFourOfAKind.
  ///
  /// In en, this message translates to:
  /// **'Four of a kind'**
  String get handFourOfAKind;

  /// No description provided for @handFullHouse.
  ///
  /// In en, this message translates to:
  /// **'Full house'**
  String get handFullHouse;

  /// No description provided for @handFlush.
  ///
  /// In en, this message translates to:
  /// **'Flush'**
  String get handFlush;

  /// No description provided for @handStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get handStraight;

  /// No description provided for @handThreeOfAKind.
  ///
  /// In en, this message translates to:
  /// **'Three of a kind'**
  String get handThreeOfAKind;

  /// No description provided for @handTwoPair.
  ///
  /// In en, this message translates to:
  /// **'Two pair'**
  String get handTwoPair;

  /// No description provided for @handPair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get handPair;

  /// No description provided for @handHighCard.
  ///
  /// In en, this message translates to:
  /// **'High card'**
  String get handHighCard;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {handle}'**
  String accountSignedInAs(String handle);

  /// No description provided for @accountGuestHint.
  ///
  /// In en, this message translates to:
  /// **'Playing as a guest'**
  String get accountGuestHint;

  /// No description provided for @accountPlayAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Play as guest'**
  String get accountPlayAsGuest;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @fold.
  ///
  /// In en, this message translates to:
  /// **'Fold'**
  String get fold;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call {amount}'**
  String call(String amount);

  /// No description provided for @bet.
  ///
  /// In en, this message translates to:
  /// **'Bet'**
  String get bet;

  /// No description provided for @raise.
  ///
  /// In en, this message translates to:
  /// **'Raise'**
  String get raise;

  /// No description provided for @allIn.
  ///
  /// In en, this message translates to:
  /// **'All-in'**
  String get allIn;

  /// No description provided for @allInAmount.
  ///
  /// In en, this message translates to:
  /// **'All-in {amount}'**
  String allInAmount(String amount);

  /// No description provided for @raiseTo.
  ///
  /// In en, this message translates to:
  /// **'Raise to {amount}'**
  String raiseTo(String amount);

  /// No description provided for @betAmount.
  ///
  /// In en, this message translates to:
  /// **'Bet {amount}'**
  String betAmount(String amount);

  /// No description provided for @presetMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get presetMin;

  /// No description provided for @presetHalfPot.
  ///
  /// In en, this message translates to:
  /// **'1/2 Pot'**
  String get presetHalfPot;

  /// No description provided for @presetThreeQuarterPot.
  ///
  /// In en, this message translates to:
  /// **'3/4 Pot'**
  String get presetThreeQuarterPot;

  /// No description provided for @presetPot.
  ///
  /// In en, this message translates to:
  /// **'Pot'**
  String get presetPot;

  /// No description provided for @presetAllIn.
  ///
  /// In en, this message translates to:
  /// **'All-in'**
  String get presetAllIn;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed: {min} - {max}'**
  String amountRange(String min, String max);

  /// No description provided for @amountClamped.
  ///
  /// In en, this message translates to:
  /// **'Amount adjusted to {amount}'**
  String amountClamped(String amount);

  /// No description provided for @rebuy.
  ///
  /// In en, this message translates to:
  /// **'Rebuy {amount}'**
  String rebuy(String amount);

  /// No description provided for @sitOut.
  ///
  /// In en, this message translates to:
  /// **'Sit out'**
  String get sitOut;

  /// No description provided for @sitIn.
  ///
  /// In en, this message translates to:
  /// **'I\'m back'**
  String get sitIn;

  /// No description provided for @showCards.
  ///
  /// In en, this message translates to:
  /// **'Show cards'**
  String get showCards;

  /// No description provided for @waitingForPlayers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for players...'**
  String get waitingForPlayers;

  /// No description provided for @tablePaused.
  ///
  /// In en, this message translates to:
  /// **'Table paused'**
  String get tablePaused;

  /// No description provided for @tableWaiting.
  ///
  /// In en, this message translates to:
  /// **'The table has not started yet'**
  String get tableWaiting;

  /// No description provided for @yourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurn;

  /// No description provided for @badgeDealer.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get badgeDealer;

  /// No description provided for @badgeSmallBlind.
  ///
  /// In en, this message translates to:
  /// **'SB'**
  String get badgeSmallBlind;

  /// No description provided for @badgeBigBlind.
  ///
  /// In en, this message translates to:
  /// **'BB'**
  String get badgeBigBlind;

  /// No description provided for @badgeSittingOut.
  ///
  /// In en, this message translates to:
  /// **'Sitting out'**
  String get badgeSittingOut;

  /// No description provided for @badgeDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get badgeDisconnected;

  /// No description provided for @badgeAllIn.
  ///
  /// In en, this message translates to:
  /// **'All-in'**
  String get badgeAllIn;

  /// No description provided for @badgeBusted.
  ///
  /// In en, this message translates to:
  /// **'Busted'**
  String get badgeBusted;

  /// No description provided for @badgeWaiting.
  ///
  /// In en, this message translates to:
  /// **'Next hand'**
  String get badgeWaiting;

  /// No description provided for @badgeFolded.
  ///
  /// In en, this message translates to:
  /// **'Folded'**
  String get badgeFolded;

  /// No description provided for @badgeNoAudio.
  ///
  /// In en, this message translates to:
  /// **'No audio'**
  String get badgeNoAudio;

  /// No description provided for @networkCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get networkCheckTitle;

  /// No description provided for @networkCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get networkCheckAgain;

  /// No description provided for @networkChecking.
  ///
  /// In en, this message translates to:
  /// **'checking'**
  String get networkChecking;

  /// No description provided for @networkStatusOk.
  ///
  /// In en, this message translates to:
  /// **'direct connections possible'**
  String get networkStatusOk;

  /// No description provided for @networkStatusRelay.
  ///
  /// In en, this message translates to:
  /// **'relay server working'**
  String get networkStatusRelay;

  /// No description provided for @networkStatusNoStun.
  ///
  /// In en, this message translates to:
  /// **'no STUN server'**
  String get networkStatusNoStun;

  /// No description provided for @networkStatusStunBlocked.
  ///
  /// In en, this message translates to:
  /// **'STUN blocked'**
  String get networkStatusStunBlocked;

  /// No description provided for @networkStatusSymmetric.
  ///
  /// In en, this message translates to:
  /// **'symmetric NAT'**
  String get networkStatusSymmetric;

  /// No description provided for @networkStatusRelayFailed.
  ///
  /// In en, this message translates to:
  /// **'relay server not answering'**
  String get networkStatusRelayFailed;

  /// No description provided for @networkStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'could not check'**
  String get networkStatusUnknown;

  /// No description provided for @networkNoStun.
  ///
  /// In en, this message translates to:
  /// **'No STUN server is configured: voice and video only work between devices in the same network. A STUN server (free public ones exist) lets browsers find their public address, which is enough as long as one of two players has a normal home router; a relay server (TURN) additionally carries the audio and video for players on mobile data or in strict networks. Ask the host.'**
  String get networkNoStun;

  /// No description provided for @networkStunBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your network blocks the address lookup (STUN), probably a firewall. From here voice and video only work with players in the same network; everyone else needs a relay server (TURN). Ask the host for one or use another network.'**
  String get networkStunBlocked;

  /// No description provided for @networkSymmetric.
  ///
  /// In en, this message translates to:
  /// **'Your network uses a symmetric NAT. You can reach players in the same network and players whose network is not symmetric (a normal home router); players on mobile data or behind another symmetric NAT cannot be reached without a relay server (TURN). Ask the host for one or use another network, for example Wi-Fi instead of mobile data.'**
  String get networkSymmetric;

  /// No description provided for @networkRelayFailed.
  ///
  /// In en, this message translates to:
  /// **'The relay server (TURN) does not answer or rejects the credentials. Players in other networks will not be able to connect.'**
  String get networkRelayFailed;

  /// No description provided for @networkHostHintStun.
  ///
  /// In en, this message translates to:
  /// **'As the host: set WEBRTC_STUN_URLS on the server, for example stun:stun.l.google.com:19302 (free, no account), and for players on mobile data or in strict networks also WEBRTC_TURN_URLS with WEBRTC_TURN_USERNAME and WEBRTC_TURN_CREDENTIAL (your own coturn or a hosted TURN service). Restart the server afterwards.'**
  String get networkHostHintStun;

  /// No description provided for @networkHostHintTurn.
  ///
  /// In en, this message translates to:
  /// **'As the host: set WEBRTC_TURN_URLS with WEBRTC_TURN_USERNAME and WEBRTC_TURN_CREDENTIAL on the server (your own coturn or a hosted TURN service; it relays the audio and video for players whose networks cannot connect directly) and restart it.'**
  String get networkHostHintTurn;

  /// No description provided for @networkHostHintRelay.
  ///
  /// In en, this message translates to:
  /// **'As the host: check the TURN server, its credentials and the firewall (UDP and TCP 3478, the relay port range, external-ip when the server sits behind NAT).'**
  String get networkHostHintRelay;

  /// No description provided for @networkPeerNoRoute.
  ///
  /// In en, this message translates to:
  /// **'Your networks cannot reach each other directly; a relay server (TURN) would fix this.'**
  String get networkPeerNoRoute;

  /// No description provided for @voicePeerFailed.
  ///
  /// In en, this message translates to:
  /// **'No audio connection to {name}.'**
  String voicePeerFailed(String name);

  /// No description provided for @mainPot.
  ///
  /// In en, this message translates to:
  /// **'Main pot'**
  String get mainPot;

  /// No description provided for @sidePot.
  ///
  /// In en, this message translates to:
  /// **'Side pot {n}'**
  String sidePot(int n);

  /// No description provided for @potTotal.
  ///
  /// In en, this message translates to:
  /// **'Pot {amount}'**
  String potTotal(String amount);

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get tabLog;

  /// No description provided for @tabLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get tabLeaderboard;

  /// No description provided for @panelToggle.
  ///
  /// In en, this message translates to:
  /// **'Menu: chat, log, leaderboard, settings'**
  String get panelToggle;

  /// No description provided for @panelMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get panelMenu;

  /// No description provided for @chatPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatPlaceholder;

  /// No description provided for @chatDisabled.
  ///
  /// In en, this message translates to:
  /// **'Chat is disabled'**
  String get chatDisabled;

  /// No description provided for @chatMuted.
  ///
  /// In en, this message translates to:
  /// **'You are muted'**
  String get chatMuted;

  /// No description provided for @chatSpectatorsOff.
  ///
  /// In en, this message translates to:
  /// **'Spectator chat is off'**
  String get chatSpectatorsOff;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get chatAdmin;

  /// No description provided for @logCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get logCopy;

  /// No description provided for @logCopied.
  ///
  /// In en, this message translates to:
  /// **'Log copied'**
  String get logCopied;

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get logEmpty;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi!'**
  String get chatEmpty;

  /// No description provided for @lbName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get lbName;

  /// No description provided for @lbStack.
  ///
  /// In en, this message translates to:
  /// **'Stack'**
  String get lbStack;

  /// No description provided for @lbNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get lbNet;

  /// No description provided for @lbHandsWon.
  ///
  /// In en, this message translates to:
  /// **'Won'**
  String get lbHandsWon;

  /// No description provided for @lbBiggestPot.
  ///
  /// In en, this message translates to:
  /// **'Biggest pot'**
  String get lbBiggestPot;

  /// No description provided for @shortcutsTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get shortcutsTitle;

  /// No description provided for @shortcutsHint.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts are inactive while typing. Esc leaves the text field.'**
  String get shortcutsHint;

  /// No description provided for @scFold.
  ///
  /// In en, this message translates to:
  /// **'Fold'**
  String get scFold;

  /// No description provided for @scCheckCall.
  ///
  /// In en, this message translates to:
  /// **'Check / Call'**
  String get scCheckCall;

  /// No description provided for @scOpenRaise.
  ///
  /// In en, this message translates to:
  /// **'Open the raise control'**
  String get scOpenRaise;

  /// No description provided for @scAllIn.
  ///
  /// In en, this message translates to:
  /// **'Select all-in (Enter confirms)'**
  String get scAllIn;

  /// No description provided for @scShowFirst.
  ///
  /// In en, this message translates to:
  /// **'Show the first card'**
  String get scShowFirst;

  /// No description provided for @scShowSecond.
  ///
  /// In en, this message translates to:
  /// **'Show the second card'**
  String get scShowSecond;

  /// No description provided for @scShowBoth.
  ///
  /// In en, this message translates to:
  /// **'Show both cards'**
  String get scShowBoth;

  /// No description provided for @scRabbitHunt.
  ///
  /// In en, this message translates to:
  /// **'See the rest of the board'**
  String get scRabbitHunt;

  /// No description provided for @scPreCheckFold.
  ///
  /// In en, this message translates to:
  /// **'Arm check / fold (hold)'**
  String get scPreCheckFold;

  /// No description provided for @scPreCallAny.
  ///
  /// In en, this message translates to:
  /// **'Arm call any (hold)'**
  String get scPreCallAny;

  /// No description provided for @scSitOut.
  ///
  /// In en, this message translates to:
  /// **'Sit out, or come back (hold)'**
  String get scSitOut;

  /// No description provided for @scRebuy.
  ///
  /// In en, this message translates to:
  /// **'Buy back in (hold)'**
  String get scRebuy;

  /// No description provided for @scHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Held keys fill up while you press them.'**
  String get scHoldHint;

  /// No description provided for @scPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets Min / 1/2 Pot / 3/4 Pot / Pot (controller: up to all-in)'**
  String get scPresets;

  /// No description provided for @scAmount.
  ///
  /// In en, this message translates to:
  /// **'+/- one big blind (Shift: +/- five)'**
  String get scAmount;

  /// No description provided for @scConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm bet / raise'**
  String get scConfirm;

  /// No description provided for @scCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel raise / close overlay / leave text field'**
  String get scCancel;

  /// No description provided for @scChat.
  ///
  /// In en, this message translates to:
  /// **'Focus chat'**
  String get scChat;

  /// No description provided for @scLog.
  ///
  /// In en, this message translates to:
  /// **'Toggle log'**
  String get scLog;

  /// No description provided for @scLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Toggle leaderboard'**
  String get scLeaderboard;

  /// No description provided for @scSound.
  ///
  /// In en, this message translates to:
  /// **'Toggle sound'**
  String get scSound;

  /// No description provided for @scHelp.
  ///
  /// In en, this message translates to:
  /// **'This overlay'**
  String get scHelp;

  /// No description provided for @scSettingsPanel.
  ///
  /// In en, this message translates to:
  /// **'Jump into the side panel and back out (opens it)'**
  String get scSettingsPanel;

  /// No description provided for @scSections.
  ///
  /// In en, this message translates to:
  /// **'Jump between action bar, table and side panel'**
  String get scSections;

  /// No description provided for @scPanelTabs.
  ///
  /// In en, this message translates to:
  /// **'Chat, log, leaderboard, settings: the side panel\'s tabs, from anywhere'**
  String get scPanelTabs;

  /// No description provided for @shortcutsPadHint.
  ///
  /// In en, this message translates to:
  /// **'Controller: the D-pad or left stick moves between controls (and on into the next area), A activates, B goes back or closes. LT / RT open the side panel\'s tabs from anywhere; LB / RB jump between the action bar, the table and the side panel; Back opens the side panel and jumps into it. The strip under the action bar always shows where you are and what the buttons do there. At the table X folds, Y opens the raise, ↑ ↓ step the amount, ← → cycle the presets, LB / RB step by five, RT selects all-in.'**
  String get shortcutsPadHint;

  /// No description provided for @padWhereActions.
  ///
  /// In en, this message translates to:
  /// **'Action bar'**
  String get padWhereActions;

  /// No description provided for @padWhereTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get padWhereTable;

  /// No description provided for @padWherePanel.
  ///
  /// In en, this message translates to:
  /// **'Side panel'**
  String get padWherePanel;

  /// No description provided for @padWhereDialog.
  ///
  /// In en, this message translates to:
  /// **'Dialog'**
  String get padWhereDialog;

  /// No description provided for @padMove.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get padMove;

  /// No description provided for @padSelect.
  ///
  /// In en, this message translates to:
  /// **'select'**
  String get padSelect;

  /// No description provided for @padOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get padOpen;

  /// No description provided for @padBack.
  ///
  /// In en, this message translates to:
  /// **'back'**
  String get padBack;

  /// No description provided for @padClose.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get padClose;

  /// No description provided for @padTab.
  ///
  /// In en, this message translates to:
  /// **'panel tab'**
  String get padTab;

  /// No description provided for @padSection.
  ///
  /// In en, this message translates to:
  /// **'section'**
  String get padSection;

  /// No description provided for @padPanel.
  ///
  /// In en, this message translates to:
  /// **'side panel'**
  String get padPanel;

  /// No description provided for @padAmount.
  ///
  /// In en, this message translates to:
  /// **'amount'**
  String get padAmount;

  /// No description provided for @padPreset.
  ///
  /// In en, this message translates to:
  /// **'preset'**
  String get padPreset;

  /// No description provided for @padFive.
  ///
  /// In en, this message translates to:
  /// **'±5 blinds'**
  String get padFive;

  /// No description provided for @padConfirm.
  ///
  /// In en, this message translates to:
  /// **'confirm'**
  String get padConfirm;

  /// No description provided for @padCancel.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get padCancel;

  /// No description provided for @padHelp.
  ///
  /// In en, this message translates to:
  /// **'help'**
  String get padHelp;

  /// No description provided for @padConnected.
  ///
  /// In en, this message translates to:
  /// **'Controller connected ({id}): X folds, A checks or calls, Y opens the raise, LT / RT open the side panel, Start shows all buttons. On-screen hints: Preferences.'**
  String padConnected(String id);

  /// No description provided for @padHints.
  ///
  /// In en, this message translates to:
  /// **'Show controller hints on screen (legend and button caps)'**
  String get padHints;

  /// No description provided for @padDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected: {id}, {mapping} layout, last button {button}'**
  String padDetected(String id, String mapping, String button);

  /// No description provided for @padMappingStandard.
  ///
  /// In en, this message translates to:
  /// **'standard'**
  String get padMappingStandard;

  /// No description provided for @padMappingOther.
  ///
  /// In en, this message translates to:
  /// **'non-standard, remapped'**
  String get padMappingOther;

  /// No description provided for @soundOn.
  ///
  /// In en, this message translates to:
  /// **'Sound on'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In en, this message translates to:
  /// **'Sound off'**
  String get soundOff;

  /// No description provided for @spectatorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} watching'**
  String spectatorsCount(int count);

  /// No description provided for @roleSpectator.
  ///
  /// In en, this message translates to:
  /// **'Spectating'**
  String get roleSpectator;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin view'**
  String get roleAdmin;

  /// No description provided for @yourTurnTitle.
  ///
  /// In en, this message translates to:
  /// **'▶ Your turn — Showdown'**
  String get yourTurnTitle;

  /// No description provided for @seatLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat {seat}'**
  String seatLabel(int seat);

  /// No description provided for @emptySeat.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get emptySeat;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @logHandStarted.
  ///
  /// In en, this message translates to:
  /// **'Hand #{number} starts. Dealer: {name}'**
  String logHandStarted(int number, String name);

  /// No description provided for @logAnte.
  ///
  /// In en, this message translates to:
  /// **'{name} posts ante {amount}'**
  String logAnte(String name, String amount);

  /// No description provided for @logSmallBlind.
  ///
  /// In en, this message translates to:
  /// **'{name} posts small blind {amount}'**
  String logSmallBlind(String name, String amount);

  /// No description provided for @logBigBlind.
  ///
  /// In en, this message translates to:
  /// **'{name} posts big blind {amount}'**
  String logBigBlind(String name, String amount);

  /// No description provided for @logDealt.
  ///
  /// In en, this message translates to:
  /// **'You are dealt {cards}'**
  String logDealt(String cards);

  /// No description provided for @logFold.
  ///
  /// In en, this message translates to:
  /// **'{name} folds'**
  String logFold(String name);

  /// No description provided for @logCheck.
  ///
  /// In en, this message translates to:
  /// **'{name} checks'**
  String logCheck(String name);

  /// No description provided for @logCall.
  ///
  /// In en, this message translates to:
  /// **'{name} calls {amount}'**
  String logCall(String name, String amount);

  /// No description provided for @logBet.
  ///
  /// In en, this message translates to:
  /// **'{name} bets {amount}'**
  String logBet(String name, String amount);

  /// No description provided for @logRaise.
  ///
  /// In en, this message translates to:
  /// **'{name} raises to {amount}'**
  String logRaise(String name, String amount);

  /// No description provided for @logAllInSuffix.
  ///
  /// In en, this message translates to:
  /// **' (all-in)'**
  String get logAllInSuffix;

  /// No description provided for @logTimeoutCheck.
  ///
  /// In en, this message translates to:
  /// **'{name} times out and checks'**
  String logTimeoutCheck(String name);

  /// No description provided for @logTimeoutFold.
  ///
  /// In en, this message translates to:
  /// **'{name} times out and folds'**
  String logTimeoutFold(String name);

  /// No description provided for @logUncalled.
  ///
  /// In en, this message translates to:
  /// **'Uncalled bet of {amount} returned to {name}'**
  String logUncalled(String amount, String name);

  /// No description provided for @logFlop.
  ///
  /// In en, this message translates to:
  /// **'Flop: {cards}'**
  String logFlop(String cards);

  /// No description provided for @logTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn: {cards}'**
  String logTurn(String cards);

  /// No description provided for @logRiver.
  ///
  /// In en, this message translates to:
  /// **'River: {cards}'**
  String logRiver(String cards);

  /// No description provided for @logReveal.
  ///
  /// In en, this message translates to:
  /// **'{name} shows {cards} - {description}'**
  String logReveal(String name, String cards, String description);

  /// No description provided for @logRevealNoDesc.
  ///
  /// In en, this message translates to:
  /// **'{name} shows {cards}'**
  String logRevealNoDesc(String name, String cards);

  /// No description provided for @logWin.
  ///
  /// In en, this message translates to:
  /// **'{name} wins {amount} ({pot}) with {description}'**
  String logWin(String name, String amount, String pot, String description);

  /// No description provided for @logWinUncontested.
  ///
  /// In en, this message translates to:
  /// **'{name} wins {amount} ({pot})'**
  String logWinUncontested(String name, String amount, String pot);

  /// No description provided for @logVoided.
  ///
  /// In en, this message translates to:
  /// **'Hand voided ({reason})'**
  String logVoided(String reason);

  /// No description provided for @logJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined (seat {seat})'**
  String logJoined(String name, int seat);

  /// No description provided for @logLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String logLeft(String name);

  /// No description provided for @logKicked.
  ///
  /// In en, this message translates to:
  /// **'{name} was removed'**
  String logKicked(String name);

  /// No description provided for @logSatOut.
  ///
  /// In en, this message translates to:
  /// **'{name} sits out'**
  String logSatOut(String name);

  /// No description provided for @logSatIn.
  ///
  /// In en, this message translates to:
  /// **'{name} is back'**
  String logSatIn(String name);

  /// No description provided for @logBusted.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of chips'**
  String logBusted(String name);

  /// No description provided for @logRebought.
  ///
  /// In en, this message translates to:
  /// **'{name} rebought {amount}'**
  String logRebought(String name, String amount);

  /// No description provided for @logChips.
  ///
  /// In en, this message translates to:
  /// **'Admin adjusted chips of {name} by {delta}'**
  String logChips(String name, String delta);

  /// No description provided for @logSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings changed: {fields}'**
  String logSettings(String fields);

  /// No description provided for @logStarted.
  ///
  /// In en, this message translates to:
  /// **'Table started'**
  String get logStarted;

  /// No description provided for @logPaused.
  ///
  /// In en, this message translates to:
  /// **'Table paused'**
  String get logPaused;

  /// No description provided for @logResumed.
  ///
  /// In en, this message translates to:
  /// **'Table resumed'**
  String get logResumed;

  /// No description provided for @logEnded.
  ///
  /// In en, this message translates to:
  /// **'Table ended'**
  String get logEnded;

  /// No description provided for @logRestarted.
  ///
  /// In en, this message translates to:
  /// **'Server restarted'**
  String get logRestarted;

  /// No description provided for @logNewRound.
  ///
  /// In en, this message translates to:
  /// **'New round started'**
  String get logNewRound;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminTitle;

  /// No description provided for @adminNewTable.
  ///
  /// In en, this message translates to:
  /// **'New table'**
  String get adminNewTable;

  /// No description provided for @adminCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminCreate;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminSave;

  /// No description provided for @adminSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get adminSaved;

  /// No description provided for @adminSavedNextHand.
  ///
  /// In en, this message translates to:
  /// **'Saved. Applies from the next hand: {fields}'**
  String adminSavedNextHand(String fields);

  /// No description provided for @adminNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get adminNoChanges;

  /// No description provided for @adminTableName.
  ///
  /// In en, this message translates to:
  /// **'Table name'**
  String get adminTableName;

  /// No description provided for @adminTableNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'1-40 characters'**
  String get adminTableNameInvalid;

  /// No description provided for @adminPlayersCount.
  ///
  /// In en, this message translates to:
  /// **'{seated}/{max} players'**
  String adminPlayersCount(int seated, int max);

  /// No description provided for @adminCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get adminCopyLink;

  /// No description provided for @adminLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get adminLinkCopied;

  /// No description provided for @adminQrCode.
  ///
  /// In en, this message translates to:
  /// **'QR code'**
  String get adminQrCode;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// No description provided for @adminPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get adminPlayers;

  /// No description provided for @adminChat.
  ///
  /// In en, this message translates to:
  /// **'Chat moderation'**
  String get adminChat;

  /// No description provided for @adminHands.
  ///
  /// In en, this message translates to:
  /// **'Recent hands'**
  String get adminHands;

  /// No description provided for @adminNoHands.
  ///
  /// In en, this message translates to:
  /// **'No hands yet'**
  String get adminNoHands;

  /// No description provided for @adminHandRow.
  ///
  /// In en, this message translates to:
  /// **'Hand #{number} · {time}'**
  String adminHandRow(int number, String time);

  /// No description provided for @adminHandVoided.
  ///
  /// In en, this message translates to:
  /// **'voided'**
  String get adminHandVoided;

  /// No description provided for @adminStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get adminStart;

  /// No description provided for @adminPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get adminPause;

  /// No description provided for @adminResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get adminResume;

  /// No description provided for @adminEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get adminEnd;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete table'**
  String get adminDelete;

  /// No description provided for @adminEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End the table?'**
  String get adminEndTitle;

  /// No description provided for @adminEndBody.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the running hand should finish first.'**
  String get adminEndBody;

  /// No description provided for @adminEndAfterHand.
  ///
  /// In en, this message translates to:
  /// **'After this hand'**
  String get adminEndAfterHand;

  /// No description provided for @adminEndNow.
  ///
  /// In en, this message translates to:
  /// **'Now, void the hand'**
  String get adminEndNow;

  /// No description provided for @adminNewRound.
  ///
  /// In en, this message translates to:
  /// **'New round'**
  String get adminNewRound;

  /// No description provided for @adminNewRoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new round?'**
  String get adminNewRoundTitle;

  /// No description provided for @adminNewRoundBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone keeps their seat and the table keeps its link. Stacks go back to the start money, the statistics start over and the blinds return to the level you set. The standings of this round stay readable.'**
  String get adminNewRoundBody;

  /// No description provided for @adminNewRoundStart.
  ///
  /// In en, this message translates to:
  /// **'Start a new round'**
  String get adminNewRoundStart;

  /// No description provided for @adminNewRoundDone.
  ///
  /// In en, this message translates to:
  /// **'New round opened'**
  String get adminNewRoundDone;

  /// No description provided for @adminDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this table?'**
  String get adminDeleteTitle;

  /// No description provided for @adminDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All hands, chat and standings of this table are removed.'**
  String get adminDeleteBody;

  /// No description provided for @adminDeleteRunning.
  ///
  /// In en, this message translates to:
  /// **'A running table cannot be deleted. Pause or end it first.'**
  String get adminDeleteRunning;

  /// No description provided for @adminKick.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get adminKick;

  /// No description provided for @adminKickTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String adminKickTitle(String name);

  /// No description provided for @adminKickBody.
  ///
  /// In en, this message translates to:
  /// **'The player folds now and the seat is freed after the hand.'**
  String get adminKickBody;

  /// No description provided for @adminChips.
  ///
  /// In en, this message translates to:
  /// **'Chips'**
  String get adminChips;

  /// No description provided for @adminChipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust chips of {name}'**
  String adminChipsTitle(String name);

  /// No description provided for @adminChipsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount (negative to remove)'**
  String get adminChipsAmount;

  /// No description provided for @adminChipsNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get adminChipsNote;

  /// No description provided for @adminChipsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a non-zero whole number'**
  String get adminChipsInvalid;

  /// No description provided for @adminChipsApplied.
  ///
  /// In en, this message translates to:
  /// **'Chips adjusted'**
  String get adminChipsApplied;

  /// No description provided for @adminChipsQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued until the hand ends'**
  String get adminChipsQueued;

  /// No description provided for @adminMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get adminMute;

  /// No description provided for @adminUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get adminUnmute;

  /// No description provided for @adminRemoveMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove message'**
  String get adminRemoveMessage;

  /// No description provided for @adminNoChat.
  ///
  /// In en, this message translates to:
  /// **'No chat messages'**
  String get adminNoChat;

  /// No description provided for @adminStateChanged.
  ///
  /// In en, this message translates to:
  /// **'Table is now {state}'**
  String adminStateChanged(String state);

  /// No description provided for @adminAppliesNextHand.
  ///
  /// In en, this message translates to:
  /// **'applies from the next hand'**
  String get adminAppliesNextHand;

  /// No description provided for @adminAppliesImmediately.
  ///
  /// In en, this message translates to:
  /// **'applies immediately'**
  String get adminAppliesImmediately;

  /// No description provided for @adminAppliesNextJoin.
  ///
  /// In en, this message translates to:
  /// **'applies to the next join'**
  String get adminAppliesNextJoin;

  /// No description provided for @adminAppliesFuture.
  ///
  /// In en, this message translates to:
  /// **'applies to future joins and rebuys'**
  String get adminAppliesFuture;

  /// No description provided for @adminSpectatorsWatching.
  ///
  /// In en, this message translates to:
  /// **'{count} watching · {connections} connections'**
  String adminSpectatorsWatching(int count, int connections);

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Table password (empty = none)'**
  String get setPassword;

  /// No description provided for @setPasswordKeep.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep the current password'**
  String get setPasswordKeep;

  /// No description provided for @setPasswordClear.
  ///
  /// In en, this message translates to:
  /// **'Remove password'**
  String get setPasswordClear;

  /// No description provided for @setMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Max players'**
  String get setMaxPlayers;

  /// No description provided for @setStartMoney.
  ///
  /// In en, this message translates to:
  /// **'Start money'**
  String get setStartMoney;

  /// No description provided for @setSmallBlind.
  ///
  /// In en, this message translates to:
  /// **'Small blind'**
  String get setSmallBlind;

  /// No description provided for @setBigBlind.
  ///
  /// In en, this message translates to:
  /// **'Big blind'**
  String get setBigBlind;

  /// No description provided for @setAnte.
  ///
  /// In en, this message translates to:
  /// **'Ante'**
  String get setAnte;

  /// No description provided for @setTurnTime.
  ///
  /// In en, this message translates to:
  /// **'Turn time (s)'**
  String get setTurnTime;

  /// No description provided for @setDisconnectedTurnTime.
  ///
  /// In en, this message translates to:
  /// **'Turn time when disconnected (s)'**
  String get setDisconnectedTurnTime;

  /// No description provided for @setSitOutAfter.
  ///
  /// In en, this message translates to:
  /// **'Sit out after missed turns'**
  String get setSitOutAfter;

  /// No description provided for @setJoinPolicy.
  ///
  /// In en, this message translates to:
  /// **'Join policy'**
  String get setJoinPolicy;

  /// No description provided for @joinPolicyAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get joinPolicyAlways;

  /// No description provided for @joinPolicyBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'Only before the start'**
  String get joinPolicyBeforeStart;

  /// No description provided for @joinPolicyClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get joinPolicyClosed;

  /// No description provided for @setAllowSpectators.
  ///
  /// In en, this message translates to:
  /// **'Allow spectators'**
  String get setAllowSpectators;

  /// No description provided for @setSpectatorChat.
  ///
  /// In en, this message translates to:
  /// **'Spectators may chat'**
  String get setSpectatorChat;

  /// No description provided for @setChatEnabled.
  ///
  /// In en, this message translates to:
  /// **'Chat enabled'**
  String get setChatEnabled;

  /// No description provided for @setAllowRebuy.
  ///
  /// In en, this message translates to:
  /// **'Allow rebuys'**
  String get setAllowRebuy;

  /// No description provided for @setShowdownReveal.
  ///
  /// In en, this message translates to:
  /// **'Showdown reveal'**
  String get setShowdownReveal;

  /// No description provided for @setVariant.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get setVariant;

  /// No description provided for @variantHoldem.
  ///
  /// In en, this message translates to:
  /// **'Texas Hold\'em'**
  String get variantHoldem;

  /// No description provided for @variantRoyal.
  ///
  /// In en, this message translates to:
  /// **'Royal Hold\'em (10 to Ace)'**
  String get variantRoyal;

  /// No description provided for @valRoyalMaxPlayers.
  ///
  /// In en, this message translates to:
  /// **'Royal Hold\'em seats at most 6 players'**
  String get valRoyalMaxPlayers;

  /// No description provided for @revealAll.
  ///
  /// In en, this message translates to:
  /// **'All hands'**
  String get revealAll;

  /// No description provided for @revealWinnersOnly.
  ///
  /// In en, this message translates to:
  /// **'Winners only'**
  String get revealWinnersOnly;

  /// No description provided for @setAutoStart.
  ///
  /// In en, this message translates to:
  /// **'Start automatically'**
  String get setAutoStart;

  /// No description provided for @setHandDelay.
  ///
  /// In en, this message translates to:
  /// **'Pause between hands (ms)'**
  String get setHandDelay;

  /// No description provided for @valRange.
  ///
  /// In en, this message translates to:
  /// **'Must be between {min} and {max}'**
  String valRange(String min, String max);

  /// No description provided for @valMin.
  ///
  /// In en, this message translates to:
  /// **'Must be at least {min}'**
  String valMin(String min);

  /// No description provided for @valInteger.
  ///
  /// In en, this message translates to:
  /// **'Must be a whole number'**
  String get valInteger;

  /// No description provided for @valBigBlind.
  ///
  /// In en, this message translates to:
  /// **'Must be at least the small blind'**
  String get valBigBlind;

  /// No description provided for @valDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Must be between 3 and the turn time'**
  String get valDisconnected;

  /// No description provided for @valPassword.
  ///
  /// In en, this message translates to:
  /// **'Must be empty or 4-64 characters'**
  String get valPassword;

  /// No description provided for @fourColorDeck.
  ///
  /// In en, this message translates to:
  /// **'Four-color deck'**
  String get fourColorDeck;

  /// No description provided for @chipStacks.
  ///
  /// In en, this message translates to:
  /// **'Chip stacks on the table'**
  String get chipStacks;

  /// No description provided for @fixedSeats.
  ///
  /// In en, this message translates to:
  /// **'Fixed seats: the same table for everyone (off: you sit at the bottom)'**
  String get fixedSeats;

  /// No description provided for @landingCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Host a game'**
  String get landingCreateTitle;

  /// No description provided for @landingCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Whoever creates a table hosts it: an Admin tab at the table lets you change settings, manage players and end the game. No account needed.'**
  String get landingCreateHint;

  /// No description provided for @landingCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a table'**
  String get landingCreate;

  /// No description provided for @tabAdmin.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get tabAdmin;

  /// No description provided for @adminKey.
  ///
  /// In en, this message translates to:
  /// **'Admin key'**
  String get adminKey;

  /// No description provided for @adminKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep this key. It lets you manage the table from another device or browser; anyone who has it can do the same.'**
  String get adminKeyHint;

  /// No description provided for @adminKeyCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy key'**
  String get adminKeyCopy;

  /// No description provided for @adminKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Key copied'**
  String get adminKeyCopied;

  /// No description provided for @adminKeyRejected.
  ///
  /// In en, this message translates to:
  /// **'This admin key is not valid for this table.'**
  String get adminKeyRejected;

  /// No description provided for @adminDeleted.
  ///
  /// In en, this message translates to:
  /// **'Table deleted'**
  String get adminDeleted;

  /// No description provided for @joinHostBadge.
  ///
  /// In en, this message translates to:
  /// **'You host this table'**
  String get joinHostBadge;

  /// No description provided for @joinHostEnter.
  ///
  /// In en, this message translates to:
  /// **'I host this table: enter the admin key'**
  String get joinHostEnter;

  /// No description provided for @joinHostUse.
  ///
  /// In en, this message translates to:
  /// **'Use key'**
  String get joinHostUse;

  /// No description provided for @adminTabHands.
  ///
  /// In en, this message translates to:
  /// **'Hands'**
  String get adminTabHands;

  /// No description provided for @setBlindsUpMinutes.
  ///
  /// In en, this message translates to:
  /// **'Blinds up every (minutes, 0 = off)'**
  String get setBlindsUpMinutes;

  /// No description provided for @setBlindsUpPercent.
  ///
  /// In en, this message translates to:
  /// **'Blinds up by (%)'**
  String get setBlindsUpPercent;

  /// No description provided for @setAllowDrawing.
  ///
  /// In en, this message translates to:
  /// **'Allow drawing on the table'**
  String get setAllowDrawing;

  /// No description provided for @setTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament mode: no chip adjustments at all, and once a hand is dealt money and information settings and seat changes are locked, for the host too'**
  String get setTournament;

  /// No description provided for @tournamentBadge.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get tournamentBadge;

  /// No description provided for @tournamentLockedNote.
  ///
  /// In en, this message translates to:
  /// **'Tournament running: the settings that could move chips or change what players know are locked.'**
  String get tournamentLockedNote;

  /// No description provided for @rulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules at this table'**
  String get rulesTitle;

  /// No description provided for @rulesShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get rulesShow;

  /// No description provided for @rulesIntro.
  ///
  /// In en, this message translates to:
  /// **'How {table} is set up. You can open this again under Settings.'**
  String rulesIntro(String table);

  /// No description provided for @rulesGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get rulesGame;

  /// No description provided for @rulesBlinds.
  ///
  /// In en, this message translates to:
  /// **'Blinds'**
  String get rulesBlinds;

  /// No description provided for @rulesBlindSchedule.
  ///
  /// In en, this message translates to:
  /// **'Blind schedule'**
  String get rulesBlindSchedule;

  /// No description provided for @rulesBlindsUp.
  ///
  /// In en, this message translates to:
  /// **'Up every {minutes} min by {percent} %'**
  String rulesBlindsUp(int minutes, int percent);

  /// No description provided for @rulesBlindsUpOff.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get rulesBlindsUpOff;

  /// No description provided for @rulesTiming.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get rulesTiming;

  /// No description provided for @rulesTurnTime.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s per turn'**
  String rulesTurnTime(int seconds);

  /// No description provided for @rulesTimeBank.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s time bank, +{refill} s per hand'**
  String rulesTimeBank(int seconds, int refill);

  /// No description provided for @rulesSeatChange.
  ///
  /// In en, this message translates to:
  /// **'Seat changes'**
  String get rulesSeatChange;

  /// No description provided for @rulesSeatChangeFree.
  ///
  /// In en, this message translates to:
  /// **'Between hands, cost a dead big blind'**
  String get rulesSeatChangeFree;

  /// No description provided for @rulesSeatChangeUntilDeal.
  ///
  /// In en, this message translates to:
  /// **'Only until the first hand is dealt'**
  String get rulesSeatChangeUntilDeal;

  /// No description provided for @rulesSeatChangeLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked, a hand has been dealt'**
  String get rulesSeatChangeLocked;

  /// No description provided for @rulesOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get rulesOptions;

  /// No description provided for @rulesPassword.
  ///
  /// In en, this message translates to:
  /// **'Password protected'**
  String get rulesPassword;

  /// No description provided for @rulesTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament mode'**
  String get rulesTournament;

  /// No description provided for @rulesLockedNow.
  ///
  /// In en, this message translates to:
  /// **'locked'**
  String get rulesLockedNow;

  /// No description provided for @rulesTournamentBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone plays the start money: the host can never give or take chips. Once a hand is dealt, blinds, ante, start money, rebuys, the game, the showdown reveal, the blind schedule and the seats are locked, for the host too.'**
  String get rulesTournamentBody;

  /// No description provided for @rulesCashGame.
  ///
  /// In en, this message translates to:
  /// **'Cash game'**
  String get rulesCashGame;

  /// No description provided for @rulesCashGameBody.
  ///
  /// In en, this message translates to:
  /// **'The host may give or take chips and change blinds and other settings at any time; money changes apply from the next hand.'**
  String get rulesCashGameBody;

  /// No description provided for @rulesHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get rulesHost;

  /// No description provided for @rulesHostLifecycle.
  ///
  /// In en, this message translates to:
  /// **'Start, pause and end the table, kick players'**
  String get rulesHostLifecycle;

  /// No description provided for @rulesHostModeration.
  ///
  /// In en, this message translates to:
  /// **'Mute the chat, switch off a player\'s microphone or camera (never on)'**
  String get rulesHostModeration;

  /// No description provided for @rulesHostTiming.
  ///
  /// In en, this message translates to:
  /// **'Change turn time, time bank and the pause between hands'**
  String get rulesHostTiming;

  /// No description provided for @rulesHostBlindsUp.
  ///
  /// In en, this message translates to:
  /// **'Raise the blinds by hand, for everyone and logged'**
  String get rulesHostBlindsUp;

  /// No description provided for @rulesHostChips.
  ///
  /// In en, this message translates to:
  /// **'Give or take chips'**
  String get rulesHostChips;

  /// No description provided for @rulesHostMoney.
  ///
  /// In en, this message translates to:
  /// **'Change blinds, start money, rebuys, game and showdown reveal at any time'**
  String get rulesHostMoney;

  /// No description provided for @rulesHostMoneyBeforeDeal.
  ///
  /// In en, this message translates to:
  /// **'Change blinds, start money, rebuys, game and showdown reveal, but only until the first deal'**
  String get rulesHostMoneyBeforeDeal;

  /// No description provided for @rulesHostMoneyLocked.
  ///
  /// In en, this message translates to:
  /// **'Change blinds, start money, rebuys, game or showdown reveal (locked since the first deal)'**
  String get rulesHostMoneyLocked;

  /// No description provided for @showDrawings.
  ///
  /// In en, this message translates to:
  /// **'Show drawings'**
  String get showDrawings;

  /// No description provided for @peerHideDrawings.
  ///
  /// In en, this message translates to:
  /// **'Hide drawings'**
  String get peerHideDrawings;

  /// No description provided for @drawPencil.
  ///
  /// In en, this message translates to:
  /// **'Draw on the table'**
  String get drawPencil;

  /// No description provided for @drawEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get drawEraser;

  /// No description provided for @drawClearMine.
  ///
  /// In en, this message translates to:
  /// **'Clear my drawings'**
  String get drawClearMine;

  /// No description provided for @drawClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all drawings'**
  String get drawClearAll;

  /// No description provided for @setAllowRabbitHunt.
  ///
  /// In en, this message translates to:
  /// **'Allow rabbit hunting'**
  String get setAllowRabbitHunt;

  /// No description provided for @logRabbitHunt.
  ///
  /// In en, this message translates to:
  /// **'{name} rabbit hunts: {cards}'**
  String logRabbitHunt(String name, String cards);

  /// No description provided for @logBlindsChanged.
  ///
  /// In en, this message translates to:
  /// **'Blinds are now {small}/{big}'**
  String logBlindsChanged(String small, String big);

  /// No description provided for @foldCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for free?'**
  String get foldCheckTitle;

  /// No description provided for @foldCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody has bet. You can check and see the next card without paying anything.'**
  String get foldCheckBody;

  /// No description provided for @foldCheckInstead.
  ///
  /// In en, this message translates to:
  /// **'Check instead'**
  String get foldCheckInstead;

  /// No description provided for @foldAnyway.
  ///
  /// In en, this message translates to:
  /// **'Fold anyway'**
  String get foldAnyway;

  /// No description provided for @showFirstCard.
  ///
  /// In en, this message translates to:
  /// **'Show 1st'**
  String get showFirstCard;

  /// No description provided for @showSecondCard.
  ///
  /// In en, this message translates to:
  /// **'Show 2nd'**
  String get showSecondCard;

  /// No description provided for @rabbitHunt.
  ///
  /// In en, this message translates to:
  /// **'Rabbit hunt'**
  String get rabbitHunt;

  /// No description provided for @preCheckFold.
  ///
  /// In en, this message translates to:
  /// **'Check / Fold'**
  String get preCheckFold;

  /// No description provided for @preCallAny.
  ///
  /// In en, this message translates to:
  /// **'Call any'**
  String get preCallAny;

  /// No description provided for @yourHand.
  ///
  /// In en, this message translates to:
  /// **'Your hand: {description}'**
  String yourHand(String description);

  /// No description provided for @sittingOutNotice.
  ///
  /// In en, this message translates to:
  /// **'You are away and are not dealt in.'**
  String get sittingOutNotice;

  /// No description provided for @youFolded.
  ///
  /// In en, this message translates to:
  /// **'You folded'**
  String get youFolded;

  /// No description provided for @showCoins.
  ///
  /// In en, this message translates to:
  /// **'Show amounts in chips'**
  String get showCoins;

  /// No description provided for @showBigBlinds.
  ///
  /// In en, this message translates to:
  /// **'Show amounts in big blinds'**
  String get showBigBlinds;

  /// No description provided for @yourTurnBanner.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get yourTurnBanner;

  /// No description provided for @yourTurnBannerTime.
  ///
  /// In en, this message translates to:
  /// **'Your turn · {seconds} s'**
  String yourTurnBannerTime(int seconds);

  /// No description provided for @blindsUpIn.
  ///
  /// In en, this message translates to:
  /// **'blinds up in {time}'**
  String blindsUpIn(String time);

  /// No description provided for @adminBlindsUp.
  ///
  /// In en, this message translates to:
  /// **'Blinds up now'**
  String get adminBlindsUp;

  /// No description provided for @adminBlindsRaised.
  ///
  /// In en, this message translates to:
  /// **'Blinds raised to {blinds}'**
  String adminBlindsRaised(String blinds);

  /// No description provided for @joinSeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get joinSeatLabel;

  /// No description provided for @joinSeatAny.
  ///
  /// In en, this message translates to:
  /// **'Any free seat'**
  String get joinSeatAny;

  /// No description provided for @joinAvatarLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get joinAvatarLabel;

  /// No description provided for @errSeatTaken.
  ///
  /// In en, this message translates to:
  /// **'That seat was just taken. Pick another one.'**
  String get errSeatTaken;

  /// No description provided for @replayTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay a hand'**
  String get replayTitle;

  /// No description provided for @replayOpen.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get replayOpen;

  /// No description provided for @replayNoHands.
  ///
  /// In en, this message translates to:
  /// **'No hands played yet'**
  String get replayNoHands;

  /// No description provided for @replayLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the hands: {message}'**
  String replayLoadFailed(String message);

  /// No description provided for @replayStart.
  ///
  /// In en, this message translates to:
  /// **'Before the deal'**
  String get replayStart;

  /// No description provided for @replayPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get replayPlay;

  /// No description provided for @replayPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get replayPause;

  /// No description provided for @replayPrev.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get replayPrev;

  /// No description provided for @replayNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get replayNext;

  /// No description provided for @replayStep.
  ///
  /// In en, this message translates to:
  /// **'{step} / {total}'**
  String replayStep(int step, int total);

  /// No description provided for @replayBackToList.
  ///
  /// In en, this message translates to:
  /// **'All hands'**
  String get replayBackToList;

  /// No description provided for @replayReveals.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One player shows their cards} other{{count} players show their cards}}'**
  String replayReveals(int count);

  /// No description provided for @replayPrevHand.
  ///
  /// In en, this message translates to:
  /// **'Previous hand'**
  String get replayPrevHand;

  /// No description provided for @replayNextHand.
  ///
  /// In en, this message translates to:
  /// **'Next hand'**
  String get replayNextHand;

  /// No description provided for @logDeadBlind.
  ///
  /// In en, this message translates to:
  /// **'{name} posts a dead big blind {amount} (seat change)'**
  String logDeadBlind(String name, String amount);

  /// No description provided for @logPlayerMoved.
  ///
  /// In en, this message translates to:
  /// **'{name} moves to seat {seat}'**
  String logPlayerMoved(String name, int seat);

  /// No description provided for @takeSeatHint.
  ///
  /// In en, this message translates to:
  /// **'Move here at the next deal'**
  String get takeSeatHint;

  /// No description provided for @seatPendingYou.
  ///
  /// In en, this message translates to:
  /// **'You, next hand'**
  String get seatPendingYou;

  /// No description provided for @changeSeatTitle.
  ///
  /// In en, this message translates to:
  /// **'Move to seat {seat}?'**
  String changeSeatTitle(int seat);

  /// No description provided for @changeSeatBody.
  ///
  /// In en, this message translates to:
  /// **'You move at the next deal. Changing seats costs a dead big blind of {amount} in your next hand (this keeps seat changes from dodging the blinds), and you can move again after three hands.'**
  String changeSeatBody(String amount);

  /// No description provided for @changeSeatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get changeSeatConfirm;

  /// No description provided for @menuMore.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuMore;

  /// No description provided for @takeSeat.
  ///
  /// In en, this message translates to:
  /// **'Take a seat'**
  String get takeSeat;

  /// No description provided for @panelClose.
  ///
  /// In en, this message translates to:
  /// **'Close panel'**
  String get panelClose;

  /// No description provided for @otherTable.
  ///
  /// In en, this message translates to:
  /// **'Other table'**
  String get otherTable;

  /// No description provided for @voiceJoin.
  ///
  /// In en, this message translates to:
  /// **'Join the voice chat'**
  String get voiceJoin;

  /// No description provided for @voiceJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Browser-to-browser audio; the server never hears it. Needs a microphone and HTTPS (or localhost).'**
  String get voiceJoinHint;

  /// No description provided for @voiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice chat'**
  String get voiceTitle;

  /// No description provided for @voiceOn.
  ///
  /// In en, this message translates to:
  /// **'Voice chat on'**
  String get voiceOn;

  /// No description provided for @voiceOff.
  ///
  /// In en, this message translates to:
  /// **'Voice chat off'**
  String get voiceOff;

  /// No description provided for @voiceMute.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get voiceMute;

  /// No description provided for @voiceUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get voiceUnmute;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice chat is not available here: the browser only grants the microphone on HTTPS or localhost.'**
  String get voiceUnavailable;

  /// No description provided for @voiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'speaking'**
  String get voiceSpeaking;

  /// No description provided for @menuPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get menuPreferences;

  /// No description provided for @menuTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get menuTable;

  /// No description provided for @settingsTableRules.
  ///
  /// In en, this message translates to:
  /// **'Table rules'**
  String get settingsTableRules;

  /// No description provided for @settingsTableRulesHint.
  ///
  /// In en, this message translates to:
  /// **'Blinds, times, rebuys, game variant'**
  String get settingsTableRulesHint;

  /// No description provided for @settingsVoiceVideo.
  ///
  /// In en, this message translates to:
  /// **'Voice & video'**
  String get settingsVoiceVideo;

  /// No description provided for @settingsVoiceVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Microphone, camera, network check'**
  String get settingsVoiceVideoHint;

  /// No description provided for @settingsPreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Sound, deck, chips, seats, display size, language, theme'**
  String get settingsPreferencesHint;

  /// No description provided for @settingsTableHint.
  ///
  /// In en, this message translates to:
  /// **'Your hat, the table rules, another table, leave'**
  String get settingsTableHint;

  /// No description provided for @hostControls.
  ///
  /// In en, this message translates to:
  /// **'Game controls'**
  String get hostControls;

  /// No description provided for @hostControlsHint.
  ///
  /// In en, this message translates to:
  /// **'Start, pause, end, blinds up, admin key'**
  String get hostControlsHint;

  /// No description provided for @hostPlayersHint.
  ///
  /// In en, this message translates to:
  /// **'Chips, mute, kick'**
  String get hostPlayersHint;

  /// No description provided for @hostChat.
  ///
  /// In en, this message translates to:
  /// **'Chat moderation'**
  String get hostChat;

  /// No description provided for @hostChatHint.
  ///
  /// In en, this message translates to:
  /// **'Remove messages'**
  String get hostChatHint;

  /// No description provided for @hostHandsHint.
  ///
  /// In en, this message translates to:
  /// **'Recent hands and replay'**
  String get hostHandsHint;

  /// No description provided for @turnOf.
  ///
  /// In en, this message translates to:
  /// **'{name} to act · {seconds} s'**
  String turnOf(String name, int seconds);

  /// No description provided for @showdownStrip.
  ///
  /// In en, this message translates to:
  /// **'Showdown · {seconds} s'**
  String showdownStrip(int seconds);

  /// No description provided for @nextHandIn.
  ///
  /// In en, this message translates to:
  /// **'Next hand in {seconds} s'**
  String nextHandIn(int seconds);

  /// No description provided for @adminUnsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes.'**
  String get adminUnsavedChanges;

  /// No description provided for @adminDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get adminDiscard;

  /// No description provided for @voiceMicOn.
  ///
  /// In en, this message translates to:
  /// **'Microphone on'**
  String get voiceMicOn;

  /// No description provided for @voiceMicMuted.
  ///
  /// In en, this message translates to:
  /// **'Microphone muted'**
  String get voiceMicMuted;

  /// No description provided for @joinAvatarChange.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get joinAvatarChange;

  /// No description provided for @hatTitle.
  ///
  /// In en, this message translates to:
  /// **'Hat'**
  String get hatTitle;

  /// No description provided for @hatChange.
  ///
  /// In en, this message translates to:
  /// **'Change hat'**
  String get hatChange;

  /// No description provided for @lookTitle.
  ///
  /// In en, this message translates to:
  /// **'Avatar & hat'**
  String get lookTitle;

  /// No description provided for @selfMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get selfMenuTitle;

  /// No description provided for @hatNone.
  ///
  /// In en, this message translates to:
  /// **'No hat'**
  String get hatNone;

  /// No description provided for @showHats.
  ///
  /// In en, this message translates to:
  /// **'Show other players\' hats'**
  String get showHats;

  /// No description provided for @showHeat.
  ///
  /// In en, this message translates to:
  /// **'Show win streaks'**
  String get showHeat;

  /// No description provided for @playerMenuLocal.
  ///
  /// In en, this message translates to:
  /// **'Only for you'**
  String get playerMenuLocal;

  /// No description provided for @playerMenuLocalHint.
  ///
  /// In en, this message translates to:
  /// **'These settings apply on this device only and are forgotten when you leave the table. The player does not notice.'**
  String get playerMenuLocalHint;

  /// No description provided for @playerMenuEveryone.
  ///
  /// In en, this message translates to:
  /// **'For everyone (host)'**
  String get playerMenuEveryone;

  /// No description provided for @hostMuteAll.
  ///
  /// In en, this message translates to:
  /// **'Mute chat, stickers and drawings'**
  String get hostMuteAll;

  /// No description provided for @hostMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get hostMic;

  /// No description provided for @hostCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get hostCamera;

  /// No description provided for @hostOnlyPlayerUnmutes.
  ///
  /// In en, this message translates to:
  /// **'The host can only switch this off; the player turns it on again'**
  String get hostOnlyPlayerUnmutes;

  /// No description provided for @peerVolume.
  ///
  /// In en, this message translates to:
  /// **'Voice volume'**
  String get peerVolume;

  /// No description provided for @peerMute.
  ///
  /// In en, this message translates to:
  /// **'Mute voice'**
  String get peerMute;

  /// No description provided for @peerHideVideo.
  ///
  /// In en, this message translates to:
  /// **'Hide video'**
  String get peerHideVideo;

  /// No description provided for @peerHideHat.
  ///
  /// In en, this message translates to:
  /// **'Hide hat'**
  String get peerHideHat;

  /// No description provided for @peerHideHeat.
  ///
  /// In en, this message translates to:
  /// **'Hide win streak'**
  String get peerHideHeat;

  /// No description provided for @peerHideStickers.
  ///
  /// In en, this message translates to:
  /// **'Hide stickers'**
  String get peerHideStickers;

  /// No description provided for @sayPhrases.
  ///
  /// In en, this message translates to:
  /// **'Phrases'**
  String get sayPhrases;

  /// No description provided for @sayStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get sayStickers;

  /// No description provided for @landingStickers.
  ///
  /// In en, this message translates to:
  /// **'Stickers: Noto Emoji (CC BY 4.0)'**
  String get landingStickers;

  /// No description provided for @peerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get peerReset;

  /// No description provided for @peerMutedMark.
  ///
  /// In en, this message translates to:
  /// **'Muted for you'**
  String get peerMutedMark;

  /// No description provided for @peerQuietMark.
  ///
  /// In en, this message translates to:
  /// **'Turned down for you'**
  String get peerQuietMark;

  /// No description provided for @peerNoVideoMark.
  ///
  /// In en, this message translates to:
  /// **'Video hidden for you'**
  String get peerNoVideoMark;

  /// No description provided for @heatBadge.
  ///
  /// In en, this message translates to:
  /// **'{heat, select, 1{Warming up: 2 hands in a row} 2{Running hot: 3 hands in a row} 3{On fire: 4 or more hands in a row} other{Running hot}}'**
  String heatBadge(String heat);

  /// No description provided for @hatName.
  ///
  /// In en, this message translates to:
  /// **'{hat, select, top_hat{Top hat} cowboy{Cowboy hat} crown{Crown} party{Party hat} beanie{Beanie} wizard{Wizard hat} chef{Chef\'s hat} pirate{Pirate hat} cap{Baseball cap} halo{Halo} viking{Viking helmet} sombrero{Sombrero} fedora{Fedora} bowler{Bowler hat} santa{Santa hat} tiara{Tiara} propeller{Propeller beanie} bunny_ears{Bunny ears} flower_crown{Flower crown} headband{Headband} other{Hat}}'**
  String hatName(String hat);

  /// No description provided for @joinPickSeat.
  ///
  /// In en, this message translates to:
  /// **'Pick a seat (optional)'**
  String get joinPickSeat;

  /// No description provided for @joinPickSeatHide.
  ///
  /// In en, this message translates to:
  /// **'Hide seats'**
  String get joinPickSeatHide;

  /// No description provided for @displaySize.
  ///
  /// In en, this message translates to:
  /// **'Display size'**
  String get displaySize;

  /// No description provided for @displaySizeHint.
  ///
  /// In en, this message translates to:
  /// **'Larger cards, chips, buttons and text.'**
  String get displaySizeHint;

  /// No description provided for @displayNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get displayNormal;

  /// No description provided for @displayLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get displayLarge;

  /// No description provided for @displayExtraLarge.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get displayExtraLarge;

  /// No description provided for @handLine.
  ///
  /// In en, this message translates to:
  /// **'Your hand line'**
  String get handLine;

  /// No description provided for @handLineOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get handLineOff;

  /// No description provided for @handLineBoard.
  ///
  /// In en, this message translates to:
  /// **'On the table'**
  String get handLineBoard;

  /// No description provided for @handLineBottom.
  ///
  /// In en, this message translates to:
  /// **'Below the table'**
  String get handLineBottom;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite players'**
  String get inviteTitle;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'Share this link or let them scan the code. The link was copied to your clipboard.'**
  String get inviteHint;

  /// No description provided for @invitePlayers.
  ///
  /// In en, this message translates to:
  /// **'Players ({count})'**
  String invitePlayers(int count);

  /// No description provided for @inviteSpectators.
  ///
  /// In en, this message translates to:
  /// **'Spectators ({count})'**
  String inviteSpectators(int count);

  /// No description provided for @inviteNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get inviteNobody;

  /// No description provided for @winnerBadge.
  ///
  /// In en, this message translates to:
  /// **'Winner'**
  String get winnerBadge;

  /// No description provided for @winsLine.
  ///
  /// In en, this message translates to:
  /// **'{name} wins {amount}'**
  String winsLine(String name, String amount);

  /// No description provided for @winsLineWith.
  ///
  /// In en, this message translates to:
  /// **'{name} wins {amount} with {description}'**
  String winsLineWith(String name, String amount, String description);

  /// No description provided for @revealInOrder.
  ///
  /// In en, this message translates to:
  /// **'In order (beaten hands muck)'**
  String get revealInOrder;

  /// No description provided for @badgeMucked.
  ///
  /// In en, this message translates to:
  /// **'Mucked'**
  String get badgeMucked;

  /// No description provided for @logMucks.
  ///
  /// In en, this message translates to:
  /// **'{name} mucks'**
  String logMucks(String name);

  /// No description provided for @micTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get micTitle;

  /// No description provided for @micHint.
  ///
  /// In en, this message translates to:
  /// **'Voice chat runs browser to browser. Your microphone is only sent to the other players at this table.'**
  String get micHint;

  /// No description provided for @micStateOff.
  ///
  /// In en, this message translates to:
  /// **'Voice chat off'**
  String get micStateOff;

  /// No description provided for @micStateOn.
  ///
  /// In en, this message translates to:
  /// **'Microphone on'**
  String get micStateOn;

  /// No description provided for @micStateMuted.
  ///
  /// In en, this message translates to:
  /// **'Microphone muted'**
  String get micStateMuted;

  /// No description provided for @voiceMutedByHost.
  ///
  /// In en, this message translates to:
  /// **'The host muted your microphone. You can unmute yourself.'**
  String get voiceMutedByHost;

  /// No description provided for @adminMuteVoice.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get adminMuteVoice;

  /// No description provided for @adminMutedVoice.
  ///
  /// In en, this message translates to:
  /// **'Microphone muted'**
  String get adminMutedVoice;

  /// No description provided for @adminPlayerActions.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String adminPlayerActions(String name);

  /// No description provided for @adminMuteChat.
  ///
  /// In en, this message translates to:
  /// **'Mute chat'**
  String get adminMuteChat;

  /// No description provided for @adminUnmuteChat.
  ///
  /// In en, this message translates to:
  /// **'Unmute chat'**
  String get adminUnmuteChat;

  /// No description provided for @sayTitle.
  ///
  /// In en, this message translates to:
  /// **'Say something'**
  String get sayTitle;

  /// No description provided for @sayButton.
  ///
  /// In en, this message translates to:
  /// **'Quick phrase'**
  String get sayButton;

  /// No description provided for @phraseNiceHand.
  ///
  /// In en, this message translates to:
  /// **'Nice hand'**
  String get phraseNiceHand;

  /// No description provided for @phraseNiceCall.
  ///
  /// In en, this message translates to:
  /// **'Nice call'**
  String get phraseNiceCall;

  /// No description provided for @phraseNiceFold.
  ///
  /// In en, this message translates to:
  /// **'Nice fold'**
  String get phraseNiceFold;

  /// No description provided for @phraseNiceBluff.
  ///
  /// In en, this message translates to:
  /// **'Nice bluff'**
  String get phraseNiceBluff;

  /// No description provided for @phraseWellPlayed.
  ///
  /// In en, this message translates to:
  /// **'Well played'**
  String get phraseWellPlayed;

  /// No description provided for @phraseGg.
  ///
  /// In en, this message translates to:
  /// **'GG'**
  String get phraseGg;

  /// No description provided for @phraseThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get phraseThanks;

  /// No description provided for @phraseSorry.
  ///
  /// In en, this message translates to:
  /// **'Sorry'**
  String get phraseSorry;

  /// No description provided for @phraseWow.
  ///
  /// In en, this message translates to:
  /// **'Wow'**
  String get phraseWow;

  /// No description provided for @phraseOops.
  ///
  /// In en, this message translates to:
  /// **'Oops'**
  String get phraseOops;

  /// No description provided for @phraseFurious.
  ///
  /// In en, this message translates to:
  /// **'I\'m furious'**
  String get phraseFurious;

  /// No description provided for @phraseLol.
  ///
  /// In en, this message translates to:
  /// **'LOL'**
  String get phraseLol;

  /// No description provided for @phraseHurryUp.
  ///
  /// In en, this message translates to:
  /// **'Hurry up'**
  String get phraseHurryUp;

  /// No description provided for @phraseBrb.
  ///
  /// In en, this message translates to:
  /// **'Be right back'**
  String get phraseBrb;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @setTimeBank.
  ///
  /// In en, this message translates to:
  /// **'Time bank (seconds, 0 = off)'**
  String get setTimeBank;

  /// No description provided for @errTimeBank.
  ///
  /// In en, this message translates to:
  /// **'0 to 120 seconds'**
  String get errTimeBank;

  /// No description provided for @setTimeBankRefill.
  ///
  /// In en, this message translates to:
  /// **'Time bank refill per hand (seconds)'**
  String get setTimeBankRefill;

  /// No description provided for @errTimeBankRefill.
  ///
  /// In en, this message translates to:
  /// **'0 to 30 seconds'**
  String get errTimeBankRefill;

  /// No description provided for @setAllowStraddle.
  ///
  /// In en, this message translates to:
  /// **'Allow straddle'**
  String get setAllowStraddle;

  /// No description provided for @setRunItTwice.
  ///
  /// In en, this message translates to:
  /// **'Offer run it twice'**
  String get setRunItTwice;

  /// No description provided for @logStraddle.
  ///
  /// In en, this message translates to:
  /// **'{name} posts a straddle {amount}'**
  String logStraddle(String name, String amount);

  /// No description provided for @logBoard2.
  ///
  /// In en, this message translates to:
  /// **'Board 2 · {street}: {cards}'**
  String logBoard2(String street, String cards);

  /// No description provided for @boardLabel.
  ///
  /// In en, this message translates to:
  /// **'Board {n}'**
  String boardLabel(int n);

  /// No description provided for @badgeStraddle.
  ///
  /// In en, this message translates to:
  /// **'STR'**
  String get badgeStraddle;

  /// No description provided for @timeBankStrip.
  ///
  /// In en, this message translates to:
  /// **'Time bank · {seconds} s'**
  String timeBankStrip(int seconds);

  /// No description provided for @timeBankLeft.
  ///
  /// In en, this message translates to:
  /// **'Time bank {seconds} s'**
  String timeBankLeft(int seconds);

  /// No description provided for @straddleToggle.
  ///
  /// In en, this message translates to:
  /// **'Straddle'**
  String get straddleToggle;

  /// No description provided for @straddleHint.
  ///
  /// In en, this message translates to:
  /// **'Post twice the big blind before the deal when you sit left of the big blind.'**
  String get straddleHint;

  /// No description provided for @runTwiceQuestion.
  ///
  /// In en, this message translates to:
  /// **'Run it twice?'**
  String get runTwiceQuestion;

  /// No description provided for @runTwiceYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, twice'**
  String get runTwiceYes;

  /// No description provided for @runTwiceNo.
  ///
  /// In en, this message translates to:
  /// **'No, once'**
  String get runTwiceNo;

  /// No description provided for @runTwiceWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the others…'**
  String get runTwiceWaiting;

  /// No description provided for @runTwiceDeclined.
  ///
  /// In en, this message translates to:
  /// **'Running it once'**
  String get runTwiceDeclined;

  /// No description provided for @lbHandsPlayed.
  ///
  /// In en, this message translates to:
  /// **'Hands played'**
  String get lbHandsPlayed;

  /// No description provided for @lbVpip.
  ///
  /// In en, this message translates to:
  /// **'Voluntarily in the pot'**
  String get lbVpip;

  /// No description provided for @lbShowdowns.
  ///
  /// In en, this message translates to:
  /// **'Showdowns won / seen'**
  String get lbShowdowns;

  /// No description provided for @placeLabel.
  ///
  /// In en, this message translates to:
  /// **'{place}.'**
  String placeLabel(int place);

  /// No description provided for @outBadge.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outBadge;

  /// No description provided for @logExportText.
  ///
  /// In en, this message translates to:
  /// **'Export text'**
  String get logExportText;

  /// No description provided for @logExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get logExportJson;

  /// No description provided for @logExported.
  ///
  /// In en, this message translates to:
  /// **'History exported'**
  String get logExported;

  /// No description provided for @notifyTurn.
  ///
  /// In en, this message translates to:
  /// **'Notify me when it\'s my turn'**
  String get notifyTurn;

  /// No description provided for @notifyTurnHint.
  ///
  /// In en, this message translates to:
  /// **'A system notification (and a vibration on phones) when the tab is in the background.'**
  String get notifyTurnHint;

  /// No description provided for @notifyDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked in this browser.'**
  String get notifyDenied;

  /// No description provided for @notifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get notifyTitle;

  /// No description provided for @notifyBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s your turn at {table}'**
  String notifyBody(String table);

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraTitle;

  /// No description provided for @cameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get cameraOn;

  /// No description provided for @cameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get cameraOff;

  /// No description provided for @cameraHint.
  ///
  /// In en, this message translates to:
  /// **'A small video next to your avatar, sent browser to browser like the voice. Works best with up to six players.'**
  String get cameraHint;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The browser did not grant the camera.'**
  String get cameraUnavailable;

  /// No description provided for @cameraOffByHost.
  ///
  /// In en, this message translates to:
  /// **'The host turned your camera off. You can turn it on again.'**
  String get cameraOffByHost;

  /// No description provided for @adminCameraOff.
  ///
  /// In en, this message translates to:
  /// **'Turn camera off'**
  String get adminCameraOff;

  /// No description provided for @adminCameraOffDone.
  ///
  /// In en, this message translates to:
  /// **'Camera turned off'**
  String get adminCameraOffDone;

  /// No description provided for @cameraJoinHint.
  ///
  /// In en, this message translates to:
  /// **'Adds a small camera tile next to your avatar (turns the voice chat on as well). The browser asks for the camera once.'**
  String get cameraJoinHint;

  /// No description provided for @showCameras.
  ///
  /// In en, this message translates to:
  /// **'Show other players\' cameras'**
  String get showCameras;

  /// No description provided for @showCamerasHint.
  ///
  /// In en, this message translates to:
  /// **'Off saves bandwidth: the others stop sending you video. Your own camera is unaffected.'**
  String get showCamerasHint;

  /// No description provided for @scFocusAmount.
  ///
  /// In en, this message translates to:
  /// **'Type the raise amount (Esc leaves the field)'**
  String get scFocusAmount;

  /// No description provided for @showdownSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Showdown spotlight'**
  String get showdownSpotlight;

  /// No description provided for @spotlightSplit.
  ///
  /// In en, this message translates to:
  /// **'Split pot – {names}: {description}'**
  String spotlightSplit(String names, String description);
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
