// ─────────────────────────────────────────────────────────
// TadbeerAI — PDF Export Service
// Generates a comprehensive enterprise report for Judges
// ─────────────────────────────────────────────────────────

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/tadbeer_models.dart';
import 'package:intl/intl.dart';

class PdfExportService {
  static Future<void> generateAndSharePdf(
    InsightResult insight,
    SimulationResult sim,
  ) async {
    final doc = pw.Document();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    // Main Report Page
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return [
            _buildHeader(now),
            pw.SizedBox(height: 20),

            // 1. INSIGHT
            _buildSectionTitle('1. Trigger Event & Insight'),
            pw.Text(
              insight.insightTitle,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Confidence: ${(insight.confidence * 100).toInt()}% — ${insight.confidenceReason}',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 16),

            // 2. IMPACT
            _buildSectionTitle('2. Business Impact (Agent 4)'),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              data: <List<String>>[
                ['Factor', 'Value', 'Severity'],
                ...insight.impacts.map(
                  (i) => [
                    i.description,
                    i.quantified ?? '-',
                    i.severity.toUpperCase()
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 3. STATE CHANGES (SIMULATION)
            _buildSectionTitle('3. Simulated Execution (Agent 6)'),
            pw.Text(
              'Action Taken: Simulated the highest-ranked action resulting in ${sim.stateChanges} state changes.',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              context: context,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue100,
              ),
              data: <List<String>>[
                ['System Node', 'Before', 'After'],
                ...sim.diffs.map((d) => [d.field, d.before, d.after]),
              ],
            ),
            pw.SizedBox(height: 20),

            // 4. GENERATED ARTIFACTS
            _buildSectionTitle('4. Autonomous Communications'),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SMS Drafted for ${sim.usersReached} customers:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    sim.smsDraft,
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 5. AGENT TRACE
            _buildSectionTitle('5. Antigravity Agent Trace'),
            ...insight.agentTrace.map(
              (step) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '[${step.agentName}]',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                          'Agent ${step.agentNumber} · ${step.durationSeconds}s'),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Trigger standard native share sheet / print dialog
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'TadbeerAI_Execution_Report.pdf',
    );
  }

  static pw.Widget _buildHeader(String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'TadbeerAI',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.Text(
              'Autonomous Agent Execution Report',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
            ),
          ],
        ),
        pw.Text(
          'Timestamp: $date',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }
}
