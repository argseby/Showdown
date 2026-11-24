import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/standings.dart';
import '../../protocol/protocol.dart';

/// The words the export prints. They are handed in rather than read from a
/// localization here so the builder stays a pure function of its data — the
/// tests print a document without a widget tree.
class LeaderboardPdfTexts {
  const LeaderboardPdfTexts({
    required this.title,
    required this.generated,
    required this.allTime,
    required this.allTimeNote,
    required this.thisRound,
    required this.round,
    required this.hands,
    required this.noRounds,
    required this.colRank,
    required this.colPlayer,
    required this.colRounds,
    required this.colWins,
    required this.colNet,
    required this.colStack,
    required this.colHands,
    required this.colHandsWon,
    required this.colBiggestPot,
    required this.bot,
    required this.chartTitle,
    required this.biggestPot,
  });

  final String title;

  /// "Exported 19 Nov 2026, 21:04" — already formatted.
  final String generated;
  final String allTime;
  final String allTimeNote;
  final String thisRound;

  /// Takes the round's number: "Round 3".
  final String Function(int) round;

  /// Takes a count of hands: "34 hands".
  final String Function(int) hands;
  final String noRounds;
  final String colRank;
  final String colPlayer;
  final String colRounds;
  final String colWins;
  final String colNet;
  final String colStack;
  final String colHands;
  final String colHandsWon;
  final String colBiggestPot;
  final String bot;

  /// Heading of the chart of the board over the rounds.
  final String chartTitle;

  /// "Biggest pot 4,000: Alice, hand #31" from the amount (formatted), the
  /// winners (joined) and the hand number.
  final String Function(String amount, String names, int hand) biggestPot;
}

/// The chart colours, the same fixed categorical order as on screen.
const _seriesColors = [
  PdfColor.fromInt(0xFF2A78D6),
  PdfColor.fromInt(0xFFEB6834),
  PdfColor.fromInt(0xFF1BAF7A),
  PdfColor.fromInt(0xFFEDA100),
  PdfColor.fromInt(0xFFE87BA4),
  PdfColor.fromInt(0xFF008300),
];

/// Builds the leaderboard export: the all-time board first, then the round
/// that is being played, then every finished round newest first.
///
/// [standings] is the table's record as the server keeps it (null when it
/// could not be read, in which case only the live round is printed).
/// [current] is the live leaderboard from the snapshot, left empty when the
/// table sits ended — its standing is then the newest finished round.
Future<Uint8List> buildLeaderboardPdf({
  required String tableName,
  required TableStandings? standings,
  required List<LeaderboardEntry> current,
  required LeaderboardPdfTexts texts,
  required String Function(int) amount,
  required String Function(int) date,
}) {
  final doc = pw.Document(title: '${_safe(tableName)} - ${texts.title}');
  final rounds = [...?standings?.rounds]..sort((a, b) => b.index - a.index);
  final allTime = standings?.allTime ?? const <AllTimeEntry>[];

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                _safe(tableName),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Text(
          _safe(tableName),
          style: const pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          texts.title,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          texts.generated,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 16),

        // All time first: it is the answer to who is up at this table, and
        // the one thing a restart used to throw away.
        _heading(texts.allTime),
        pw.Text(
          texts.allTimeNote,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 6),
        if (allTime.isEmpty)
          _note(texts.noRounds)
        else
          _table(
            headers: [
              texts.colRank,
              texts.colPlayer,
              texts.colRounds,
              texts.colWins,
              texts.colNet,
              texts.colHands,
              texts.colHandsWon,
              texts.colBiggestPot,
            ],
            rows: [
              for (var i = 0; i < allTime.length; i++)
                [
                  '${i + 1}',
                  _name(allTime[i].name, bot: allTime[i].bot, texts: texts),
                  '${allTime[i].rounds}',
                  '${allTime[i].wins}',
                  _signed(allTime[i].net, amount),
                  '${allTime[i].handsPlayed}',
                  '${allTime[i].handsWon}',
                  amount(allTime[i].biggestPot),
                ],
            ],
          ),

        // The evening as a line per player: from the second finished round
        // on there is something to draw.
        if (allTime.isNotEmpty && rounds.length >= 2) ...[
          pw.SizedBox(height: 14),
          _heading(texts.chartTitle),
          pw.SizedBox(height: 6),
          _netChart(allTime, [
            for (final r in rounds.reversed) r.index,
          ], amount),
        ],

        if (current.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          _heading(texts.thisRound),
          pw.SizedBox(height: 6),
          _roundTable(current, texts: texts, amount: amount),
        ],

        for (final r in rounds) ...[
          pw.SizedBox(height: 18),
          _heading(
            '${texts.round(r.index)} - ${texts.hands(r.hands)} - ${date(r.endedAt)}',
          ),
          if (r.biggestPot case final best?)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: _note(
                [
                  texts.biggestPot(
                    amount(best.amount),
                    _safe(best.winners.join(', ')),
                    best.hand,
                  ),
                  if (best.description.isNotEmpty) _safe(best.description),
                ].join(' - '),
              ),
            ),
          pw.SizedBox(height: 6),
          _roundTable(r.standings, texts: texts, amount: amount),
        ],
      ],
    ),
  );
  return doc.save();
}

/// The running net of the leading players over [rounds] (ascending).
pw.Widget _netChart(
  List<AllTimeEntry> allTime,
  List<int> rounds,
  String Function(int) amount,
) {
  final series = netSeries(allTime, rounds, top: _seriesColors.length);
  var lo = 0, hi = 0;
  for (final s in series) {
    for (final p in s.points) {
      if (p == null) continue;
      if (p < lo) lo = p;
      if (p > hi) hi = p;
    }
  }
  if (lo == hi) hi = lo + 1;
  final ticks = _niceTicks(lo, hi);
  return pw.SizedBox(
    height: 170,
    child: pw.Chart(
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis<int>(
          [for (var i = 0; i < rounds.length; i++) i],
          buildLabel: (v) => pw.Text(
            '${rounds[v.toInt()]}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          divisions: false,
          ticks: true,
        ),
        yAxis: pw.FixedAxis<int>(
          ticks,
          format: (v) => _safe(amount(v.toInt())),
          textStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          divisions: true,
          divisionsColor: PdfColors.grey300,
        ),
      ),
      datasets: [
        for (var s = 0; s < series.length; s++)
          pw.LineDataSet(
            legend: _safe(series[s].name),
            color: _seriesColors[s],
            lineWidth: 1.5,
            pointSize: 2.5,
            data: [
              for (var i = 0; i < rounds.length; i++)
                if (series[s].points[i] != null)
                  pw.PointChartValue(
                    i.toDouble(),
                    series[s].points[i]!.toDouble(),
                  ),
            ],
          ),
      ],
      bottom: pw.ChartLegend(
        direction: pw.Axis.horizontal,
        position: pw.Alignment.center,
        textStyle: const pw.TextStyle(fontSize: 8),
      ),
    ),
  );
}

/// Round axis values from [lo] to [hi], zero among them, about five steps.
List<int> _niceTicks(int lo, int hi) {
  final raw = (hi - lo) / 5;
  var step = 1;
  while (step * 10 <= raw) {
    step *= 10;
  }
  for (final m in const [1, 2, 5, 10]) {
    if (step * m >= raw) {
      step *= m;
      break;
    }
  }
  final from = (lo / step).floor() * step;
  final to = (hi / step).ceil() * step;
  return [for (var v = from; v <= to; v += step) v];
}

pw.Widget _heading(String text) => pw.Text(
  text,
  style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
);

pw.Widget _note(String text) => pw.Text(
  text,
  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
);

pw.Widget _roundTable(
  List<LeaderboardEntry> entries, {
  required LeaderboardPdfTexts texts,
  required String Function(int) amount,
}) => _table(
  headers: [
    texts.colRank,
    texts.colPlayer,
    texts.colStack,
    texts.colNet,
    texts.colHands,
    texts.colHandsWon,
    texts.colBiggestPot,
  ],
  rows: [
    for (var i = 0; i < entries.length; i++)
      [
        '${(entries[i].place ?? 0) > 0 ? entries[i].place : i + 1}',
        _safe(entries[i].name),
        amount(entries[i].stack),
        _signed(entries[i].net, amount),
        '${entries[i].handsPlayed ?? 0}',
        '${entries[i].handsWon}',
        amount(entries[i].biggestPot),
      ],
  ],
);

pw.Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
}) => pw.TableHelper.fromTextArray(
  headers: headers,
  data: rows,
  border: null,
  headerStyle: const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
  cellStyle: const pw.TextStyle(fontSize: 9),
  oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
  headerAlignment: pw.Alignment.centerLeft,
  cellAlignment: pw.Alignment.centerRight,
  cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
  columnWidths: {1: const pw.FlexColumnWidth(3)},
);

String _name(
  String name, {
  required bool bot,
  required LeaderboardPdfTexts texts,
}) => bot ? '${_safe(name)} (${texts.bot})' : _safe(name);

String _signed(int net, String Function(int) amount) =>
    net > 0 ? '+${amount(net)}' : amount(net);

/// The built-in Helvetica of a PDF can only draw Latin-1, and asking it for
/// anything else throws. Player names are free text — emoji and non-Latin
/// scripts included — so everything outside that range becomes a question
/// mark rather than taking the whole export down.
String _safe(String s) {
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r == 0x0a || r == 0x0d || r == 0x09) {
      out.write(' ');
    } else if (r < 0x20 || (r > 0x7e && r < 0xa0) || r > 0xff) {
      out.write('?');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}
