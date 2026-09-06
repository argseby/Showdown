// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Showdown';

  @override
  String get landingTagline => 'Texas Hold\'em für deine private Runde.';

  @override
  String get landingCodeLabel => 'Tisch-Link oder Code';

  @override
  String get landingCodePlaceholder =>
      'https://example.com/t/k7m2p9xq4w oder k7m2p9xq4w';

  @override
  String get landingJoin => 'Tisch öffnen';

  @override
  String get landingInvalidCode =>
      'Das sieht nicht wie ein Tisch-Link oder Code aus.';

  @override
  String get notFoundTitle => 'Seite nicht gefunden';

  @override
  String get notFoundBody => 'Unter dieser Adresse gibt es nichts.';

  @override
  String get notFoundHome => 'Zurück zum Start';

  @override
  String get themeToggle => 'Helles/dunkles Design umschalten';

  @override
  String get languageToggle => 'Sprache wechseln';

  @override
  String get languageEnglish => 'Englisch';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get joinTitle => 'Tisch beitreten';

  @override
  String joinSeats(int seated, int max) {
    return '$seated von $max Plätzen belegt';
  }

  @override
  String get joinStateWaiting => 'Wartet auf Spieler';

  @override
  String get joinStateRunning => 'Läuft';

  @override
  String get joinStatePaused => 'Pausiert';

  @override
  String get joinStateEnded => 'Beendet';

  @override
  String joinBlinds(String small, String big) {
    return 'Blinds $small/$big';
  }

  @override
  String get joinNameLabel => 'Dein Name';

  @override
  String get joinNamePlaceholder => '1-20 Zeichen';

  @override
  String get joinPasswordLabel => 'Tisch-Passwort';

  @override
  String get joinButton => 'Mitspielen';

  @override
  String get spectateButton => 'Zuschauen';

  @override
  String get joinNameInvalid => '1-20 Buchstaben, Ziffern, Leerzeichen, _ - .';

  @override
  String get joinPasswordRequired => 'Bitte das Tisch-Passwort eingeben.';

  @override
  String get joinLoadFailed => 'Dieser Tisch konnte nicht geladen werden.';

  @override
  String get joinTableEnded => 'Dieser Tisch ist beendet.';

  @override
  String get joinClosed => 'Der Beitritt ist an diesem Tisch geschlossen.';

  @override
  String get joinSpectatorsOff =>
      'Zuschauer sind an diesem Tisch nicht erlaubt.';

  @override
  String get tableNotFound => 'Tisch nicht gefunden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get errWrongPassword => 'Falsches Passwort';

  @override
  String get errNameTaken => 'Dieser Name ist schon vergeben';

  @override
  String get errTableFull => 'Der Tisch ist voll';

  @override
  String get errJoinsClosed => 'Der Beitritt ist geschlossen';

  @override
  String get errTableEnded => 'Der Tisch ist beendet';

  @override
  String get errInvalidName => 'Ungültiger Name';

  @override
  String get errSpectatorsDisabled => 'Zuschauer sind nicht erlaubt';

  @override
  String get errRateLimited =>
      'Zu viele Anfragen, bitte gleich noch einmal versuchen';

  @override
  String errGeneric(String message) {
    return 'Etwas ist schiefgelaufen: $message';
  }

  @override
  String get errNotYourTurn => 'Du bist nicht am Zug';

  @override
  String get errIllegalAction => 'Diese Aktion ist gerade nicht erlaubt';

  @override
  String get errAmountOutOfRange => 'Betrag außerhalb des erlaubten Bereichs';

  @override
  String handNumber(int number) {
    return 'Hand #$number';
  }

  @override
  String blindsShort(String small, String big) {
    return 'Blinds $small/$big';
  }

  @override
  String get connConnected => 'Verbunden';

  @override
  String get connConnecting => 'Verbinde...';

  @override
  String connReconnecting(int attempt) {
    return 'Verbinde neu... (Versuch $attempt)';
  }

  @override
  String get connDisconnected => 'Getrennt';

  @override
  String get replacedTitle => 'Anderswo verbunden';

  @override
  String get replacedBody =>
      'Dieser Platz wird jetzt von einer anderen Verbindung genutzt.';

  @override
  String get reconnectHere => 'Hier neu verbinden';

  @override
  String get kickedTitle => 'Vom Tisch entfernt';

  @override
  String get kickedBody => 'Der Admin hat dich von diesem Tisch entfernt.';

  @override
  String get sessionExpiredTitle => 'Sitzung abgelaufen';

  @override
  String get sessionExpiredBody =>
      'Deine Sitzung ist nicht mehr gültig. Bitte tritt erneut bei.';

  @override
  String get tableEndedTitle => 'Tisch beendet';

  @override
  String get finalStandings => 'Endstand';

  @override
  String get backToJoin => 'Zurück zur Tischseite';

  @override
  String get serverRestarting =>
      'Der Server startet neu, gleich geht es weiter...';

  @override
  String get leave => 'Verlassen';

  @override
  String get leaveConfirmTitle => 'Tisch verlassen?';

  @override
  String get leaveConfirmBody =>
      'Dein Platz wird frei. Läuft gerade eine Hand, passt du.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get close => 'Schließen';

  @override
  String get fold => 'Passen';

  @override
  String get check => 'Schieben';

  @override
  String call(String amount) {
    return 'Mitgehen $amount';
  }

  @override
  String get bet => 'Setzen';

  @override
  String get raise => 'Erhöhen';

  @override
  String get allIn => 'All-in';

  @override
  String raiseTo(String amount) {
    return 'Erhöhen auf $amount';
  }

  @override
  String betAmount(String amount) {
    return 'Setzen $amount';
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
    return 'Erlaubt: $min - $max';
  }

  @override
  String amountClamped(String amount) {
    return 'Betrag auf $amount angepasst';
  }

  @override
  String rebuy(String amount) {
    return 'Nachkaufen $amount';
  }

  @override
  String get sitOut => 'Aussetzen';

  @override
  String get sitIn => 'Ich bin zurück';

  @override
  String get showCards => 'Karten zeigen';

  @override
  String get waitingForPlayers => 'Warten auf Spieler...';

  @override
  String get tablePaused => 'Tisch pausiert';

  @override
  String get tableWaiting => 'Der Tisch hat noch nicht begonnen';

  @override
  String get yourTurn => 'Du bist dran';

  @override
  String get badgeDealer => 'D';

  @override
  String get badgeSmallBlind => 'SB';

  @override
  String get badgeBigBlind => 'BB';

  @override
  String get badgeSittingOut => 'Setzt aus';

  @override
  String get badgeDisconnected => 'Offline';

  @override
  String get badgeAllIn => 'All-in';

  @override
  String get badgeBusted => 'Pleite';

  @override
  String get badgeWaiting => 'Nächste Hand';

  @override
  String get badgeFolded => 'Gepasst';

  @override
  String get mainPot => 'Hauptpot';

  @override
  String sidePot(int n) {
    return 'Nebenpot $n';
  }

  @override
  String potTotal(String amount) {
    return 'Pot $amount';
  }

  @override
  String get tabChat => 'Chat';

  @override
  String get tabLog => 'Verlauf';

  @override
  String get tabLeaderboard => 'Rangliste';

  @override
  String get panelToggle => 'Seitenleiste ein-/ausblenden';

  @override
  String get chatPlaceholder => 'Nachricht...';

  @override
  String get chatDisabled => 'Der Chat ist deaktiviert';

  @override
  String get chatMuted => 'Du bist stummgeschaltet';

  @override
  String get chatSpectatorsOff => 'Zuschauer-Chat ist aus';

  @override
  String get chatSend => 'Senden';

  @override
  String get chatAdmin => 'Admin';

  @override
  String get logCopy => 'Verlauf kopieren';

  @override
  String get logCopied => 'Verlauf kopiert';

  @override
  String get logEmpty => 'Noch keine Ereignisse';

  @override
  String get lbName => 'Name';

  @override
  String get lbStack => 'Stack';

  @override
  String get lbNet => 'Netto';

  @override
  String get lbHandsWon => 'Gewonnen';

  @override
  String get lbBiggestPot => 'Größter Pot';

  @override
  String get shortcutsTitle => 'Tastaturkürzel';

  @override
  String get shortcutsHint =>
      'Kürzel sind beim Tippen inaktiv. Esc verlässt das Textfeld.';

  @override
  String get scFold => 'Passen';

  @override
  String get scCheckCall => 'Schieben / Mitgehen';

  @override
  String get scOpenRaise => 'Erhöhen-Regler öffnen';

  @override
  String get scAllIn => 'All-in wählen (Enter bestätigt)';

  @override
  String get scPresets => 'Vorgaben Min / 1/2 Pot / 3/4 Pot / Pot';

  @override
  String get scAmount => '+/- ein Big Blind (Shift: +/- fünf)';

  @override
  String get scConfirm => 'Setzen / Erhöhen bestätigen';

  @override
  String get scCancel =>
      'Erhöhen abbrechen / Overlay schließen / Textfeld verlassen';

  @override
  String get scChat => 'Chat fokussieren';

  @override
  String get scLog => 'Verlauf umschalten';

  @override
  String get scLeaderboard => 'Rangliste umschalten';

  @override
  String get scSound => 'Ton umschalten';

  @override
  String get scHelp => 'Dieses Overlay';

  @override
  String get soundOn => 'Ton an';

  @override
  String get soundOff => 'Ton aus';

  @override
  String spectatorsCount(int count) {
    return '$count schauen zu';
  }

  @override
  String get roleSpectator => 'Zuschauer';

  @override
  String get roleAdmin => 'Admin-Ansicht';

  @override
  String get yourTurnTitle => '▶ Du bist dran — Showdown';

  @override
  String seatLabel(int seat) {
    return 'Platz $seat';
  }

  @override
  String get emptySeat => 'Frei';

  @override
  String get you => 'Du';

  @override
  String logHandStarted(int number, String name) {
    return 'Hand #$number beginnt. Dealer: $name';
  }

  @override
  String logAnte(String name, String amount) {
    return '$name zahlt Ante $amount';
  }

  @override
  String logSmallBlind(String name, String amount) {
    return '$name setzt Small Blind $amount';
  }

  @override
  String logBigBlind(String name, String amount) {
    return '$name setzt Big Blind $amount';
  }

  @override
  String logDealt(String cards) {
    return 'Du bekommst $cards';
  }

  @override
  String logFold(String name) {
    return '$name passt';
  }

  @override
  String logCheck(String name) {
    return '$name schiebt';
  }

  @override
  String logCall(String name, String amount) {
    return '$name geht mit $amount';
  }

  @override
  String logBet(String name, String amount) {
    return '$name setzt $amount';
  }

  @override
  String logRaise(String name, String amount) {
    return '$name erhöht auf $amount';
  }

  @override
  String get logAllInSuffix => ' (All-in)';

  @override
  String logTimeoutCheck(String name) {
    return '$name lässt die Zeit ablaufen und schiebt';
  }

  @override
  String logTimeoutFold(String name) {
    return '$name lässt die Zeit ablaufen und passt';
  }

  @override
  String logUncalled(String amount, String name) {
    return 'Nicht mitgegangene $amount gehen an $name zurück';
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
    return '$name zeigt $cards - $description';
  }

  @override
  String logRevealNoDesc(String name, String cards) {
    return '$name zeigt $cards';
  }

  @override
  String logWin(String name, String amount, String pot, String description) {
    return '$name gewinnt $amount ($pot) mit $description';
  }

  @override
  String logWinUncontested(String name, String amount, String pot) {
    return '$name gewinnt $amount ($pot)';
  }

  @override
  String logVoided(String reason) {
    return 'Hand annulliert ($reason)';
  }

  @override
  String logJoined(String name, int seat) {
    return '$name ist beigetreten (Platz $seat)';
  }

  @override
  String logLeft(String name) {
    return '$name hat den Tisch verlassen';
  }

  @override
  String logKicked(String name) {
    return '$name wurde entfernt';
  }

  @override
  String logSatOut(String name) {
    return '$name setzt aus';
  }

  @override
  String logSatIn(String name) {
    return '$name ist zurück';
  }

  @override
  String logBusted(String name) {
    return '$name hat keine Chips mehr';
  }

  @override
  String logRebought(String name, String amount) {
    return '$name hat $amount nachgekauft';
  }

  @override
  String logChips(String name, String delta) {
    return 'Admin hat die Chips von $name um $delta angepasst';
  }

  @override
  String logSettings(String fields) {
    return 'Einstellungen geändert: $fields';
  }

  @override
  String get logStarted => 'Tisch gestartet';

  @override
  String get logPaused => 'Tisch pausiert';

  @override
  String get logResumed => 'Tisch fortgesetzt';

  @override
  String get logEnded => 'Tisch beendet';

  @override
  String get logRestarted => 'Server neu gestartet';

  @override
  String get adminTitle => 'Admin';

  @override
  String get adminNewTable => 'Neuer Tisch';

  @override
  String get adminCreate => 'Anlegen';

  @override
  String get adminSave => 'Speichern';

  @override
  String get adminSaved => 'Einstellungen gespeichert';

  @override
  String adminSavedNextHand(String fields) {
    return 'Gespeichert. Gilt ab der nächsten Hand: $fields';
  }

  @override
  String get adminNoChanges => 'Keine Änderungen';

  @override
  String get adminTableName => 'Tischname';

  @override
  String get adminTableNameInvalid => '1-40 Zeichen';

  @override
  String adminPlayersCount(int seated, int max) {
    return '$seated/$max Spieler';
  }

  @override
  String get adminCopyLink => 'Link kopieren';

  @override
  String get adminLinkCopied => 'Link kopiert';

  @override
  String get adminQrCode => 'QR-Code';

  @override
  String get adminSettings => 'Einstellungen';

  @override
  String get adminPlayers => 'Spieler';

  @override
  String get adminChat => 'Chat-Moderation';

  @override
  String get adminHands => 'Letzte Hände';

  @override
  String get adminNoHands => 'Noch keine Hände';

  @override
  String adminHandRow(int number, String time) {
    return 'Hand #$number · $time';
  }

  @override
  String get adminHandVoided => 'annulliert';

  @override
  String get adminStart => 'Starten';

  @override
  String get adminPause => 'Pausieren';

  @override
  String get adminResume => 'Fortsetzen';

  @override
  String get adminEnd => 'Beenden';

  @override
  String get adminDelete => 'Tisch löschen';

  @override
  String get adminEndTitle => 'Tisch beenden?';

  @override
  String get adminEndBody =>
      'Wähle, ob die laufende Hand erst zu Ende gespielt wird.';

  @override
  String get adminEndAfterHand => 'Nach dieser Hand';

  @override
  String get adminEndNow => 'Sofort, Hand annullieren';

  @override
  String get adminDeleteTitle => 'Diesen Tisch löschen?';

  @override
  String get adminDeleteBody =>
      'Alle Hände, der Chat und die Ergebnisse dieses Tisches werden gelöscht.';

  @override
  String get adminDeleteRunning =>
      'Ein laufender Tisch kann nicht gelöscht werden. Erst pausieren oder beenden.';

  @override
  String get adminKick => 'Entfernen';

  @override
  String adminKickTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get adminKickBody =>
      'Der Spieler passt sofort, der Platz wird nach der Hand frei.';

  @override
  String get adminChips => 'Chips';

  @override
  String adminChipsTitle(String name) {
    return 'Chips von $name anpassen';
  }

  @override
  String get adminChipsAmount => 'Betrag (negativ zum Abziehen)';

  @override
  String get adminChipsNote => 'Notiz';

  @override
  String get adminChipsInvalid => 'Bitte eine ganze Zahl ungleich 0 eingeben';

  @override
  String get adminChipsApplied => 'Chips angepasst';

  @override
  String get adminChipsQueued => 'Wird nach der Hand angewendet';

  @override
  String get adminMute => 'Stummschalten';

  @override
  String get adminUnmute => 'Stummschaltung aufheben';

  @override
  String get adminRemoveMessage => 'Nachricht entfernen';

  @override
  String get adminNoChat => 'Keine Chat-Nachrichten';

  @override
  String adminStateChanged(String state) {
    return 'Tisch ist jetzt $state';
  }

  @override
  String get adminAppliesNextHand => 'gilt ab der nächsten Hand';

  @override
  String get adminAppliesImmediately => 'gilt sofort';

  @override
  String get adminAppliesNextJoin => 'gilt beim nächsten Beitritt';

  @override
  String get adminAppliesFuture => 'gilt für künftige Beitritte und Nachkäufe';

  @override
  String adminSpectatorsWatching(int count, int connections) {
    return '$count Zuschauer · $connections Verbindungen';
  }

  @override
  String get setPassword => 'Tisch-Passwort (leer = keins)';

  @override
  String get setPasswordKeep =>
      'Leer lassen, um das aktuelle Passwort zu behalten';

  @override
  String get setPasswordClear => 'Passwort entfernen';

  @override
  String get setMaxPlayers => 'Max. Spieler';

  @override
  String get setStartMoney => 'Startgeld';

  @override
  String get setSmallBlind => 'Small Blind';

  @override
  String get setBigBlind => 'Big Blind';

  @override
  String get setAnte => 'Ante';

  @override
  String get setTurnTime => 'Zugzeit (s)';

  @override
  String get setDisconnectedTurnTime => 'Zugzeit bei Verbindungsabbruch (s)';

  @override
  String get setSitOutAfter => 'Aussetzen nach verpassten Zügen';

  @override
  String get setJoinPolicy => 'Beitrittsregel';

  @override
  String get joinPolicyAlways => 'Immer';

  @override
  String get joinPolicyBeforeStart => 'Nur vor dem Start';

  @override
  String get joinPolicyClosed => 'Geschlossen';

  @override
  String get setAllowSpectators => 'Zuschauer erlauben';

  @override
  String get setSpectatorChat => 'Zuschauer dürfen chatten';

  @override
  String get setChatEnabled => 'Chat aktiv';

  @override
  String get setAllowRebuy => 'Nachkauf erlauben';

  @override
  String get setShowdownReveal => 'Aufdecken beim Showdown';

  @override
  String get revealAll => 'Alle Hände';

  @override
  String get revealWinnersOnly => 'Nur Gewinner';

  @override
  String get setAutoStart => 'Automatisch starten';

  @override
  String get setHandDelay => 'Pause zwischen Händen (ms)';

  @override
  String valRange(String min, String max) {
    return 'Muss zwischen $min und $max liegen';
  }

  @override
  String valMin(String min) {
    return 'Muss mindestens $min sein';
  }

  @override
  String get valInteger => 'Muss eine ganze Zahl sein';

  @override
  String get valBigBlind => 'Muss mindestens der Small Blind sein';

  @override
  String get valDisconnected => 'Muss zwischen 3 und der Zugzeit liegen';

  @override
  String get valPassword => 'Muss leer oder 4-64 Zeichen lang sein';

  @override
  String get fourColorDeck => 'Vierfarbiges Deck';

  @override
  String get landingCreateTitle => 'Eine Runde hosten';

  @override
  String get landingCreateHint =>
      'Wer einen Tisch erstellt, leitet ihn: über den Admin-Tab am Tisch änderst du Einstellungen, verwaltest Spieler und beendest das Spiel. Kein Konto nötig.';

  @override
  String get landingCreate => 'Tisch erstellen';

  @override
  String get tabAdmin => 'Admin';

  @override
  String get adminKey => 'Admin-Schlüssel';

  @override
  String get adminKeyHint =>
      'Bewahre diesen Schlüssel auf. Damit kannst du den Tisch auch von einem anderen Gerät oder Browser aus verwalten; wer ihn hat, kann das ebenfalls.';

  @override
  String get adminKeyCopy => 'Schlüssel kopieren';

  @override
  String get adminKeyCopied => 'Schlüssel kopiert';

  @override
  String get adminKeyRejected =>
      'Dieser Admin-Schlüssel gilt nicht für diesen Tisch.';

  @override
  String get adminDeleted => 'Tisch gelöscht';

  @override
  String get joinHostBadge => 'Du leitest diesen Tisch';

  @override
  String get joinHostEnter =>
      'Ich leite diesen Tisch: Admin-Schlüssel eingeben';

  @override
  String get joinHostUse => 'Schlüssel verwenden';

  @override
  String get adminTabHands => 'Hände';

  @override
  String get setBlindsUpMinutes => 'Blinds erhöhen alle (Minuten, 0 = aus)';

  @override
  String get setBlindsUpPercent => 'Blinds erhöhen um (%)';

  @override
  String get setAllowRabbitHunt => 'Rabbit Hunting erlauben';

  @override
  String logRabbitHunt(String name, String cards) {
    return '$name schaut nach (Rabbit Hunt): $cards';
  }

  @override
  String logBlindsChanged(String small, String big) {
    return 'Blinds sind jetzt $small/$big';
  }

  @override
  String get foldCheckTitle => 'Kostenlos schieben?';

  @override
  String get foldCheckBody =>
      'Niemand hat gesetzt. Du kannst schieben und die nächste Karte sehen, ohne etwas zu zahlen.';

  @override
  String get foldCheckInstead => 'Lieber schieben';

  @override
  String get foldAnyway => 'Trotzdem passen';

  @override
  String get showFirstCard => '1. zeigen';

  @override
  String get showSecondCard => '2. zeigen';

  @override
  String get rabbitHunt => 'Rabbit Hunt';

  @override
  String get preCheckFold => 'Schieben / Passen';

  @override
  String get preCallAny => 'Alles mitgehen';

  @override
  String yourHand(String description) {
    return 'Deine Hand: $description';
  }

  @override
  String get sittingOutNotice => 'Du bist abwesend und bekommst keine Karten.';

  @override
  String get showCoins => 'Beträge in Chips anzeigen';

  @override
  String get showBigBlinds => 'Beträge in Big Blinds anzeigen';

  @override
  String get yourTurnBanner => 'Du bist dran';

  @override
  String yourTurnBannerTime(int seconds) {
    return 'Du bist dran · $seconds s';
  }

  @override
  String blindsUpIn(String time) {
    return 'Blinds steigen in $time';
  }

  @override
  String get adminBlindsUp => 'Blinds jetzt erhöhen';

  @override
  String adminBlindsRaised(String blinds) {
    return 'Blinds erhöht auf $blinds';
  }

  @override
  String get joinSeatLabel => 'Platz';

  @override
  String get joinSeatAny => 'Beliebiger freier Platz';

  @override
  String get joinAvatarLabel => 'Avatar';

  @override
  String get errSeatTaken =>
      'Dieser Platz wurde gerade belegt. Wähle einen anderen.';

  @override
  String get replayTitle => 'Hand nachspielen';

  @override
  String get replayOpen => 'Nachspielen';

  @override
  String get replayNoHands => 'Noch keine Hände gespielt';

  @override
  String replayLoadFailed(String message) {
    return 'Hände konnten nicht geladen werden: $message';
  }

  @override
  String get replayStart => 'Vor dem Geben';

  @override
  String get replayPlay => 'Abspielen';

  @override
  String get replayPause => 'Pause';

  @override
  String get replayPrev => 'Zurück';

  @override
  String get replayNext => 'Weiter';

  @override
  String replayStep(int step, int total) {
    return '$step / $total';
  }

  @override
  String get replayBackToList => 'Alle Hände';

  @override
  String replayReveals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler zeigen ihre Karten',
      one: 'Ein Spieler zeigt seine Karten',
    );
    return '$_temp0';
  }

  @override
  String get replayPrevHand => 'Vorherige Hand';

  @override
  String get replayNextHand => 'Nächste Hand';

  @override
  String logDeadBlind(String name, String amount) {
    return '$name setzt einen toten Big Blind $amount (Platzwechsel)';
  }

  @override
  String logPlayerMoved(String name, int seat) {
    return '$name wechselt auf Platz $seat';
  }

  @override
  String get takeSeatHint => 'Beim nächsten Geben hierher wechseln';

  @override
  String get seatPendingYou => 'Du, nächste Hand';

  @override
  String changeSeatTitle(int seat) {
    return 'Auf Platz $seat wechseln?';
  }

  @override
  String changeSeatBody(String amount) {
    return 'Der Wechsel passiert beim nächsten Geben. Ein Platzwechsel kostet in deiner nächsten Hand einen toten Big Blind von $amount (so kann niemand die Blinds umgehen), und du kannst erst nach drei Händen wieder wechseln.';
  }

  @override
  String get changeSeatConfirm => 'Wechseln';

  @override
  String get menuMore => 'Menü';

  @override
  String get takeSeat => 'Platz nehmen';

  @override
  String get panelClose => 'Leiste schließen';

  @override
  String get otherTable => 'Anderer Tisch';

  @override
  String get voiceJoin => 'Am Voice-Chat teilnehmen';

  @override
  String get voiceJoinHint =>
      'Audio direkt zwischen den Browsern; der Server hört nichts. Braucht ein Mikrofon und HTTPS (oder localhost).';

  @override
  String get voiceTitle => 'Voice-Chat';

  @override
  String get voiceOn => 'Voice-Chat an';

  @override
  String get voiceOff => 'Voice-Chat aus';

  @override
  String get voiceMute => 'Mikrofon stummschalten';

  @override
  String get voiceUnmute => 'Mikrofon einschalten';

  @override
  String get voiceUnavailable =>
      'Voice-Chat ist hier nicht möglich: der Browser gibt das Mikrofon nur über HTTPS oder localhost frei.';

  @override
  String get voiceSpeaking => 'spricht';

  @override
  String get menuPreferences => 'Einstellungen';

  @override
  String get menuTable => 'Tisch';

  @override
  String turnOf(String name, int seconds) {
    return '$name ist dran · $seconds s';
  }

  @override
  String showdownStrip(int seconds) {
    return 'Showdown · $seconds s';
  }

  @override
  String nextHandIn(int seconds) {
    return 'Nächste Hand in $seconds s';
  }

  @override
  String get adminUnsavedChanges => 'Du hast ungespeicherte Änderungen.';

  @override
  String get adminDiscard => 'Verwerfen';

  @override
  String get voiceMicOn => 'Mikrofon an';

  @override
  String get voiceMicMuted => 'Mikrofon stumm';

  @override
  String get joinAvatarChange => 'Avatar ändern';

  @override
  String get joinPickSeat => 'Platz wählen (optional)';

  @override
  String get joinPickSeatHide => 'Plätze ausblenden';

  @override
  String get displaySize => 'Darstellungsgröße';

  @override
  String get displaySizeHint => 'Größere Karten, Chips, Buttons und Schrift.';

  @override
  String get displayNormal => 'Normal';

  @override
  String get displayLarge => 'Groß';

  @override
  String get displayExtraLarge => 'Sehr groß';

  @override
  String get invite => 'Einladen';

  @override
  String get inviteTitle => 'Spieler einladen';

  @override
  String get inviteHint =>
      'Teile diesen Link oder lass den Code scannen. Der Link wurde in die Zwischenablage kopiert.';

  @override
  String invitePlayers(int count) {
    return 'Spieler ($count)';
  }

  @override
  String inviteSpectators(int count) {
    return 'Zuschauer ($count)';
  }

  @override
  String get inviteNobody => 'Noch niemand';

  @override
  String get winnerBadge => 'Gewinner';

  @override
  String winsLine(String name, String amount) {
    return '$name gewinnt $amount';
  }

  @override
  String winsLineWith(String name, String amount, String description) {
    return '$name gewinnt $amount mit $description';
  }

  @override
  String get revealInOrder => 'Der Reihe nach (geschlagene Hände mucken)';

  @override
  String get badgeMucked => 'Gemuckt';

  @override
  String logMucks(String name) {
    return '$name muckt';
  }

  @override
  String get micTitle => 'Mikrofon';

  @override
  String get micHint =>
      'Der Voice-Chat läuft direkt zwischen den Browsern. Dein Mikrofon geht nur an die Spieler an diesem Tisch.';

  @override
  String get micStateOff => 'Voice-Chat aus';

  @override
  String get micStateOn => 'Mikrofon an';

  @override
  String get micStateMuted => 'Mikrofon stumm';

  @override
  String get voiceMutedByHost =>
      'Der Gastgeber hat dein Mikrofon stummgeschaltet. Du kannst es selbst wieder einschalten.';

  @override
  String get adminMuteVoice => 'Mikrofon stummschalten';

  @override
  String get adminMutedVoice => 'Mikrofon stumm';

  @override
  String adminPlayerActions(String name) {
    return '$name';
  }

  @override
  String get adminMuteChat => 'Chat stummschalten';

  @override
  String get adminUnmuteChat => 'Chat freigeben';

  @override
  String get sayTitle => 'Sag etwas';

  @override
  String get sayButton => 'Kurzer Spruch';

  @override
  String get phraseNiceHand => 'Schöne Hand';

  @override
  String get phraseNiceCall => 'Guter Call';

  @override
  String get phraseNiceFold => 'Guter Fold';

  @override
  String get phraseNiceBluff => 'Schöner Bluff';

  @override
  String get phraseWellPlayed => 'Gut gespielt';

  @override
  String get phraseGg => 'GG';

  @override
  String get phraseThanks => 'Danke';

  @override
  String get phraseSorry => 'Sorry';

  @override
  String get phraseWow => 'Wow';

  @override
  String get phraseOops => 'Ups';

  @override
  String get phraseFurious => 'Ich koche vor Wut';

  @override
  String get phraseLol => 'LOL';

  @override
  String get phraseHurryUp => 'Mach hinne';

  @override
  String get phraseBrb => 'Bin gleich zurück';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get setTimeBank => 'Zeitbank (Sekunden, 0 = aus)';

  @override
  String get errTimeBank => '0 bis 120 Sekunden';

  @override
  String get setTimeBankRefill => 'Zeitbank-Auffüllung pro Hand (Sekunden)';

  @override
  String get errTimeBankRefill => '0 bis 30 Sekunden';

  @override
  String get setAllowStraddle => 'Straddle erlauben';

  @override
  String get setRunItTwice => 'Run it twice anbieten';

  @override
  String logStraddle(String name, String amount) {
    return '$name setzt Straddle $amount';
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
    return 'Zeitbank · $seconds s';
  }

  @override
  String timeBankLeft(int seconds) {
    return 'Zeitbank $seconds s';
  }

  @override
  String get straddleToggle => 'Straddle';

  @override
  String get straddleHint =>
      'Vor dem Geben den doppelten Big Blind setzen, wenn du links vom Big Blind sitzt.';

  @override
  String get runTwiceQuestion => 'Run it twice?';

  @override
  String get runTwiceYes => 'Ja, zweimal';

  @override
  String get runTwiceNo => 'Nein, einmal';

  @override
  String get runTwiceWaiting => 'Warte auf die anderen…';

  @override
  String get runTwiceDeclined => 'Es wird einmal gespielt';

  @override
  String get lbHandsPlayed => 'Hände gespielt';

  @override
  String get lbVpip => 'Freiwillig im Pot';

  @override
  String get lbShowdowns => 'Showdowns gewonnen / gesehen';

  @override
  String placeLabel(int place) {
    return '$place.';
  }

  @override
  String get outBadge => 'Raus';

  @override
  String get logExportText => 'Als Text exportieren';

  @override
  String get logExportJson => 'Als JSON exportieren';

  @override
  String get logExported => 'Verlauf exportiert';

  @override
  String get notifyTurn => 'Benachrichtigen, wenn ich dran bin';

  @override
  String get notifyTurnHint =>
      'Eine Systembenachrichtigung (und Vibration am Handy), wenn der Tab im Hintergrund ist.';

  @override
  String get notifyDenied =>
      'Benachrichtigungen sind in diesem Browser blockiert.';

  @override
  String get notifyTitle => 'Du bist dran';

  @override
  String notifyBody(String table) {
    return 'Du bist dran bei $table';
  }

  @override
  String get cameraTitle => 'Kamera';

  @override
  String get cameraOn => 'Kamera an';

  @override
  String get cameraOff => 'Kamera aus';

  @override
  String get cameraHint =>
      'Ein kleines Video neben deinem Avatar, direkt zwischen den Browsern wie die Sprache. Am besten bis sechs Spieler.';

  @override
  String get cameraUnavailable =>
      'Der Browser hat die Kamera nicht freigegeben.';

  @override
  String get cameraOffByHost =>
      'Der Gastgeber hat deine Kamera ausgeschaltet. Du kannst sie wieder einschalten.';

  @override
  String get adminCameraOff => 'Kamera ausschalten';

  @override
  String get adminCameraOffDone => 'Kamera ausgeschaltet';

  @override
  String get cameraJoinHint =>
      'Zeigt ein kleines Kamerabild neben deinem Avatar (schaltet auch den Voice-Chat ein). Der Browser fragt einmal nach der Kamera.';

  @override
  String get showCameras => 'Kameras der anderen anzeigen';

  @override
  String get showCamerasHint =>
      'Aus spart Bandbreite: die anderen senden dir kein Video mehr. Deine eigene Kamera bleibt unberührt.';

  @override
  String get scFocusAmount =>
      'Erhöhungsbetrag eintippen (Esc verlässt das Feld)';

  @override
  String get showdownSpotlight => 'Showdown-Spotlight';
}
