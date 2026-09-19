import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/account.dart';
import '../../../core/file_saver.dart';
import '../../../core/formatting.dart';
import '../../../core/gamepad/gamepad.dart';
import '../../../core/gamepad/pad_section.dart';
import '../../../core/providers.dart';
import '../../../core/session_store.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../../shared/kbd_hint.dart';
import '../../../shared/suit_painter.dart';
import '../../account/account_dialog.dart';
import '../../account/account_sheet.dart';
import '../../account/stats_dialog.dart';
import '../../admin/admin_panel.dart';
import '../../admin/table_rules_section.dart';
import '../log_text.dart';
import '../replay/replay_dialog.dart';
import '../table_session.dart';
import 'settings_tab.dart';

/// Tabs of the side panel. [admin] exists only for the table's host.
enum PanelTab { chat, log, leaderboard, settings }

/// Chat · Log · Leaderboard (· Admin for the host) with unread badges.
class SidePanel extends ConsumerStatefulWidget {
  const SidePanel({
    super.key,
    required this.tableId,
    required this.tab,
    required this.onTabChanged,
    required this.chatFocusNode,
    required this.onSendChat,
    required this.settings,
    this.adminToken,
    this.onSay,
  });

  /// Players: the quick phrases and stickers, offered in the chat too.
  final VoidCallback? onSay;

  /// Builds one page of the settings menu (voice, preferences, table).
  final Widget Function(SettingsPart part) settings;

  final String tableId;

  /// The table's admin token when this device hosts the table.
  final String? adminToken;
  final PanelTab tab;
  final ValueChanged<PanelTab> onTabChanged;
  final FocusNode chatFocusNode;
  final ValueChanged<String> onSendChat;

  @override
  ConsumerState<SidePanel> createState() => SidePanelState();
}

/// The pages inside the Settings tab. The host's pages need the admin token.
enum SettingsPage {
  voice,
  preferences,
  table,
  hostControls,
  hostRules,
  hostPlayers,
  hostChat,
  hostHands,
}

class SidePanelState extends ConsumerState<SidePanel> {
  /// The open settings page; null shows the settings menu.
  SettingsPage? _page;

  /// The panel owns its tab so that it also works inside the bottom sheet,
  /// whose overlay does not rebuild with the page. [SidePanel.tab] is the
  /// initial tab and follows keyboard toggles from the page.
  late PanelTab _tab = widget.tab;

  /// One focus node per tab: with a controller the tabs are controls (the
  /// cursor lands on the active one, ← → walk them, A selects), so a tab
  /// without any control of its own, like the leaderboard, still keeps
  /// the cursor in the panel.
  final _tabFocus = {for (final t in PanelTab.values) t: FocusNode()};

  /// The focus node of [tab]'s strip item, for the controller.
  FocusNode tabNode(PanelTab tab) => _tabFocus[tab]!;

  @override
  void dispose() {
    for (final n in _tabFocus.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tab != widget.tab) _tab = widget.tab;
    _markRead();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _select(PanelTab tab) {
    setState(() {
      _tab = tab;
      _page = null;
    });
    widget.onTabChanged(tab);
    _markRead();
  }

  /// Controller: switch tabs (LT / RT).
  void selectTab(PanelTab tab) => _select(tab);

  /// Controller B: back from a settings page; false when at the top.
  bool back() {
    if (_page != null) {
      setState(() => _page = null);
      return true;
    }
    return false;
  }

  /// The open settings page's title, for the controller legend.
  String? pageTitle(AppLocalizations l10n) =>
      _page == null ? null : _pageTitle(l10n, _page!);

  Future<void> _replay() async {
    final session = ref.read(tableSessionProvider(widget.tableId));
    final stored = ref.read(sessionProvider(widget.tableId)).value;
    final adminToken = widget.adminToken;
    final token = adminToken ?? stored?.token;
    final snapshot = session.snapshot;
    if (token == null || snapshot == null) return;
    await showReplayDialog(
      context,
      tableId: widget.tableId,
      token: token,
      admin: adminToken != null && stored == null,
      base: snapshot,
      viewerSeat: session.mySeat,
    );
  }

  void _markRead() {
    final n = ref.read(tableSessionProvider(widget.tableId).notifier);
    switch (_tab) {
      case PanelTab.chat:
        n.markChatRead();
      case PanelTab.log:
      case PanelTab.leaderboard:
      case PanelTab.settings:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(tableSessionProvider(widget.tableId));
    ref.listen(tableSessionProvider(widget.tableId), (_, _) => _markRead());
    Widget label(String text, int unread) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (unread > 0) ...[const Gap(6), PrimaryBadge(child: Text('$unread'))],
      ],
    );
    final adminToken = widget.adminToken;
    final tab = _tab;
    // Four tabs for everyone; the host's pages live inside Settings.
    final visible = [
      PanelTab.chat,
      PanelTab.log,
      PanelTab.leaderboard,
      PanelTab.settings,
    ];
    // Phones: the text tabs do not fit in one row and the settings gear
    // ended up off-screen; icons with tooltips keep every tab in view.
    final narrow = MediaQuery.sizeOf(context).width < 700;
    Widget iconTab(IconData icon, String name) => Tooltip(
      tooltip: TooltipContainer(child: Text(name)).call,
      child: Icon(icon, size: 18),
    );
    final unreadChat = tab == PanelTab.chat ? 0 : session.unreadChat;
    // Each tab is a control of its own (focus, A), for the controller.
    Widget padTab(PanelTab t, Widget child) => Clickable(
      focusNode: _tabFocus[t],
      onPressed: () => _select(t),
      child: child,
    );
    final tabs = Tabs(
      index: visible.indexOf(tab),
      onChanged: (i) => _select(visible[i]),
      children: [
        TabItem(
          child: padTab(
            PanelTab.chat,
            narrow
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconTab(LucideIcons.messageCircle, l10n.tabChat),
                      if (unreadChat > 0) ...[
                        const Gap(4),
                        PrimaryBadge(child: Text('$unreadChat')),
                      ],
                    ],
                  )
                : label(l10n.tabChat, unreadChat),
          ),
        ),
        // The log carries no counter: only chat messages are announced.
        TabItem(
          child: padTab(
            PanelTab.log,
            narrow
                ? iconTab(LucideIcons.scrollText, l10n.tabLog)
                : Text(l10n.tabLog),
          ),
        ),
        TabItem(
          child: padTab(
            PanelTab.leaderboard,
            narrow
                ? iconTab(LucideIcons.trophy, l10n.tabLeaderboard)
                : Text(l10n.tabLeaderboard),
          ),
        ),
        TabItem(
          key: const Key('tab-settings'),
          child: padTab(
            PanelTab.settings,
            narrow
                ? iconTab(LucideIcons.settings, l10n.tabSettings)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.settings, size: 14),
                      const Gap(6),
                      Text(l10n.tabSettings),
                    ],
                  ),
          ),
        ),
      ],
    );
    // Inside a settings page the tab strip gives way to a back button and
    // the page title: the page is a level below the tabs.
    final page = tab == PanelTab.settings ? _page : null;
    // With a controller: is its cursor in this panel (caps show LT / RT
    // for the tabs and B for back) or elsewhere (a Back cap says how to
    // get here)? Null without a controller.
    final padHere = ref.watch(gamepadProvider) && ref.watch(padHintsProvider)
        ? ref.watch(
            padCursorProvider.select((c) => c.section == PadSection.panel),
          )
        : null;
    final header = page == null
        ? Row(
            children: [
              // Controller caps: how to get here, or how to switch tabs.
              if (padHere == false) ...[
                const KbdHint('', pad: 'Back'),
                const Gap(6),
              ],
              // With text tabs there is no room; the legend has them.
              if ((padHere ?? false) && narrow) ...[
                const KbdHint('', pad: 'LT'),
                const Gap(4),
              ],
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: tabs,
                ),
              ),
              if ((padHere ?? false) && narrow) ...[
                const Gap(4),
                const KbdHint('', pad: 'RT'),
              ],
            ],
          )
        : Row(
            children: [
              GhostButton(
                key: const Key('settings-back'),
                density: ButtonDensity.icon,
                onPressed: () => setState(() => _page = null),
                child: const Icon(LucideIcons.arrowLeft),
              ),
              if (padHere ?? false) ...[
                const Gap(2),
                const KbdHint('', pad: 'B'),
              ],
              const Gap(4),
              Expanded(child: Text(_pageTitle(l10n, page)).semiBold()),
            ],
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const Gap(8),
        Expanded(
          child: switch (tab) {
            PanelTab.chat => ChatPanel(
              session: session,
              focusNode: widget.chatFocusNode,
              onSend: widget.onSendChat,
              onSay: widget.onSay,
            ),
            PanelTab.log => HandLog(
              session: session,
              onReplay: session.snapshot == null ? null : _replay,
            ),
            PanelTab.leaderboard => TableLeaderboard(
              snapshot: session.snapshot,
            ),
            PanelTab.settings => switch (page) {
              null => _SettingsMenu(
                isPlayer: session.isPlayer,
                host: adminToken != null,
                onOpen: (p) => setState(() => _page = p),
              ),
              SettingsPage.voice => widget.settings(SettingsPart.voice),
              SettingsPage.preferences => widget.settings(
                SettingsPart.preferences,
              ),
              SettingsPage.table => widget.settings(SettingsPart.table),
              SettingsPage.hostRules => SingleChildScrollView(
                child: TableRulesSection(
                  key: const Key('table-rules'),
                  tableId: widget.tableId,
                  token: adminToken!,
                ),
              ),
              SettingsPage.hostControls => AdminPanel(
                tableId: widget.tableId,
                token: adminToken!,
                part: AdminPart.controls,
              ),
              SettingsPage.hostPlayers => AdminPanel(
                tableId: widget.tableId,
                token: adminToken!,
                part: AdminPart.players,
              ),
              SettingsPage.hostChat => AdminPanel(
                tableId: widget.tableId,
                token: adminToken!,
                part: AdminPart.chat,
              ),
              SettingsPage.hostHands => AdminPanel(
                tableId: widget.tableId,
                token: adminToken!,
                part: AdminPart.hands,
              ),
            },
          },
        ),
      ],
    );
  }
}

/// One line of the chat: a message or a system event.
class _ChatLine {
  const _ChatLine({
    required this.ts,
    required this.text,
    this.author,
    this.kind = 'system',
  });
  final int ts;
  final String text;
  final String? author;
  final String kind;
}

class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    required this.session,
    required this.focusNode,
    required this.onSend,
    this.onSay,
  });

  final TableSessionState session;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;

  /// Players: opens the quick phrases and stickers next to the input.
  final VoidCallback? onSay;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

/// The host chats under their own name, marked "(Admin)"; a seatless admin
/// view has no name and shows just the label.
String _authorLabel(AppLocalizations l10n, _ChatLine line) {
  final author = line.author ?? '';
  if (line.kind != 'admin') return author;
  if (author.isEmpty || author == 'admin') return l10n.chatAdmin;
  return '$author (${l10n.chatAdmin})';
}

class _ChatPanelState extends State<ChatPanel> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = widget.session;
    // Only what people wrote (and the server's own notices): table events
    // live in the log tab and are not repeated here.
    final lines = <_ChatLine>[
      for (final m in s.chat)
        _ChatLine(
          ts: m.ts,
          text: m.text,
          author: m.authorName,
          kind: m.authorKind,
        ),
    ]..sort((a, b) => a.ts.compareTo(b.ts));

    final settings = s.snapshot?.table.settings;
    String? disabledNote;
    if (settings != null && !settings.chatEnabled) {
      disabledNote = l10n.chatDisabled;
    } else if (settings != null &&
        !s.isPlayer &&
        s.identity?.role == 'spectator' &&
        !settings.spectatorChat) {
      disabledNote = l10n.chatSpectatorsOff;
    } else if (s.lastError?.code == 'muted') {
      disabledNote = l10n.chatMuted;
    }

    return Column(
      children: [
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    l10n.chatEmpty,
                    key: const Key('chat-empty'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  itemCount: lines.length,
                  itemBuilder: (context, i) {
                    final line = lines[lines.length - 1 - i];
                    final isAdmin = line.kind == 'admin';
                    final isSystem =
                        line.author == null || line.kind == 'system';
                    final color = isSystem
                        ? theme.colorScheme.mutedForeground
                        : HSLColor.fromAHSL(
                            1,
                            nameHue(line.author!),
                            0.6,
                            theme.colorScheme.brightness == Brightness.dark
                                ? 0.7
                                : 0.4,
                          ).toColor();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Container(
                        padding: isAdmin
                            ? const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              )
                            : EdgeInsets.zero,
                        decoration: isAdmin
                            ? BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        // Selectable so a line can be picked up and copied
                        // (a link someone posted, a name, the whole message).
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${formatClock(line.ts)} ',
                                style: TextStyle(
                                  color: theme.colorScheme.mutedForeground,
                                  fontSize: 11,
                                  fontFamily: 'GeistMono',
                                ),
                              ),
                              if (!isSystem)
                                TextSpan(
                                  text: '${_authorLabel(l10n, line)}: ',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ...cardSpans(
                                line.text,
                                style: isSystem
                                    ? TextStyle(
                                        color:
                                            theme.colorScheme.mutedForeground,
                                        fontStyle: FontStyle.italic,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const Gap(8),
        if (disabledNote != null)
          Text(
            disabledNote,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.mutedForeground,
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chat-input'),
                  controller: _controller,
                  focusNode: widget.focusNode,
                  placeholder: Text(l10n.chatPlaceholder),
                  maxLength: 300,
                  onSubmitted: (_) {
                    _send();
                    widget.focusNode.requestFocus();
                  },
                ),
              ),
              if (widget.onSay != null) ...[
                const Gap(2),
                Tooltip(
                  tooltip: TooltipContainer(child: Text(l10n.sayButton)).call,
                  child: GhostButton(
                    key: const Key('chat-say'),
                    density: ButtonDensity.icon,
                    onPressed: widget.onSay,
                    child: const Icon(LucideIcons.smile),
                  ),
                ),
              ],
              const Gap(2),
              GhostButton(
                density: ButtonDensity.icon,
                onPressed: _send,
                child: const Icon(LucideIcons.send),
              ),
            ],
          ),
      ],
    );
  }
}

class HandLog extends ConsumerWidget {
  const HandLog({super.key, required this.session, this.onReplay});

  final TableSessionState session;

  /// Opens the hand replay (null when no hands can be loaded yet).
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final chipDisplay = ref.watch(chipDisplayProvider);
    final bigBlind = session.snapshot?.table.settings.bigBlind ?? 0;
    String amount(int v) =>
        formatAmount(v, mode: chipDisplay, bigBlind: bigBlind, locale: locale);
    final lines = <(int, String)>[];
    for (final e in session.log) {
      final text = logLineText(
        l10n,
        e,
        mySeat: session.mySeat,
        locale: locale,
        amount: amount,
      );
      if (text != null) lines.add((e.event.ts, text));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: lines.isEmpty
              ? Center(
                  child: Text(
                    l10n.logEmpty,
                    style: TextStyle(color: theme.colorScheme.mutedForeground),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: lines.length,
                  itemBuilder: (context, i) {
                    final (ts, text) = lines[lines.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${formatClock(ts)} ',
                              style: TextStyle(
                                color: theme.colorScheme.mutedForeground,
                                fontSize: 11,
                                fontFamily: 'GeistMono',
                              ),
                            ),
                            ...cardSpans(
                              text,
                              blackSuit: theme.colorScheme.foreground,
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
        ),
        const Gap(8),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 6,
          runSpacing: 6,
          children: [
            OutlineButton(
              key: const Key('log-replay'),
              size: ButtonSize.small,
              leading: const Icon(LucideIcons.rotateCcw),
              onPressed: onReplay,
              child: Text(l10n.replayOpen),
            ),
            OutlineButton(
              key: const Key('log-export-text'),
              size: ButtonSize.small,
              leading: const Icon(LucideIcons.download),
              onPressed: lines.isEmpty
                  ? null
                  : () {
                      FileSaver.create().saveText(
                        'showdown-${session.snapshot?.table.id ?? 'table'}.txt',
                        lines
                            .map((l) => '${formatClock(l.$1)} ${l.$2}')
                            .join('\n'),
                      );
                      showToast(
                        context: context,
                        location: ToastLocation.bottomCenter,
                        builder: (context, overlay) =>
                            SurfaceCard(child: Text(l10n.logExported)),
                      );
                    },
              child: Text(l10n.logExportText),
            ),
            OutlineButton(
              key: const Key('log-export-json'),
              size: ButtonSize.small,
              leading: const Icon(LucideIcons.fileJson),
              onPressed: session.log.isEmpty
                  ? null
                  : () {
                      FileSaver.create().saveText(
                        'showdown-${session.snapshot?.table.id ?? 'table'}.json',
                        jsonEncode([
                          for (final e in session.log)
                            {
                              'hand': e.handNumber,
                              'names': {
                                for (final n in e.names.entries)
                                  '${n.key}': n.value,
                              },
                              'event': e.event.toJson(),
                            },
                        ]),
                        mimeType: 'application/json',
                      );
                      showToast(
                        context: context,
                        location: ToastLocation.bottomCenter,
                        builder: (context, overlay) =>
                            SurfaceCard(child: Text(l10n.logExported)),
                      );
                    },
              child: Text(l10n.logExportJson),
            ),
            OutlineButton(
              size: ButtonSize.small,
              leading: const Icon(LucideIcons.copy),
              onPressed: lines.isEmpty
                  ? null
                  : () {
                      Clipboard.setData(
                        ClipboardData(
                          text: lines
                              .map((l) => '${formatClock(l.$1)} ${l.$2}')
                              .join('\n'),
                        ),
                      );
                      showToast(
                        context: context,
                        location: ToastLocation.bottomCenter,
                        builder: (context, overlay) =>
                            SurfaceCard(child: Text(l10n.logCopied)),
                      );
                    },
              child: Text(l10n.logCopy),
            ),
          ],
        ),
      ],
    );
  }
}

class TableLeaderboard extends ConsumerWidget {
  const TableLeaderboard({super.key, required this.snapshot});

  final Snapshot? snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final chipDisplay = ref.watch(chipDisplayProvider);
    final bigBlind = snapshot?.table.settings.bigBlind ?? 0;
    final entries = snapshot?.leaderboard ?? const <LeaderboardEntry>[];
    // While the table sits ended the live list is that round's standing;
    // the section only earns its place once a new round has started.
    final last = snapshot?.table.state == 'ended' ? null : snapshot?.lastRound;
    final avatars = {
      for (final sv in snapshot?.seats ?? const <SeatView>[])
        if (sv.player != null) sv.player!.name: sv.player!.avatar,
    };
    String amount(int v) =>
        formatAmount(v, mode: chipDisplay, bigBlind: bigBlind, locale: locale);
    final muted = TextStyle(
      fontSize: 11,
      color: theme.colorScheme.mutedForeground,
    );
    return ListView(
      children: [
        // The round that finished before this one: the stacks and statistics
        // below were reset when the new round opened, so this is the only
        // place the result is still readable.
        if (last != null) ...[
          _LeaderboardSection(
            label:
                '${l10n.lastRoundTitle} · ${l10n.lastRoundHands(last.hands)}',
          ),
          for (var i = 0; i < last.standings.length; i++)
            _LeaderboardRow(
              index: i,
              e: last.standings[i],
              avatars: avatars,
              amount: amount,
              muted: muted,
            ),
          const Gap(6),
          const Divider(),
          _LeaderboardSection(label: l10n.thisRound),
        ],
        for (var i = 0; i < entries.length; i++)
          _LeaderboardRow(
            index: i,
            e: entries[i],
            avatars: avatars,
            amount: amount,
            muted: muted,
          ),
      ],
    );
  }
}

/// A heading inside the leaderboard (last round / this round).
class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 2),
    child: Text(label).muted().small().semiBold(),
  );
}

/// One player's line in the leaderboard.
class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.index,
    required this.e,
    required this.avatars,
    required this.amount,
    required this.muted,
  });

  final int index;
  final LeaderboardEntry e;
  final Map<String, int> avatars;
  final String Function(int) amount;
  final TextStyle muted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              (e.place ?? 0) > 0 ? l10n.placeLabel(e.place!) : '${index + 1}.',
              style: (e.place ?? 0) > 0
                  ? muted.copyWith(fontWeight: FontWeight.w700)
                  : muted,
            ),
          ),
          PlayerAvatar(index: avatars[e.name] ?? 0, size: 28),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Tooltip(
                      tooltip: TooltipContainer(child: Text(l10n.lbHandsWon))
                          .call,
                      child: Icon(
                        LucideIcons.trophy,
                        size: 11,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const Gap(3),
                    Text('${e.handsWon}', style: muted),
                    const Gap(10),
                    Tooltip(
                      tooltip: TooltipContainer(child: Text(l10n.lbBiggestPot))
                          .call,
                      child: Icon(
                        LucideIcons.coins,
                        size: 11,
                        color: theme.colorScheme.mutedForeground,
                      ),
                    ),
                    const Gap(3),
                    Text(amount(e.biggestPot), style: muted),
                    if ((e.handsPlayed ?? 0) > 0) ...[
                      const Gap(10),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text(l10n.lbVpip))
                            .call,
                        child: Icon(
                          LucideIcons.flame,
                          size: 11,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        '${(100 * (e.vpipHands ?? 0) / e.handsPlayed!).round()}%',
                        style: muted,
                      ),
                      const Gap(10),
                      Tooltip(
                        tooltip: TooltipContainer(child: Text(l10n.lbShowdowns))
                            .call,
                        child: Icon(
                          LucideIcons.swords,
                          size: 11,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        '${e.showdownsWon ?? 0}/${e.showdowns ?? 0}',
                        style: muted,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount(e.stack),
                style: const TextStyle(fontFamily: 'GeistMono'),
              ),
              Text(
                (e.net > 0 ? '+' : '') + amount(e.net),
                style: TextStyle(
                  fontFamily: 'GeistMono',
                  fontSize: 11,
                  color: e.net > 0
                      ? const Color(0xFF43A047)
                      : (e.net < 0
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.mutedForeground),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _pageTitle(AppLocalizations l10n, SettingsPage page) => switch (page) {
  SettingsPage.voice => l10n.settingsVoiceVideo,
  SettingsPage.preferences => l10n.menuPreferences,
  SettingsPage.table => l10n.menuTable,
  SettingsPage.hostControls => l10n.hostControls,
  SettingsPage.hostRules => l10n.settingsTableRules,
  SettingsPage.hostPlayers => l10n.adminPlayers,
  SettingsPage.hostChat => l10n.hostChat,
  SettingsPage.hostHands => l10n.adminTabHands,
};

/// The root of the Settings tab: one row per page, the host's pages in
/// their own section.
class _SettingsMenu extends ConsumerWidget {
  const _SettingsMenu({
    required this.isPlayer,
    required this.host,
    required this.onOpen,
  });

  final bool isPlayer;
  final bool host;
  final ValueChanged<SettingsPage> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    Widget row(
      SettingsPage page,
      IconData icon,
      String title,
      String subtitle, {
      required String keyName,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlineButton(
        key: Key('settings-$keyName'),
        onPressed: () => onOpen(page),
        alignment: Alignment.centerLeft,
        leading: Icon(icon, size: 18, color: theme.colorScheme.mutedForeground),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(title.toUpperCase()).muted().xSmall().semiBold(),
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPlayer)
            row(
              SettingsPage.voice,
              LucideIcons.headphones,
              l10n.settingsVoiceVideo,
              l10n.settingsVoiceVideoHint,
              keyName: 'voice',
            ),
          row(
            SettingsPage.preferences,
            LucideIcons.slidersHorizontal,
            l10n.menuPreferences,
            l10n.settingsPreferencesHint,
            keyName: 'preferences',
          ),
          row(
            SettingsPage.table,
            LucideIcons.armchair,
            l10n.menuTable,
            l10n.settingsTableHint,
            keyName: 'table',
          ),
          // The profile, on the instances that have them: the same sheet
          // the person in the app bar opens elsewhere.
          if (ref.watch(accountsEnabledProvider).value == true) ...[
            section(l10n.accountMenu),
            Builder(
              builder: (context) {
                final account = ref.watch(accountProvider).value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlineButton(
                    key: const Key('settings-account'),
                    onPressed: () => account == null
                        ? showAccountDialog(context)
                        : showAccountSheet(context),
                    alignment: Alignment.centerLeft,
                    leading: Icon(
                      account == null
                          ? LucideIcons.user
                          : LucideIcons.userCheck,
                      size: 18,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          account == null
                              ? l10n.accountSignIn
                              : '@${account.handle}',
                        ),
                        Text(
                          account == null
                              ? l10n.accountGuestHint
                              : l10n.accountMenuHint,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // The record itself, for a player who is signed in: the same
            // dialog the profile sheet opens.
            Builder(
              builder: (context) {
                if (ref.watch(accountProvider).value == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlineButton(
                    key: const Key('settings-stats'),
                    onPressed: () => showStatsDialog(context),
                    alignment: Alignment.centerLeft,
                    leading: Icon(
                      LucideIcons.chartNoAxesColumn,
                      size: 18,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.colorScheme.mutedForeground,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.statsOpen),
                        Text(
                          l10n.statsMenuHint,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          if (host) ...[
            section(l10n.tabAdmin),
            row(
              SettingsPage.hostControls,
              LucideIcons.play,
              l10n.hostControls,
              l10n.hostControlsHint,
              keyName: 'host-controls',
            ),
            row(
              SettingsPage.hostRules,
              LucideIcons.listChecks,
              l10n.settingsTableRules,
              l10n.settingsTableRulesHint,
              keyName: 'host-rules',
            ),
            row(
              SettingsPage.hostPlayers,
              LucideIcons.users,
              l10n.adminPlayers,
              l10n.hostPlayersHint,
              keyName: 'host-players',
            ),
            row(
              SettingsPage.hostChat,
              LucideIcons.messageSquareOff,
              l10n.hostChat,
              l10n.hostChatHint,
              keyName: 'host-chat',
            ),
            row(
              SettingsPage.hostHands,
              LucideIcons.history,
              l10n.adminTabHands,
              l10n.hostHandsHint,
              keyName: 'host-hands',
            ),
          ],
        ],
      ),
    );
  }
}
