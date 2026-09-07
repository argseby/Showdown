// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Showdown';

  @override
  String get landingTagline => 'Texas Hold\'em for your private group.';

  @override
  String get landingCodeLabel => 'Table link or code';

  @override
  String get landingCodePlaceholder =>
      'https://example.com/t/k7m2p9xq4w or k7m2p9xq4w';

  @override
  String get landingJoin => 'Open table';

  @override
  String get landingInvalidCode =>
      'That doesn\'t look like a table link or code.';

  @override
  String landingServerVersion(String version) {
    return 'Server $version';
  }

  @override
  String get landingSource => 'Source on GitHub';

  @override
  String landingCreatedBy(String author) {
    return 'Created by $author';
  }

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundBody => 'There is nothing at this address.';

  @override
  String get notFoundHome => 'Back to start';

  @override
  String get themeToggle => 'Toggle light/dark theme';

  @override
  String get languageToggle => 'Switch language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'German';

  @override
  String get joinTitle => 'Join table';

  @override
  String joinSeats(int seated, int max) {
    return '$seated of $max seats taken';
  }

  @override
  String get joinStateWaiting => 'Waiting for players';

  @override
  String get joinStateRunning => 'Running';

  @override
  String get joinStatePaused => 'Paused';

  @override
  String get joinStateEnded => 'Ended';

  @override
  String joinBlinds(String small, String big) {
    return 'Blinds $small/$big';
  }

  @override
  String get joinNameLabel => 'Your name';

  @override
  String get joinNamePlaceholder => '1-20 characters';

  @override
  String get joinPasswordLabel => 'Table password';

  @override
  String get joinButton => 'Join';

  @override
  String get spectateButton => 'Spectate';

  @override
  String get joinNameInvalid => 'Use 1-20 letters, digits, spaces, _ - .';

  @override
  String get joinPasswordRequired => 'Please enter the table password.';

  @override
  String get joinLoadFailed => 'Could not load this table.';

  @override
  String get joinTableEnded => 'This table has ended.';

  @override
  String get joinClosed => 'Joining is closed for this table.';

  @override
  String get joinSpectatorsOff => 'Spectators are not allowed at this table.';

  @override
  String get tableNotFound => 'Table not found';

  @override
  String get retry => 'Retry';

  @override
  String get errWrongPassword => 'Wrong password';

  @override
  String get errNameTaken => 'That name is already taken';

  @override
  String get errTableFull => 'The table is full';

  @override
  String get errJoinsClosed => 'Joining is closed';

  @override
  String get errTableEnded => 'The table has ended';

  @override
  String get errInvalidName => 'Invalid name';

  @override
  String get errSpectatorsDisabled => 'Spectators are not allowed';

  @override
  String get errRateLimited => 'Too many requests, please try again shortly';

  @override
  String errGeneric(String message) {
    return 'Something went wrong: $message';
  }

  @override
  String get errNotYourTurn => 'It is not your turn';

  @override
  String get errIllegalAction => 'That action is not allowed right now';

  @override
  String get errAmountOutOfRange => 'Amount out of range';

  @override
  String handNumber(int number) {
    return 'Hand #$number';
  }

  @override
  String blindsShort(String small, String big) {
    return 'Blinds $small/$big';
  }

  @override
  String get connConnected => 'Connected';

  @override
  String get connConnecting => 'Connecting...';

  @override
  String connReconnecting(int attempt) {
    return 'Reconnecting... (attempt $attempt)';
  }

  @override
  String get connDisconnected => 'Disconnected';

  @override
  String get replacedTitle => 'Connected elsewhere';

  @override
  String get replacedBody => 'This seat is now used by another connection.';

  @override
  String get reconnectHere => 'Reconnect here';

  @override
  String get kickedTitle => 'Removed from the table';

  @override
  String get kickedBody => 'The admin removed you from this table.';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sessionExpiredBody =>
      'Your session is no longer valid. Please join again.';

  @override
  String get tableEndedTitle => 'Table ended';

  @override
  String get finalStandings => 'Final standings';

  @override
  String get backToJoin => 'Back to the table page';

  @override
  String get serverRestarting =>
      'The server is restarting, reconnecting shortly...';

  @override
  String get leave => 'Leave';

  @override
  String get leaveConfirmTitle => 'Leave the table?';

  @override
  String get leaveConfirmBody =>
      'Your seat will be freed. If a hand is running you fold.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get close => 'Close';

  @override
  String get fold => 'Fold';

  @override
  String get check => 'Check';

  @override
  String call(String amount) {
    return 'Call $amount';
  }

  @override
  String get bet => 'Bet';

  @override
  String get raise => 'Raise';

  @override
  String get allIn => 'All-in';

  @override
  String raiseTo(String amount) {
    return 'Raise to $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Bet $amount';
  }

  @override
  String get presetMin => 'Min';

  @override
  String get presetHalfPot => '1/2 Pot';

  @override
  String get presetThreeQuarterPot => '3/4 Pot';

  @override
  String get presetPot => 'Pot';

  @override
  String get presetAllIn => 'All-in';

  @override
  String amountRange(String min, String max) {
    return 'Allowed: $min - $max';
  }

  @override
  String amountClamped(String amount) {
    return 'Amount adjusted to $amount';
  }

  @override
  String rebuy(String amount) {
    return 'Rebuy $amount';
  }

  @override
  String get sitOut => 'Sit out';

  @override
  String get sitIn => 'I\'m back';

  @override
  String get showCards => 'Show cards';

  @override
  String get waitingForPlayers => 'Waiting for players...';

  @override
  String get tablePaused => 'Table paused';

  @override
  String get tableWaiting => 'The table has not started yet';

  @override
  String get yourTurn => 'Your turn';

  @override
  String get badgeDealer => 'D';

  @override
  String get badgeSmallBlind => 'SB';

  @override
  String get badgeBigBlind => 'BB';

  @override
  String get badgeSittingOut => 'Sitting out';

  @override
  String get badgeDisconnected => 'Offline';

  @override
  String get badgeAllIn => 'All-in';

  @override
  String get badgeBusted => 'Busted';

  @override
  String get badgeWaiting => 'Next hand';

  @override
  String get badgeFolded => 'Folded';

  @override
  String get badgeNoAudio => 'No audio';

  @override
  String get mainPot => 'Main pot';

  @override
  String sidePot(int n) {
    return 'Side pot $n';
  }

  @override
  String potTotal(String amount) {
    return 'Pot $amount';
  }

  @override
  String get tabChat => 'Chat';

  @override
  String get tabLog => 'Log';

  @override
  String get tabLeaderboard => 'Leaderboard';

  @override
  String get panelToggle => 'Toggle panel';

  @override
  String get chatPlaceholder => 'Message...';

  @override
  String get chatDisabled => 'Chat is disabled';

  @override
  String get chatMuted => 'You are muted';

  @override
  String get chatSpectatorsOff => 'Spectator chat is off';

  @override
  String get chatSend => 'Send';

  @override
  String get chatAdmin => 'Admin';

  @override
  String get logCopy => 'Copy log';

  @override
  String get logCopied => 'Log copied';

  @override
  String get logEmpty => 'No events yet';

  @override
  String get lbName => 'Name';

  @override
  String get lbStack => 'Stack';

  @override
  String get lbNet => 'Net';

  @override
  String get lbHandsWon => 'Won';

  @override
  String get lbBiggestPot => 'Biggest pot';

  @override
  String get shortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutsHint =>
      'Shortcuts are inactive while typing. Esc leaves the text field.';

  @override
  String get scFold => 'Fold';

  @override
  String get scCheckCall => 'Check / Call';

  @override
  String get scOpenRaise => 'Open the raise control';

  @override
  String get scAllIn => 'Select all-in (Enter confirms)';

  @override
  String get scPresets => 'Presets Min / 1/2 Pot / 3/4 Pot / Pot';

  @override
  String get scAmount => '+/- one big blind (Shift: +/- five)';

  @override
  String get scConfirm => 'Confirm bet / raise';

  @override
  String get scCancel => 'Cancel raise / close overlay / leave text field';

  @override
  String get scChat => 'Focus chat';

  @override
  String get scLog => 'Toggle log';

  @override
  String get scLeaderboard => 'Toggle leaderboard';

  @override
  String get scSound => 'Toggle sound';

  @override
  String get scHelp => 'This overlay';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String spectatorsCount(int count) {
    return '$count watching';
  }

  @override
  String get roleSpectator => 'Spectating';

  @override
  String get roleAdmin => 'Admin view';

  @override
  String get yourTurnTitle => '▶ Your turn — Showdown';

  @override
  String seatLabel(int seat) {
    return 'Seat $seat';
  }

  @override
  String get emptySeat => 'Empty';

  @override
  String get you => 'You';

  @override
  String logHandStarted(int number, String name) {
    return 'Hand #$number starts. Dealer: $name';
  }

  @override
  String logAnte(String name, String amount) {
    return '$name posts ante $amount';
  }

  @override
  String logSmallBlind(String name, String amount) {
    return '$name posts small blind $amount';
  }

  @override
  String logBigBlind(String name, String amount) {
    return '$name posts big blind $amount';
  }

  @override
  String logDealt(String cards) {
    return 'You are dealt $cards';
  }

  @override
  String logFold(String name) {
    return '$name folds';
  }

  @override
  String logCheck(String name) {
    return '$name checks';
  }

  @override
  String logCall(String name, String amount) {
    return '$name calls $amount';
  }

  @override
  String logBet(String name, String amount) {
    return '$name bets $amount';
  }

  @override
  String logRaise(String name, String amount) {
    return '$name raises to $amount';
  }

  @override
  String get logAllInSuffix => ' (all-in)';

  @override
  String logTimeoutCheck(String name) {
    return '$name times out and checks';
  }

  @override
  String logTimeoutFold(String name) {
    return '$name times out and folds';
  }

  @override
  String logUncalled(String amount, String name) {
    return 'Uncalled bet of $amount returned to $name';
  }

  @override
  String logFlop(String cards) {
    return 'Flop: $cards';
  }

  @override
  String logTurn(String cards) {
    return 'Turn: $cards';
  }

  @override
  String logRiver(String cards) {
    return 'River: $cards';
  }

  @override
  String logReveal(String name, String cards, String description) {
    return '$name shows $cards - $description';
  }

  @override
  String logRevealNoDesc(String name, String cards) {
    return '$name shows $cards';
  }

  @override
  String logWin(String name, String amount, String pot, String description) {
    return '$name wins $amount ($pot) with $description';
  }

  @override
  String logWinUncontested(String name, String amount, String pot) {
    return '$name wins $amount ($pot)';
  }

  @override
  String logVoided(String reason) {
    return 'Hand voided ($reason)';
  }

  @override
  String logJoined(String name, int seat) {
    return '$name joined (seat $seat)';
  }

  @override
  String logLeft(String name) {
    return '$name left';
  }

  @override
  String logKicked(String name) {
    return '$name was removed';
  }

  @override
  String logSatOut(String name) {
    return '$name sits out';
  }

  @override
  String logSatIn(String name) {
    return '$name is back';
  }

  @override
  String logBusted(String name) {
    return '$name is out of chips';
  }

  @override
  String logRebought(String name, String amount) {
    return '$name rebought $amount';
  }

  @override
  String logChips(String name, String delta) {
    return 'Admin adjusted chips of $name by $delta';
  }

  @override
  String logSettings(String fields) {
    return 'Settings changed: $fields';
  }

  @override
  String get logStarted => 'Table started';

  @override
  String get logPaused => 'Table paused';

  @override
  String get logResumed => 'Table resumed';

  @override
  String get logEnded => 'Table ended';

  @override
  String get logRestarted => 'Server restarted';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminNewTable => 'New table';

  @override
  String get adminCreate => 'Create';

  @override
  String get adminSave => 'Save';

  @override
  String get adminSaved => 'Settings saved';

  @override
  String adminSavedNextHand(String fields) {
    return 'Saved. Applies from the next hand: $fields';
  }

  @override
  String get adminNoChanges => 'No changes';

  @override
  String get adminTableName => 'Table name';

  @override
  String get adminTableNameInvalid => '1-40 characters';

  @override
  String adminPlayersCount(int seated, int max) {
    return '$seated/$max players';
  }

  @override
  String get adminCopyLink => 'Copy link';

  @override
  String get adminLinkCopied => 'Link copied';

  @override
  String get adminQrCode => 'QR code';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminPlayers => 'Players';

  @override
  String get adminChat => 'Chat moderation';

  @override
  String get adminHands => 'Recent hands';

  @override
  String get adminNoHands => 'No hands yet';

  @override
  String adminHandRow(int number, String time) {
    return 'Hand #$number · $time';
  }

  @override
  String get adminHandVoided => 'voided';

  @override
  String get adminStart => 'Start';

  @override
  String get adminPause => 'Pause';

  @override
  String get adminResume => 'Resume';

  @override
  String get adminEnd => 'End';

  @override
  String get adminDelete => 'Delete table';

  @override
  String get adminEndTitle => 'End the table?';

  @override
  String get adminEndBody =>
      'Choose whether the running hand should finish first.';

  @override
  String get adminEndAfterHand => 'After this hand';

  @override
  String get adminEndNow => 'Now, void the hand';

  @override
  String get adminDeleteTitle => 'Delete this table?';

  @override
  String get adminDeleteBody =>
      'All hands, chat and standings of this table are removed.';

  @override
  String get adminDeleteRunning =>
      'A running table cannot be deleted. Pause or end it first.';

  @override
  String get adminKick => 'Kick';

  @override
  String adminKickTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get adminKickBody =>
      'The player folds now and the seat is freed after the hand.';

  @override
  String get adminChips => 'Chips';

  @override
  String adminChipsTitle(String name) {
    return 'Adjust chips of $name';
  }

  @override
  String get adminChipsAmount => 'Amount (negative to remove)';

  @override
  String get adminChipsNote => 'Note';

  @override
  String get adminChipsInvalid => 'Enter a non-zero whole number';

  @override
  String get adminChipsApplied => 'Chips adjusted';

  @override
  String get adminChipsQueued => 'Queued until the hand ends';

  @override
  String get adminMute => 'Mute';

  @override
  String get adminUnmute => 'Unmute';

  @override
  String get adminRemoveMessage => 'Remove message';

  @override
  String get adminNoChat => 'No chat messages';

  @override
  String adminStateChanged(String state) {
    return 'Table is now $state';
  }

  @override
  String get adminAppliesNextHand => 'applies from the next hand';

  @override
  String get adminAppliesImmediately => 'applies immediately';

  @override
  String get adminAppliesNextJoin => 'applies to the next join';

  @override
  String get adminAppliesFuture => 'applies to future joins and rebuys';

  @override
  String adminSpectatorsWatching(int count, int connections) {
    return '$count watching · $connections connections';
  }

  @override
  String get setPassword => 'Table password (empty = none)';

  @override
  String get setPasswordKeep => 'Leave empty to keep the current password';

  @override
  String get setPasswordClear => 'Remove password';

  @override
  String get setMaxPlayers => 'Max players';

  @override
  String get setStartMoney => 'Start money';

  @override
  String get setSmallBlind => 'Small blind';

  @override
  String get setBigBlind => 'Big blind';

  @override
  String get setAnte => 'Ante';

  @override
  String get setTurnTime => 'Turn time (s)';

  @override
  String get setDisconnectedTurnTime => 'Turn time when disconnected (s)';

  @override
  String get setSitOutAfter => 'Sit out after missed turns';

  @override
  String get setJoinPolicy => 'Join policy';

  @override
  String get joinPolicyAlways => 'Always';

  @override
  String get joinPolicyBeforeStart => 'Only before the start';

  @override
  String get joinPolicyClosed => 'Closed';

  @override
  String get setAllowSpectators => 'Allow spectators';

  @override
  String get setSpectatorChat => 'Spectators may chat';

  @override
  String get setChatEnabled => 'Chat enabled';

  @override
  String get setAllowRebuy => 'Allow rebuys';

  @override
  String get setShowdownReveal => 'Showdown reveal';

  @override
  String get revealAll => 'All hands';

  @override
  String get revealWinnersOnly => 'Winners only';

  @override
  String get setAutoStart => 'Start automatically';

  @override
  String get setHandDelay => 'Pause between hands (ms)';

  @override
  String valRange(String min, String max) {
    return 'Must be between $min and $max';
  }

  @override
  String valMin(String min) {
    return 'Must be at least $min';
  }

  @override
  String get valInteger => 'Must be a whole number';

  @override
  String get valBigBlind => 'Must be at least the small blind';

  @override
  String get valDisconnected => 'Must be between 3 and the turn time';

  @override
  String get valPassword => 'Must be empty or 4-64 characters';

  @override
  String get fourColorDeck => 'Four-color deck';

  @override
  String get landingCreateTitle => 'Host a game';

  @override
  String get landingCreateHint =>
      'Whoever creates a table hosts it: an Admin tab at the table lets you change settings, manage players and end the game. No account needed.';

  @override
  String get landingCreate => 'Create a table';

  @override
  String get tabAdmin => 'Admin';

  @override
  String get adminKey => 'Admin key';

  @override
  String get adminKeyHint =>
      'Keep this key. It lets you manage the table from another device or browser; anyone who has it can do the same.';

  @override
  String get adminKeyCopy => 'Copy key';

  @override
  String get adminKeyCopied => 'Key copied';

  @override
  String get adminKeyRejected => 'This admin key is not valid for this table.';

  @override
  String get adminDeleted => 'Table deleted';

  @override
  String get joinHostBadge => 'You host this table';

  @override
  String get joinHostEnter => 'I host this table: enter the admin key';

  @override
  String get joinHostUse => 'Use key';

  @override
  String get adminTabHands => 'Hands';

  @override
  String get setBlindsUpMinutes => 'Blinds up every (minutes, 0 = off)';

  @override
  String get setBlindsUpPercent => 'Blinds up by (%)';

  @override
  String get setAllowRabbitHunt => 'Allow rabbit hunting';

  @override
  String logRabbitHunt(String name, String cards) {
    return '$name rabbit hunts: $cards';
  }

  @override
  String logBlindsChanged(String small, String big) {
    return 'Blinds are now $small/$big';
  }

  @override
  String get foldCheckTitle => 'Check for free?';

  @override
  String get foldCheckBody =>
      'Nobody has bet. You can check and see the next card without paying anything.';

  @override
  String get foldCheckInstead => 'Check instead';

  @override
  String get foldAnyway => 'Fold anyway';

  @override
  String get showFirstCard => 'Show 1st';

  @override
  String get showSecondCard => 'Show 2nd';

  @override
  String get rabbitHunt => 'Rabbit hunt';

  @override
  String get preCheckFold => 'Check / Fold';

  @override
  String get preCallAny => 'Call any';

  @override
  String yourHand(String description) {
    return 'Your hand: $description';
  }

  @override
  String get sittingOutNotice => 'You are away and are not dealt in.';

  @override
  String get showCoins => 'Show amounts in chips';

  @override
  String get showBigBlinds => 'Show amounts in big blinds';

  @override
  String get yourTurnBanner => 'Your turn';

  @override
  String yourTurnBannerTime(int seconds) {
    return 'Your turn · $seconds s';
  }

  @override
  String blindsUpIn(String time) {
    return 'blinds up in $time';
  }

  @override
  String get adminBlindsUp => 'Blinds up now';

  @override
  String adminBlindsRaised(String blinds) {
    return 'Blinds raised to $blinds';
  }

  @override
  String get joinSeatLabel => 'Seat';

  @override
  String get joinSeatAny => 'Any free seat';

  @override
  String get joinAvatarLabel => 'Avatar';

  @override
  String get errSeatTaken => 'That seat was just taken. Pick another one.';

  @override
  String get replayTitle => 'Replay a hand';

  @override
  String get replayOpen => 'Replay';

  @override
  String get replayNoHands => 'No hands played yet';

  @override
  String replayLoadFailed(String message) {
    return 'Could not load the hands: $message';
  }

  @override
  String get replayStart => 'Before the deal';

  @override
  String get replayPlay => 'Play';

  @override
  String get replayPause => 'Pause';

  @override
  String get replayPrev => 'Back';

  @override
  String get replayNext => 'Next';

  @override
  String replayStep(int step, int total) {
    return '$step / $total';
  }

  @override
  String get replayBackToList => 'All hands';

  @override
  String replayReveals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players show their cards',
      one: 'One player shows their cards',
    );
    return '$_temp0';
  }

  @override
  String get replayPrevHand => 'Previous hand';

  @override
  String get replayNextHand => 'Next hand';

  @override
  String logDeadBlind(String name, String amount) {
    return '$name posts a dead big blind $amount (seat change)';
  }

  @override
  String logPlayerMoved(String name, int seat) {
    return '$name moves to seat $seat';
  }

  @override
  String get takeSeatHint => 'Move here at the next deal';

  @override
  String get seatPendingYou => 'You, next hand';

  @override
  String changeSeatTitle(int seat) {
    return 'Move to seat $seat?';
  }

  @override
  String changeSeatBody(String amount) {
    return 'You move at the next deal. Changing seats costs a dead big blind of $amount in your next hand (this keeps seat changes from dodging the blinds), and you can move again after three hands.';
  }

  @override
  String get changeSeatConfirm => 'Move';

  @override
  String get menuMore => 'Menu';

  @override
  String get takeSeat => 'Take a seat';

  @override
  String get panelClose => 'Close panel';

  @override
  String get otherTable => 'Other table';

  @override
  String get voiceJoin => 'Join the voice chat';

  @override
  String get voiceJoinHint =>
      'Browser-to-browser audio; the server never hears it. Needs a microphone and HTTPS (or localhost).';

  @override
  String get voiceTitle => 'Voice chat';

  @override
  String get voiceOn => 'Voice chat on';

  @override
  String get voiceOff => 'Voice chat off';

  @override
  String get voiceMute => 'Mute microphone';

  @override
  String get voiceUnmute => 'Unmute microphone';

  @override
  String get voiceUnavailable =>
      'Voice chat is not available here: the browser only grants the microphone on HTTPS or localhost.';

  @override
  String get voiceSpeaking => 'speaking';

  @override
  String get menuPreferences => 'Preferences';

  @override
  String get menuTable => 'Table';

  @override
  String turnOf(String name, int seconds) {
    return '$name to act · $seconds s';
  }

  @override
  String showdownStrip(int seconds) {
    return 'Showdown · $seconds s';
  }

  @override
  String nextHandIn(int seconds) {
    return 'Next hand in $seconds s';
  }

  @override
  String get adminUnsavedChanges => 'You have unsaved changes.';

  @override
  String get adminDiscard => 'Discard';

  @override
  String get voiceMicOn => 'Microphone on';

  @override
  String get voiceMicMuted => 'Microphone muted';

  @override
  String get joinAvatarChange => 'Change avatar';

  @override
  String get joinPickSeat => 'Pick a seat (optional)';

  @override
  String get joinPickSeatHide => 'Hide seats';

  @override
  String get displaySize => 'Display size';

  @override
  String get displaySizeHint => 'Larger cards, chips, buttons and text.';

  @override
  String get displayNormal => 'Normal';

  @override
  String get displayLarge => 'Large';

  @override
  String get displayExtraLarge => 'Extra large';

  @override
  String get handLine => 'Your hand line';

  @override
  String get handLineOff => 'Off';

  @override
  String get handLineBoard => 'On the table';

  @override
  String get handLineBottom => 'Below the table';

  @override
  String get invite => 'Invite';

  @override
  String get inviteTitle => 'Invite players';

  @override
  String get inviteHint =>
      'Share this link or let them scan the code. The link was copied to your clipboard.';

  @override
  String invitePlayers(int count) {
    return 'Players ($count)';
  }

  @override
  String inviteSpectators(int count) {
    return 'Spectators ($count)';
  }

  @override
  String get inviteNobody => 'Nobody yet';

  @override
  String get winnerBadge => 'Winner';

  @override
  String winsLine(String name, String amount) {
    return '$name wins $amount';
  }

  @override
  String winsLineWith(String name, String amount, String description) {
    return '$name wins $amount with $description';
  }

  @override
  String get revealInOrder => 'In order (beaten hands muck)';

  @override
  String get badgeMucked => 'Mucked';

  @override
  String logMucks(String name) {
    return '$name mucks';
  }

  @override
  String get micTitle => 'Microphone';

  @override
  String get micHint =>
      'Voice chat runs browser to browser. Your microphone is only sent to the other players at this table.';

  @override
  String get micStateOff => 'Voice chat off';

  @override
  String get micStateOn => 'Microphone on';

  @override
  String get micStateMuted => 'Microphone muted';

  @override
  String get voiceMutedByHost =>
      'The host muted your microphone. You can unmute yourself.';

  @override
  String get adminMuteVoice => 'Mute microphone';

  @override
  String get adminMutedVoice => 'Microphone muted';

  @override
  String adminPlayerActions(String name) {
    return '$name';
  }

  @override
  String get adminMuteChat => 'Mute chat';

  @override
  String get adminUnmuteChat => 'Unmute chat';

  @override
  String get sayTitle => 'Say something';

  @override
  String get sayButton => 'Quick phrase';

  @override
  String get phraseNiceHand => 'Nice hand';

  @override
  String get phraseNiceCall => 'Nice call';

  @override
  String get phraseNiceFold => 'Nice fold';

  @override
  String get phraseNiceBluff => 'Nice bluff';

  @override
  String get phraseWellPlayed => 'Well played';

  @override
  String get phraseGg => 'GG';

  @override
  String get phraseThanks => 'Thanks';

  @override
  String get phraseSorry => 'Sorry';

  @override
  String get phraseWow => 'Wow';

  @override
  String get phraseOops => 'Oops';

  @override
  String get phraseFurious => 'I\'m furious';

  @override
  String get phraseLol => 'LOL';

  @override
  String get phraseHurryUp => 'Hurry up';

  @override
  String get phraseBrb => 'Be right back';

  @override
  String get tabSettings => 'Settings';

  @override
  String get setTimeBank => 'Time bank (seconds, 0 = off)';

  @override
  String get errTimeBank => '0 to 120 seconds';

  @override
  String get setTimeBankRefill => 'Time bank refill per hand (seconds)';

  @override
  String get errTimeBankRefill => '0 to 30 seconds';

  @override
  String get setAllowStraddle => 'Allow straddle';

  @override
  String get setRunItTwice => 'Offer run it twice';

  @override
  String logStraddle(String name, String amount) {
    return '$name posts a straddle $amount';
  }

  @override
  String logBoard2(String street, String cards) {
    return 'Board 2 · $street: $cards';
  }

  @override
  String boardLabel(int n) {
    return 'Board $n';
  }

  @override
  String get badgeStraddle => 'STR';

  @override
  String timeBankStrip(int seconds) {
    return 'Time bank · $seconds s';
  }

  @override
  String timeBankLeft(int seconds) {
    return 'Time bank $seconds s';
  }

  @override
  String get straddleToggle => 'Straddle';

  @override
  String get straddleHint =>
      'Post twice the big blind before the deal when you sit left of the big blind.';

  @override
  String get runTwiceQuestion => 'Run it twice?';

  @override
  String get runTwiceYes => 'Yes, twice';

  @override
  String get runTwiceNo => 'No, once';

  @override
  String get runTwiceWaiting => 'Waiting for the others…';

  @override
  String get runTwiceDeclined => 'Running it once';

  @override
  String get lbHandsPlayed => 'Hands played';

  @override
  String get lbVpip => 'Voluntarily in the pot';

  @override
  String get lbShowdowns => 'Showdowns won / seen';

  @override
  String placeLabel(int place) {
    return '$place.';
  }

  @override
  String get outBadge => 'Out';

  @override
  String get logExportText => 'Export text';

  @override
  String get logExportJson => 'Export JSON';

  @override
  String get logExported => 'History exported';

  @override
  String get notifyTurn => 'Notify me when it\'s my turn';

  @override
  String get notifyTurnHint =>
      'A system notification (and a vibration on phones) when the tab is in the background.';

  @override
  String get notifyDenied => 'Notifications are blocked in this browser.';

  @override
  String get notifyTitle => 'Your turn';

  @override
  String notifyBody(String table) {
    return 'It\'s your turn at $table';
  }

  @override
  String get cameraTitle => 'Camera';

  @override
  String get cameraOn => 'Camera on';

  @override
  String get cameraOff => 'Camera off';

  @override
  String get cameraHint =>
      'A small video next to your avatar, sent browser to browser like the voice. Works best with up to six players.';

  @override
  String get cameraUnavailable => 'The browser did not grant the camera.';

  @override
  String get cameraOffByHost =>
      'The host turned your camera off. You can turn it on again.';

  @override
  String get adminCameraOff => 'Turn camera off';

  @override
  String get adminCameraOffDone => 'Camera turned off';

  @override
  String get cameraJoinHint =>
      'Adds a small camera tile next to your avatar (turns the voice chat on as well). The browser asks for the camera once.';

  @override
  String get showCameras => 'Show other players\' cameras';

  @override
  String get showCamerasHint =>
      'Off saves bandwidth: the others stop sending you video. Your own camera is unaffected.';

  @override
  String get scFocusAmount => 'Type the raise amount (Esc leaves the field)';

  @override
  String get showdownSpotlight => 'Showdown spotlight';
}
