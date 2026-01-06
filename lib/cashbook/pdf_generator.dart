import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class PdfGenerator {
  
  static Future<File> generateReport({
    required String cashbookName,
    required List<Map<String, dynamic>> entries,
    required String reportType, // 'all', 'day', 'month', 'category', 'payment'
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, String> filters,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    // Calculate Grand Totals
    double totalIn = 0;
    double totalOut = 0;
    for (var e in entries) {
      if (e['type'] == 'in') totalIn += e['amount']; else totalOut += e['amount'];
    }
    double netBalance = totalIn - totalOut;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (context) => [
          // HEADER
          _buildHeader(cashbookName, startDate, endDate, netBalance, fontBold),
          pw.SizedBox(height: 20),
          
          // FILTERS USED
          _buildFilterSummary(filters, fontBold),
          pw.SizedBox(height: 20),

          // TABLE CONTENT (Based on Report Type)
          if (reportType == 'all') _buildAllEntriesTable(entries, fontBold),
          if (reportType == 'day') _buildGroupedTable(entries, 'day', fontBold),
          if (reportType == 'month') _buildGroupedTable(entries, 'month', fontBold),
          if (reportType == 'category') _buildGroupedTable(entries, 'category', fontBold),
          if (reportType == 'payment') _buildGroupedTable(entries, 'payment', fontBold),
        ],
      ),
    );

    return _savePdfFile(cashbookName, pdf);
  }

  // --- 1. HEADER ---
  static pw.Widget _buildHeader(String name, DateTime start, DateTime end, double balance, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name, style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.indigo900)),
            pw.Text("${DateFormat('MMM d, y').format(start)} - ${DateFormat('MMM d, y').format(end)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text("Net Balance", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Text(
              "${balance >= 0 ? '+' : '-'} ${balance.abs().toStringAsFixed(2)}",
              style: pw.TextStyle(font: fontBold, fontSize: 18, color: balance >= 0 ? PdfColors.green700 : PdfColors.red700),
            ),
          ],
        )
      ],
    );
  }

  // --- 2. FILTER SUMMARY ---
  static pw.Widget _buildFilterSummary(Map<String, String> filters, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Wrap(
        spacing: 12,
        children: filters.entries.map((e) {
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text("${e.key}: ", style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600)),
              pw.Text(e.value, style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- 3. ALL ENTRIES TABLE ---
  static pw.Widget _buildAllEntriesTable(List<Map<String, dynamic>> entries, pw.Font fontBold) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date', 'Remarks', 'Category', 'Mode', 'Cash In', 'Cash Out'],
      border: null,
      headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.all(6),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      data: entries.map((e) {
        final date = (e['date'] as DateTime); // Already parsed in main page
        final isInc = e['type'] == 'in';
        return [
          DateFormat('MMM d, h:mm a').format(date),
          e['remarks'],
          e['category'],
          e['paymentMethod'],
          isInc ? e['amount'].toStringAsFixed(2) : "-",
          !isInc ? e['amount'].toStringAsFixed(2) : "-",
        ];
      }).toList(),
    );
  }

  // --- 4. GROUPED TABLE (Day, Month, Category, Payment) ---
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
      
      if (e['type'] == 'in') groups[key]!['in'] = groups[key]!['in']! + e['amount'];
      else groups[key]!['out'] = groups[key]!['out']! + e['amount'];
      
      groups[key]!['count'] = groups[key]!['count']! + 1;
    }

    // 2. Build Table
    return pw.TableHelper.fromTextArray(
      headers: [type.toUpperCase(), 'Entries', 'Total In', 'Total Out', 'Net Balance'],
      border: null,
      headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo600),
      cellStyle: const pw.TextStyle(fontSize: 10),
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      data: groups.entries.map((entry) {
        double net = entry.value['in']! - entry.value['out']!;
        return [
          entry.key,
          entry.value['count']!.toInt().toString(),
          entry.value['in']!.toStringAsFixed(2),
          entry.value['out']!.toStringAsFixed(2),
          net.toStringAsFixed(2),
        ];
      }).toList(),
    );
  }

  // --- SAVE FILE ---
  static Future<File> _savePdfFile(String name, pw.Document pdf) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${name}_Report.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
  
  // --- DOWNLOAD TO PUBLIC FOLDER ---
  static Future<void> saveToDownloads(File tempFile, String cashbookName) async {
    // 1. Request Permission
    if (!await Permission.storage.request().isGranted) return;

    // 2. Get Downloads Path (Android/iOS logic)
    Directory? downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory(); // iOS logic usually shares via UI
    }

    if (downloadsDir != null) {
      final now = DateTime.now();
      final fileName = "${cashbookName.replaceAll(' ', '_')}_${now.day}_${now.month}_${now.year}.pdf";
      final newFile = File("${downloadsDir.path}/$fileName");
      await tempFile.copy(newFile.path);
    }
  }
}
