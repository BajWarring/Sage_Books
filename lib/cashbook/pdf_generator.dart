import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfGenerator {
  // --- COLORS ---
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF4F46E5); // Indigo 600
  static const PdfColor accentColor = PdfColor.fromInt(0xFFEEF2FF); // Indigo 50
  static const PdfColor textColor = PdfColor.fromInt(0xFF1E293B);   // Slate 800
  static const PdfColor greyColor = PdfColor.fromInt(0xFF94A3B8);   // Slate 400
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF1F5F9);   // Slate 100
  static const PdfColor greenColor = PdfColor.fromInt(0xFF059669);  // Emerald 600
  static const PdfColor redColor = PdfColor.fromInt(0xFFE11D48);    // Rose 600

  static Future<File> generateReport({
    required String cashbookName,
    required List<Map<String, dynamic>> entries,
    required String reportType,
    required Map<String, String> filters,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    // 1. CALCULATE TOTALS
    double totalIn = 0;
    double totalOut = 0;
    
    // Sort entries by date (Oldest first) for correct range display
    entries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    for (var e in entries) {
      if (e['type'] == 'in') totalIn += (e['amount'] as num).toDouble(); 
      else totalOut += (e['amount'] as num).toDouble();
    }
    double netBalance = totalIn - totalOut;

    // 2. DETERMINE REAL DATE RANGE
    String dateRangeStr = "No Entries";
    if (entries.isNotEmpty) {
      final start = entries.first['date'] as DateTime; // Oldest
      final end = entries.last['date'] as DateTime;   // Newest
      dateRangeStr = "${DateFormat('MMM d, y').format(start)} - ${DateFormat('MMM d, y').format(end)}";
    }

    // 3. BUILD PAGE
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // HEADER
          _buildHeader(cashbookName, dateRangeStr, fontBold),
          pw.SizedBox(height: 12),
          pw.Divider(color: greyColor, thickness: 0.5),
          pw.SizedBox(height: 12),

          // SUMMARY CARDS
          _buildSummaryCards(totalIn, totalOut, netBalance, fontBold),
          pw.SizedBox(height: 20),

          // ACTIVE FILTERS
          _buildActiveFilters(filters, fontBold),
          pw.SizedBox(height: 20),

          // TABLE (Based on Report Type)
          if (entries.isEmpty)
            pw.Center(child: pw.Text("No entries found for this period.", style: const pw.TextStyle(color: greyColor)))
          else if (reportType == 'all') 
            _buildAllEntriesTable(entries, fontBold, totalIn, totalOut)
          else 
            _buildGroupedTable(entries, reportType, fontBold),
          
          // FOOTER NOTE
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("Generated on ${DateFormat('MMMM d, y • h:mm a').format(DateTime.now())}", style: const pw.TextStyle(fontSize: 9, color: greyColor)),
          ),
        ],
      ),
    );

    return _savePdfFile(cashbookName, pdf);
  }

  // --- COMPONENT: HEADER ---
  static pw.Widget _buildHeader(String name, String dateRange, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("CASHBOOK REPORT", style: pw.TextStyle(font: fontBold, fontSize: 10, color: greyColor, letterSpacing: 1.5)),
            pw.SizedBox(height: 4),
            pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 22, color: primaryColor)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("PERIOD", style: pw.TextStyle(font: fontBold, fontSize: 9, color: greyColor)),
            pw.Text(dateRange, style: pw.TextStyle(font: fontBold, fontSize: 11, color: textColor)),
          ],
        )
      ],
    );
  }

  // --- COMPONENT: SUMMARY CARDS ---
  static pw.Widget _buildSummaryCards(double totalIn, double totalOut, double net, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildCard("Total Cash In", totalIn, greenColor, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Total Cash Out", totalOut, redColor, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Net Balance", net, primaryColor, fontBold, isNet: true),
      ],
    );
  }

  static pw.Widget _buildCard(String label, double amount, PdfColor color, pw.Font fontBold, {bool isNet = false}) {
    String prefix = isNet ? (amount >= 0 ? '+' : '-') : '';
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: color.withOpacity(0.2)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 8, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(
              "$prefix ${amount.abs().toStringAsFixed(2)}",
              style: pw.TextStyle(font: fontBold, fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT: FILTERS ---
  static pw.Widget _buildActiveFilters(Map<String, String> filters, pw.Font fontBold) {
    final activeFilters = filters.entries.where((e) => e.value != "All" && e.value != "None" && e.value != "Newest").toList();
    
    if (activeFilters.isEmpty) return pw.SizedBox();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: lightGrey, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 4,
        children: activeFilters.map((e) {
          return pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(text: "${e.key}: ", style: pw.TextStyle(font: fontBold, fontSize: 9, color: greyColor)),
                pw.TextSpan(text: e.value, style: const pw.TextStyle(fontSize: 9, color: textColor)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- TABLE: ALL ENTRIES ---
  static pw.Widget _buildAllEntriesTable(List<Map<String, dynamic>> entries, pw.Font fontBold, double totalIn, double totalOut) {
    // Reverse for display (Newest First) if preferred, but usually reports are chronological. 
    // Let's stick to the sort order passed (which we sorted ASC for date range). 
    // To match "Newest" filter preference, we might need to reverse here.
    // However, chronological (Old -> New) is standard for ledgers. We will keep Old -> New.

    final headerStyle = pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9);
    
    return pw.TableHelper.fromTextArray(
      headers: ['DATE', 'REMARKS', 'CATEGORY', 'MODE', 'IN (+)', 'OUT (-)'],
      headerStyle: headerStyle,
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9, color: textColor),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: pw.TableBorder.all(color: greyColor.withOpacity(0.2), width: 0.5),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
      data: [
        ...entries.map((e) {
          final date = e['date'] as DateTime;
          final isInc = e['type'] == 'in';
          return [
            DateFormat('dd/MM/yy').format(date),
            e['remarks'],
            e['category'] ?? '-',
            e['paymentMethod'] ?? '-',
            isInc ? e['amount'].toStringAsFixed(2) : "",
            !isInc ? e['amount'].toStringAsFixed(2) : "",
          ];
        }).toList(),
        // FOOTER ROW
        ['TOTAL', '', '', '', totalIn.toStringAsFixed(2), totalOut.toStringAsFixed(2)]
      ],
      // Style the last row (Footer)
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: greyColor))),
    );
  }

  // --- TABLE: GROUPED (Day, Month, Category, Payment) ---
  static pw.Widget _buildGroupedTable(List<Map<String, dynamic>> entries, String type, pw.Font fontBold) {
    // 1. Group Data
    Map<String, Map<String, double>> groups = {};
    
    for (var e in entries) {
      String key = "";
      DateTime date = e['date'];
      
      if (type == 'day') key = DateFormat('MMM d, y').format(date);
      else if (type == 'month') key = DateFormat('MMMM y').format(date);
      else if (type == 'category') key = e['category'] ?? 'Uncategorized';
      else if (type == 'payment') key = e['paymentMethod'] ?? 'Unknown';

      if (!groups.containsKey(key)) groups[key] = {'in': 0.0, 'out': 0.0, 'count': 0};
      
      if (e['type'] == 'in') groups[key]!['in'] = groups[key]!['in']! + (e['amount'] as num).toDouble();
      else groups[key]!['out'] = groups[key]!['out']! + (e['amount'] as num).toDouble();
      
      groups[key]!['count'] = groups[key]!['count']! + 1;
    }

    // 2. Prep Data & Totals
    List<List<String>> tableData = [];
    double sumIn = 0;
    double sumOut = 0;
    double sumNet = 0;
    int sumCount = 0;

    groups.forEach((key, val) {
      double net = val['in']! - val['out']!;
      sumIn += val['in']!;
      sumOut += val['out']!;
      sumNet += net;
      sumCount += val['count']!.toInt();

      tableData.add([
        key,
        val['count']!.toInt().toString(),
        val['in']!.toStringAsFixed(2),
        val['out']!.toStringAsFixed(2),
        net.toStringAsFixed(2),
      ]);
    });

    // 3. Add Footer Row
    tableData.add([
      "TOTAL",
      sumCount.toString(),
      sumIn.toStringAsFixed(2),
      sumOut.toStringAsFixed(2),
      sumNet.toStringAsFixed(2)
    ]);

    String firstColHeader = type.toUpperCase();
    if(type == 'day') firstColHeader = "DATE";
    if(type == 'month') firstColHeader = "MONTH";

    return pw.TableHelper.fromTextArray(
      headers: [firstColHeader, 'ENTRIES', 'TOTAL IN', 'TOTAL OUT', 'NET'],
      headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      cellStyle: const pw.TextStyle(fontSize: 9, color: textColor),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: pw.TableBorder.all(color: greyColor.withOpacity(0.2), width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
      data: tableData,
    );
  }

  // --- SAVE UTILS ---
  static Future<File> _savePdfFile(String name, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final cleanName = name.replaceAll(' ', '_');
    final file = File('${dir.path}/${cleanName}_Report.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
  
  static Future<void> saveToDownloads(File tempFile, String cashbookName) async {
    if (!await Permission.storage.request().isGranted) {
        // Android 11+ might return denied but still allow access to public media directories
        // Keep checking logic for older androids
    }

    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }

    if (downloadsDir != null) {
      if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
      
      final now = DateTime.now();
      // Format: CashbookName_dd_MM_yyyy.pdf
      final fileName = "${cashbookName.replaceAll(' ', '_')}_${DateFormat('dd_MM_yyyy').format(now)}.pdf";
      final newFile = File("${downloadsDir.path}/$fileName");
      await tempFile.copy(newFile.path);
    }
  }
}
