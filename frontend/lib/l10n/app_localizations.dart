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
  /// **'Toggle panel'**
  String get panelToggle;

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

  /// No description provided for @scPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets Min / 1/2 Pot / 3/4 Pot / Pot'**
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
  /// **'Admin'**
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
