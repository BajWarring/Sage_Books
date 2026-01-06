import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfGenerator {
  // --- COLORS ---
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF4F46E5); 
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFEEF2FF); 
  static const PdfColor greenColor = PdfColor.fromInt(0xFF059669);   
  static const PdfColor greenLight = PdfColor.fromInt(0xFFECFDF5);   
  static const PdfColor redColor = PdfColor.fromInt(0xFFE11D48);     
  static const PdfColor redLight = PdfColor.fromInt(0xFFFFF1F2);     
  static const PdfColor textColor = PdfColor.fromInt(0xFF1E293B);    
  static const PdfColor greyColor = PdfColor.fromInt(0xFF94A3B8);    
  static const PdfColor lightGrey = PdfColor.fromInt(0xFFF1F5F9);    
  static const PdfColor white = PdfColors.white;

  static Future<File> generateReport({
    required String cashbookName,
    required List<Map<String, dynamic>> entries,
    required String reportType,
    required Map<String, String> filters,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    // 1. CALCULATE TOTALS & SORT
    double totalIn = 0;
    double totalOut = 0;
    entries.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    for (var e in entries) {
      if (e['type'] == 'in') totalIn += (e['amount'] as num).toDouble(); 
      else totalOut += (e['amount'] as num).toDouble();
    }
    double netBalance = totalIn - totalOut;

    // 2. DATE RANGE
    String dateRangeStr = "No Entries";
    if (entries.isNotEmpty) {
      final start = entries.first['date'] as DateTime; 
      final end = entries.last['date'] as DateTime;
      dateRangeStr = "${DateFormat('MMM d, y').format(start)} - ${DateFormat('MMM d, y').format(end)}";
    }

    // 3. CLEAN FILTERS
    final cleanedFilters = Map<String, String>.from(filters);
    cleanedFilters.removeWhere((key, value) => 
      value == "All" || value == "None" || value == "Newest" || value == "Oldest"
    );

    // 4. BUILD PAGE
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(cashbookName, dateRangeStr, fontBold),
          pw.SizedBox(height: 12),
          pw.Divider(color: greyColor, thickness: 0.5),
          pw.SizedBox(height: 12),
          _buildSummaryCards(totalIn, totalOut, netBalance, fontBold),
          pw.SizedBox(height: 20),
          if (cleanedFilters.isNotEmpty) ...[
            _buildActiveFilters(cleanedFilters, fontBold),
            pw.SizedBox(height: 20),
          ],
          
          if (entries.isEmpty)
            pw.Center(child: pw.Text("No entries found for this period.", style: const pw.TextStyle(color: greyColor)))
          else if (reportType == 'all') 
            _buildAllEntriesTable(entries, fontBold, totalIn, totalOut, netBalance)
          else 
            _buildGroupedTable(entries, reportType, fontBold),
            
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
            pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 22, color: primaryColor)),
            pw.SizedBox(height: 4),
            pw.Text("OFFICIAL REPORT", style: pw.TextStyle(font: fontBold, fontSize: 9, color: greyColor, letterSpacing: 1.5)),
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
        _buildCard("Total Cash In", totalIn, greenColor, greenLight, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Total Cash Out", totalOut, redColor, redLight, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Net Balance", net, primaryColor, primaryLight, fontBold, isNet: true),
      ],
    );
  }

  static pw.Widget _buildCard(String label, double amount, PdfColor fg, PdfColor bg, pw.Font fontBold, {bool isNet = false}) {
    String prefix = isNet ? (amount >= 0 ? '+' : '-') : '';
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: fg, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 8, color: fg)),
            pw.SizedBox(height: 4),
            pw.Text(
              "$prefix ${amount.abs().toStringAsFixed(2)}",
              style: pw.TextStyle(font: fontBold, fontSize: 14, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT: FILTERS ---
  static pw.Widget _buildActiveFilters(Map<String, String> filters, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: lightGrey, borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Wrap(
        spacing: 12,
        runSpacing: 4,
        children: filters.entries.map((e) {
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
  static pw.Widget _buildAllEntriesTable(List<Map<String, dynamic>> entries, pw.Font fontBold, double totalIn, double totalOut, double netBalance) {
    double runningBal = 0;
    
    // Prepare data
    final data = <List<dynamic>>[];
    for (var e in entries) {
      final date = e['date'] as DateTime;
      final isInc = e['type'] == 'in';
      final amt = (e['amount'] as num).toDouble();
      if (isInc) runningBal += amt; else runningBal -= amt;

      // Add data to be processed by cell builder
      data.add([e, isInc, amt, runningBal]); 
    }

    // Add Footer Data Marker
    data.add([null, false, 0.0, 0.0]); 

    return pw.TableHelper.fromTextArray(
      headers: ['DATE', 'REMARKS', 'CATEGORY', 'MODE', 'IN (+)', 'OUT (-)', 'BALANCE'],
      headerStyle: pw.TextStyle(font: fontBold, color: white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(6), // Replaced headerCellPadding with cellPadding
      border: pw.TableBorder.all(color: greyColor, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
      cellAlignment: pw.Alignment.center,
      data: data.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;

        // FOOTER ROW
        if (row[0] == null) {
          return [
            'TOTAL', '', '', '', 
            totalIn.toStringAsFixed(2), 
            totalOut.toStringAsFixed(2), 
            netBalance.toStringAsFixed(2)
          ];
        }

        // NORMAL ROWS
        final e = row[0] as Map<String, dynamic>;
        final isInc = row[1] as bool;
        final amt = row[2] as double;
        final bal = row[3] as double;
        final date = e['date'] as DateTime;

        return [
          // Date with Time
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(DateFormat('dd/MM/yy').format(date), style: const pw.TextStyle(fontSize: 9, color: textColor)),
              pw.Text(DateFormat('h:mm a').format(date), style: const pw.TextStyle(fontSize: 7, color: greyColor)),
            ]
          ),
          e['remarks'],
          e['category'] ?? '-',
          e['paymentMethod'] ?? '-',
          // Green Text for In
          pw.Text(isInc ? amt.toStringAsFixed(2) : "", style: pw.TextStyle(fontSize: 9, color: greenColor, font: fontBold)),
          // Red Text for Out
          pw.Text(!isInc ? amt.toStringAsFixed(2) : "", style: pw.TextStyle(fontSize: 9, color: redColor, font: fontBold)),
          bal.toStringAsFixed(2),
        ];
      }).toList(),
      // Custom Row Styling for Footer
      rowDecoration: const pw.BoxDecoration(color: white),
    );
  }

  // --- TABLE: GROUPED ---
  static pw.Widget _buildGroupedTable(List<Map<String, dynamic>> entries, String type, pw.Font fontBold) {
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

    List<List<dynamic>> tableData = [];
    double sumIn = 0, sumOut = 0, sumNet = 0;
    int sumCount = 0;

    groups.forEach((key, val) {
      double net = val['in']! - val['out']!;
      sumIn += val['in']!; sumOut += val['out']!; sumNet += net; sumCount += val['count']!.toInt();
      tableData.add([key, val['count']!.toInt().toString(), val['in']!, val['out']!, net]);
    });

    tableData.add([null]); // Footer marker

    String firstCol = type.toUpperCase();
    if(type == 'day') firstCol = "DATE";
    if(type == 'month') firstCol = "MONTH";

    return pw.TableHelper.fromTextArray(
      headers: [firstCol, 'ENTRIES', 'TOTAL IN', 'TOTAL OUT', 'NET'],
      headerStyle: pw.TextStyle(font: fontBold, color: white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(6),
      border: pw.TableBorder.all(color: greyColor, width: 0.5),
      oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
      cellAlignment: pw.Alignment.center,
      data: tableData.map((row) {
        if (row[0] == null) {
          return [
            'TOTAL', 
            sumCount.toString(), 
            sumIn.toStringAsFixed(2), 
            sumOut.toStringAsFixed(2), 
            sumNet.toStringAsFixed(2)
          ];
        }
        return [
          row[0], 
          row[1], 
          // Green In
          pw.Text((row[2] as double).toStringAsFixed(2), style: pw.TextStyle(color: greenColor, fontSize: 9)),
          // Red Out
          pw.Text((row[3] as double).toStringAsFixed(2), style: pw.TextStyle(color: redColor, fontSize: 9)),
          (row[4] as double).toStringAsFixed(2)
        ];
      }).toList(),
    );
  }

  // --- SAVE ---
  static Future<File> _savePdfFile(String name, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final cleanName = name.replaceAll(' ', '_');
    final file = File('${dir.path}/${cleanName}_Report.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
  
  static Future<void> saveToDownloads(File tempFile, String fileName) async {
    if (!await Permission.storage.request().isGranted) {} 
    Directory? downloadsDir;
    if (Platform.isAndroid) downloadsDir = Directory('/storage/emulated/0/Download');
    else downloadsDir = await getApplicationDocumentsDirectory();

    if (downloadsDir != null) {
      if (!await downloadsDir.exists()) await downloadsDir.create(recursive: true);
      String finalName = fileName.endsWith('.pdf') ? fileName : "$fileName.pdf";
      final newFile = File("${downloadsDir.path}/$finalName");
      await tempFile.copy(newFile.path);
    }
  }
}
