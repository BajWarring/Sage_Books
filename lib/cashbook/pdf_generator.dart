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

  // --- HEADER ---
  static pw.Widget _buildHeader(String name, String dateRange, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Using the passed name variable directly
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

  // --- SUMMARY CARDS ---
  static pw.Widget _buildSummaryCards(double totalIn, double totalOut, double net, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildCard("Total Cash In", totalIn, greenColor, greenLight, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Total Cash Out", totalOut, redColor, redLight, fontBold),
        pw.SizedBox(width: 10),
        _buildCard("Net Balance", net, primaryColor, PdfColor.fromInt(0xFFEEF2FF), fontBold, isNet: true),
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

  // --- ACTIVE FILTERS ---
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
    
    final data = <List<dynamic>>[];
    for (var e in entries) {
      final isInc = e['type'] == 'in';
      final amt = (e['amount'] as num).toDouble();
      if (isInc) runningBal += amt; else runningBal -= amt;
      data.add([e, isInc, amt, runningBal]); 
    }
    // Footer Marker
    data.add([null]); 

    return pw.TableHelper.fromTextArray(
      headers: ['DATE', 'REMARKS', 'CATEGORY', 'MODE', 'IN (+)', 'OUT (-)', 'BAL'],
      // COLUMN WIDTHS: Critical fix for text wrapping
      columnWidths: {
        0: const pw.FixedColumnWidth(55), // Date
        1: const pw.FlexColumnWidth(3),   // Remarks (Takes most space)
        2: const pw.FixedColumnWidth(55), // Category
        3: const pw.FixedColumnWidth(45), // Mode
        4: const pw.FixedColumnWidth(50), // In
        5: const pw.FixedColumnWidth(50), // Out
        6: const pw.FixedColumnWidth(55), // Balance
      },
      headerStyle: pw.TextStyle(font: fontBold, color: white, fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: primaryColor),
      headerAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.all(0), // Set to 0 to allow footer container to fill cell
      border: pw.TableBorder.all(color: greyColor, width: 0.5),
      cellAlignment: pw.Alignment.center,
      data: data.asMap().entries.map((entry) {
        final row = entry.value;

        // --- FOOTER ROW ---
        if (row[0] == null) {
          // Wrap content in a Colored Container to simulate Row Background
          pw.Widget footerCell(String text) {
             return pw.Container(
               color: primaryColor, // FOOTER COLOR FIX
               padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
               alignment: pw.Alignment.center,
               child: pw.Text(text, style: pw.TextStyle(font: fontBold, color: white, fontSize: 8))
             );
          }
          
          return [
            footerCell('TOTAL'),
            footerCell(''),
            footerCell(''),
            footerCell(''),
            footerCell(totalIn.toStringAsFixed(2)),
            footerCell(totalOut.toStringAsFixed(2)),
            footerCell(netBalance.toStringAsFixed(2)),
          ];
        }

        // --- NORMAL ROW ---
        final e = row[0] as Map<String, dynamic>;
        final isInc = row[1] as bool;
        final amt = row[2] as double;
        final bal = row[3] as double;
        final date = e['date'] as DateTime;
        final bgColor = entry.key % 2 == 1 ? lightGrey : white;

        pw.Widget cell(pw.Widget child) {
          return pw.Container(
            color: bgColor,
            padding: const pw.EdgeInsets.all(5),
            alignment: pw.Alignment.center,
            child: child
          );
        }

        return [
          cell(pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(DateFormat('dd/MM/yy').format(date), style: const pw.TextStyle(fontSize: 8, color: textColor)),
              pw.Text(DateFormat('h:mm a').format(date), style: const pw.TextStyle(fontSize: 6, color: greyColor)),
            ]
          )),
          cell(pw.Text(e['remarks'], textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9, color: textColor))),
          cell(pw.Text(e['category'] ?? '-', style: const pw.TextStyle(fontSize: 8, color: textColor))),
          cell(pw.Text(e['paymentMethod'] ?? '-', style: const pw.TextStyle(fontSize: 8, color: textColor))),
          cell(pw.Text(isInc ? amt.toStringAsFixed(2) : "", style: pw.TextStyle(fontSize: 9, color: greenColor, font: fontBold))),
          cell(pw.Text(!isInc ? amt.toStringAsFixed(2) : "", style: pw.TextStyle(fontSize: 9, color: redColor, font: fontBold))),
          cell(pw.Text(bal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8, color: textColor))),
        ];
      }).toList(),
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
      cellPadding: const pw.EdgeInsets.all(0),
      border: pw.TableBorder.all(color: greyColor, width: 0.5),
      cellAlignment: pw.Alignment.center,
      data: tableData.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;

        // Footer Row with Color
        if (row[0] == null) {
           pw.Widget footerCell(String text) {
             return pw.Container(
               color: primaryColor,
               padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
               alignment: pw.Alignment.center,
               child: pw.Text(text, style: pw.TextStyle(font: fontBold, color: white, fontSize: 8))
             );
           }
           return [
            footerCell('TOTAL'),
            footerCell(sumCount.toString()),
            footerCell(sumIn.toStringAsFixed(2)),
            footerCell(sumOut.toStringAsFixed(2)),
            footerCell(sumNet.toStringAsFixed(2)),
           ];
        }

        final bgColor = index % 2 == 1 ? lightGrey : white;
        pw.Widget cell(pw.Widget child) {
          return pw.Container(color: bgColor, padding: const pw.EdgeInsets.all(6), alignment: pw.Alignment.center, child: child);
        }

        return [
          cell(pw.Text(row[0] as String, style: const pw.TextStyle(fontSize: 9, color: textColor))),
          cell(pw.Text(row[1] as String, style: const pw.TextStyle(fontSize: 9, color: textColor))),
          cell(pw.Text((row[2] as double).toStringAsFixed(2), style: pw.TextStyle(color: greenColor, fontSize: 9, font: fontBold))),
          cell(pw.Text((row[3] as double).toStringAsFixed(2), style: pw.TextStyle(color: redColor, fontSize: 9, font: fontBold))),
          cell(pw.Text((row[4] as double).toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9, color: textColor))),
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
