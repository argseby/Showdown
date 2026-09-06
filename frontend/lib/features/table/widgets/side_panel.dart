import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../../app/l10n.dart';
import '../../../app/preferences.dart';
import '../../../core/file_saver.dart';
import '../../../core/formatting.dart';
import '../../../core/session_store.dart';
import '../../../protocol/protocol.dart';
import '../../../shared/avatars.dart';
import '../../../shared/suit_painter.dart';
import '../../admin/admin_panel.dart';
import '../log_text.dart';
import '../replay/replay_dialog.dart';
import '../table_session.dart';

/// Tabs of the side panel. [admin] exists only for the table's host.
enum PanelTab { chat, log, leaderboard, admin, settings }

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
  });

  /// Content of the gear tab (voice, preferences, table actions).
  final Widget settings;

  final String tableId;

  /// The table's admin token when this device hosts the table.
  final String? adminToken;
  final PanelTab tab;
  final ValueChanged<PanelTab> onTabChanged;
  final FocusNode chatFocusNode;
  final ValueChanged<String> onSendChat;

  @override
  ConsumerState<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends ConsumerState<SidePanel> {
  /// The panel owns its tab so that it also works inside the bottom sheet,
  /// whose overlay does not rebuild with the page. [SidePanel.tab] is the
  /// initial tab and follows keyboard toggles from the page.
  late PanelTab _tab = widget.tab;

  @override
  void didUpdateWidget(covariant SidePanel old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) _tab = widget.tab;
    _markRead();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _select(PanelTab tab) {
    setState(() => _tab = tab);
    widget.onTabChanged(tab);
    _markRead();
  }

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
        n.markLogRead();
      case PanelTab.leaderboard:
      case PanelTab.admin:
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
    final tab = _tab == PanelTab.admin && adminToken == null
        ? PanelTab.chat
        : _tab;
    final visible = [
      PanelTab.chat,
      PanelTab.log,
      PanelTab.leaderboard,
      if (adminToken != null) PanelTab.admin,
      PanelTab.settings,
    ];
    final tabs = Tabs(
      index: visible.indexOf(tab),
      onChanged: (i) => _select(visible[i]),
      children: [
        TabItem(
          child: label(
            l10n.tabChat,
            tab == PanelTab.chat ? 0 : session.unreadChat,
          ),
        ),
        TabItem(
          child: label(
            l10n.tabLog,
            tab == PanelTab.log ? 0 : session.unreadLog,
          ),
        ),
        TabItem(child: Text(l10n.tabLeaderboard)),
        if (adminToken != null)
          TabItem(key: const Key('tab-admin'), child: Text(l10n.tabAdmin)),
        TabItem(
          key: const Key('tab-settings'),
          child: Tooltip(
            tooltip: TooltipContainer(child: Text(l10n.tabSettings)).call,
            child: const Icon(LucideIcons.settings, size: 16),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: tabs),
        const Gap(8),
        Expanded(
          child: switch (tab) {
            PanelTab.chat => ChatPanel(
              session: session,
              focusNode: widget.chatFocusNode,
              onSend: widget.onSendChat,
            ),
            PanelTab.log => HandLog(
              session: session,
              onReplay: session.snapshot == null ? null : _replay,
            ),
            PanelTab.leaderboard => TableLeaderboard(
              snapshot: session.snapshot,
            ),
            PanelTab.admin => AdminPanel(
              tableId: widget.tableId,
              token: adminToken!,
            ),
            PanelTab.settings => widget.settings,
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
  });

  final TableSessionState session;
  final FocusNode focusNode;
  final ValueChanged<String> onSend;

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
    final locale = Localizations.localeOf(context).toString();
    final mySeat = s.mySeat;
    final lines = <_ChatLine>[
      for (final m in s.chat)
        _ChatLine(
          ts: m.ts,
          text: m.text,
          author: m.authorName,
          kind: m.authorKind,
        ),
      for (final e in s.log)
        if (systemChatKinds.contains(e.event.kind))
          if (logLineText(l10n, e, mySeat: mySeat, locale: locale)
              case final text?)
            _ChatLine(ts: e.event.ts, text: text),
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
          child: ListView.builder(
            controller: _scroll,
            reverse: true,
            itemCount: lines.length,
            itemBuilder: (context, i) {
              final line = lines[lines.length - 1 - i];
              final isAdmin = line.kind == 'admin';
              final isSystem = line.author == null || line.kind == 'system';
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
                      ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                      : EdgeInsets.zero,
                  decoration: isAdmin
                      ? BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text.rich(
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
                                  color: theme.colorScheme.mutedForeground,
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
              const Gap(6),
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
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    (entries[i].place ?? 0) > 0
                        ? l10n.placeLabel(entries[i].place!)
                        : '${i + 1}.',
                    style: (entries[i].place ?? 0) > 0
                        ? muted.copyWith(fontWeight: FontWeight.w700)
                        : muted,
                  ),
                ),
                PlayerAvatar(index: avatars[entries[i].name] ?? 0, size: 28),
                const Gap(8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entries[i].name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Tooltip(
                            tooltip: TooltipContainer(
                              child: Text(l10n.lbHandsWon),
                            ).call,
                            child: Icon(
                              LucideIcons.trophy,
                              size: 11,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const Gap(3),
                          Text('${entries[i].handsWon}', style: muted),
                          const Gap(10),
                          Tooltip(
                            tooltip: TooltipContainer(
                              child: Text(l10n.lbBiggestPot),
                            ).call,
                            child: Icon(
                              LucideIcons.coins,
                              size: 11,
                              color: theme.colorScheme.mutedForeground,
                            ),
                          ),
                          const Gap(3),
                          Text(amount(entries[i].biggestPot), style: muted),
                          if ((entries[i].handsPlayed ?? 0) > 0) ...[
                            const Gap(10),
                            Tooltip(
                              tooltip: TooltipContainer(
                                child: Text(l10n.lbVpip),
                              ).call,
                              child: Icon(
                                LucideIcons.flame,
                                size: 11,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            const Gap(3),
                            Text(
                              '${(100 * (entries[i].vpipHands ?? 0) / entries[i].handsPlayed!).round()}%',
                              style: muted,
                            ),
                            const Gap(10),
                            Tooltip(
                              tooltip: TooltipContainer(
                                child: Text(l10n.lbShowdowns),
                              ).call,
                              child: Icon(
                                LucideIcons.swords,
                                size: 11,
                                color: theme.colorScheme.mutedForeground,
                              ),
                            ),
                            const Gap(3),
                            Text(
                              '${entries[i].showdownsWon ?? 0}/${entries[i].showdowns ?? 0}',
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
                      amount(entries[i].stack),
                      style: const TextStyle(fontFamily: 'GeistMono'),
                    ),
                    Text(
                      (entries[i].net > 0 ? '+' : '') + amount(entries[i].net),
                      style: TextStyle(
                        fontFamily: 'GeistMono',
                        fontSize: 11,
                        color: entries[i].net > 0
                            ? const Color(0xFF43A047)
                            : (entries[i].net < 0
                                  ? theme.colorScheme.destructive
                                  : theme.colorScheme.mutedForeground),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
