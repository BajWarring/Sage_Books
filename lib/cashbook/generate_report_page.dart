import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart'; 
import 'package:sage_books/cashbook/pdf_generator.dart'; 

class GenerateReportPage extends StatefulWidget {
  final User user;
  final String cashbookId;
  final String cashbookName;

  const GenerateReportPage({
    super.key, 
    required this.user, 
    required this.cashbookId,
    this.cashbookName = "Cashbook", 
  });

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  // State
  String _filterDate = "All Time";
  String _filterType = "All";
  String _filterCategory = "All";
  String _filterPayment = "All";
  String _filterSort = "Newest";
  String _filterSearch = "None";
  String _reportType = "all"; 

  bool _isLoadingReport = false;
  File? _generatedPdfFile;
  
  // Date Range
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;
  bool _showDateInputs = false; 

  List<String> _categories = [];
  List<String> _paymentMethods = [];
  bool _isLoadingMeta = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    final docs = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').doc(widget.cashbookId).collection('entries').get();
    Set<String> catSet = {};
    Set<String> paySet = {};
    for (var doc in docs.docs) {
      if (doc.data().containsKey('category')) catSet.add(doc['category']);
      if (doc.data().containsKey('paymentMethod')) paySet.add(doc['paymentMethod']);
    }
    if (mounted) {
      setState(() {
        _categories = catSet.toList()..sort();
        _paymentMethods = paySet.toList()..sort();
        _isLoadingMeta = false;
      });
    }
  }

  // --- ACTIONS ---

  void _generateReport() async {
    setState(() => _isLoadingReport = true);

    try {
      Query query = FirebaseFirestore.instance.collection('users')
          .doc(widget.user.uid)
          .collection('cashbooks')
          .doc(widget.cashbookId)
          .collection('entries');

      DateTime now = DateTime.now();
      DateTime start = DateTime(2000); 
      DateTime end = DateTime(2100);

      if (_filterDate == "Last Week") start = now.subtract(const Duration(days: 7));
      if (_filterDate == "Last Month") start = DateTime(now.year, now.month - 1, now.day);
      if (_filterDate == "Last Year") start = DateTime(now.year - 1, now.month, now.day);
      if (_startDate != null) { start = _startDate!; end = _endDate!; }

      final snapshot = await query.orderBy('date', descending: _filterSort == 'Newest').get();
      
      List<Map<String, dynamic>> finalEntries = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['date'] = (data['date'] as Timestamp).toDate(); 

        DateTime date = data['date'];
        if (date.isBefore(start) || date.isAfter(end)) continue;
        if (_filterType != "All") {
           String type = _filterType == "Cash In" ? 'in' : 'out';
           if (data['type'] != type) continue;
        }
        if (_filterCategory != "All" && data['category'] != _filterCategory) continue;
        if (_filterPayment != "All" && data['paymentMethod'] != _filterPayment) continue;
        if (_filterSearch != "None") {
           String term = _filterSearch.toLowerCase();
           bool match = data['remarks'].toString().toLowerCase().contains(term) ||
                        data['category'].toString().toLowerCase().contains(term);
           if (!match) continue;
        }
        finalEntries.add(data);
      }

      File file = await PdfGenerator.generateReport(
        cashbookName: widget.cashbookName, // Passing REAL name
        entries: finalEntries,
        reportType: _reportType,
        filters: {
          'Type': _filterType,
          'Category': _filterCategory,
          'Payment': _filterPayment,
          'Search': _filterSearch,
        },
      );

      _generatedPdfFile = file;
      await Future.delayed(const Duration(seconds: 2)); 

      if (mounted) setState(() => _isLoadingReport = false);
      if (mounted) _showSuccessModal();

    } catch (e) {
      if (mounted) setState(() => _isLoadingReport = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- SAVE DIALOG ---
  void _showSaveDialog() {
    TextEditingController nameCtrl = TextEditingController(text: "${widget.cashbookName}_Report");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Save Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter a name for your file:", style: GoogleFonts.outfit(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixText: ".pdf",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_generatedPdfFile != null && nameCtrl.text.isNotEmpty) {
                await PdfGenerator.saveToDownloads(_generatedPdfFile!, nameCtrl.text);
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close Success Modal
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved to Downloads!")));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text("Save", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 6, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
            Container(width: 64, height: 64, decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle), child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: const Color(0xFF059669), size: 32)),
            const SizedBox(height: 16),
            Text("Report Ready!", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text("Your PDF has been generated successfully.", style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () { 
                  if (_generatedPdfFile != null) OpenFile.open(_generatedPdfFile!.path);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(PhosphorIcons.eye(PhosphorIconsStyle.bold), color: Colors.white),
                label: Text("See Preview", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _showSaveDialog, 
                style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold), color: const Color(0xFF334155)),
                label: Text("Save To Downloads", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ANIMATED GRID LAYOUT ---
  Widget _buildAnimatedGrid() {
    bool isHidden = _reportType == 'category' || _reportType == 'payment';

    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;
        double gap = 12.0;

        // 3-Column Params
        double w3 = (maxWidth - 2 * gap) / 3;
        // 2-Column Params
        double w2 = (maxWidth - gap) / 2;
        
        double fixedHeight = 60.0;
        double totalH = 2 * fixedHeight + gap; 
        
        // Center the 2-column grid
        double sideMargin = (maxWidth - (w2 * 2 + gap)) / 2;

        return SizedBox(
          height: totalH,
          child: Stack(
            children: [
              // 0. DATE (Left)
              _animItem(0, isHidden ? sideMargin : 0, 0, isHidden ? w2 : w3, 1, _buildFilterBtn("Date", _filterDate, () => _openFilterModal('date'))),

              // 1. TYPE (IMPLOSION FIX: Stays at 3-col position, scales to 0)
              _animItem(1, 
                w3 + gap, // Keep original left position
                0, 
                w3,       // Keep original width
                isHidden ? 0 : 1, // Scale only
                _buildFilterBtn("Type", _filterType, () => _openFilterModal('type')), 
                shouldScale: true),

              // 2. CATEGORY (Slides from Right to Center)
              _animItem(2, isHidden ? (sideMargin + w2 + gap) : (2 * (w3 + gap)), 0, isHidden ? w2 : w3, 1, _buildFilterBtn("Category", _filterCategory, () => _openFilterModal('category'))),

              // 3. PAYMENT (Bottom Left -> Center)
              _animItem(3, isHidden ? sideMargin : 0, fixedHeight + gap, isHidden ? w2 : w3, 1, _buildFilterBtn("Payment", _filterPayment, () => _openFilterModal('payment'))),

              // 4. SORT (IMPLOSION FIX: Stays at 3-col position, scales to 0)
              _animItem(4, 
                w3 + gap, // Keep original left position
                fixedHeight + gap, 
                w3,       // Keep original width
                isHidden ? 0 : 1, // Scale only
                _buildFilterBtn("Sort By", _filterSort, () => _openFilterModal('sort')), 
                shouldScale: true),

              // 5. SEARCH (Slides from Right to Center)
              _animItem(5, isHidden ? (sideMargin + w2 + gap) : (2 * (w3 + gap)), fixedHeight + gap, isHidden ? w2 : w3, 1, _buildFilterBtn("Search", _filterSearch, () => _openFilterModal('search'))),
            ],
          ),
        );
      },
    );
  }

  Widget _animItem(int key, double left, double top, double width, double scale, Widget child, {bool shouldScale = false}) {
    return AnimatedPositioned(
      key: ValueKey(key),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      left: left,
      top: top,
      width: width,
      height: 60.0,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: scale == 0 ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, 
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(width: width, height: 60, child: child)
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBtn(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 2)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)), maxLines: 1, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  void _openFilterModal(String type) {
    if (type == 'date') { _showDateInputs = false; _tempStartDate = null; _tempEndDate = null; }
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => StatefulBuilder(builder: (context, setModalState) => Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))), padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 40), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3)))), const SizedBox(height: 24), Text(_getModalTitle(type), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), const SizedBox(height: 16), if (type == 'search') _buildSearchInput() else if (type == 'date') _buildDateOptions(setModalState) else _buildListOptions(type)]))));
  }

  String _getModalTitle(String type) {
    switch (type) { case 'date': return "Select Date Range"; case 'type': return "Select Entry Type"; case 'category': return "Select Category"; case 'payment': return "Select Payment Method"; case 'sort': return "Sort By"; case 'search': return "Search Term"; default: return "Filter"; }
  }

  void _setDate(String val) { setState(() => _filterDate = val); Navigator.pop(context); }

  Widget _buildSearchInput() { final TextEditingController searchCtrl = TextEditingController(); return Column(children: [TextField(controller: searchCtrl, decoration: InputDecoration(hintText: "Enter keywords...", filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)))), const SizedBox(height: 16), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () { setState(() => _filterSearch = searchCtrl.text.isEmpty ? "None" : searchCtrl.text); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Apply Search", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))))]); }

  Widget _buildDateOptions(StateSetter setModalState) { return Column(children: [_buildModalItem("All Time", _filterDate == "All Time", () => _setDate("All Time")), _buildModalItem("Last Week", _filterDate == "Last Week", () => _setDate("Last Week")), _buildModalItem("Last Month", _filterDate == "Last Month", () => _setDate("Last Month")), _buildModalItem("Last Year", _filterDate == "Last Year", () => _setDate("Last Year")), const SizedBox(height: 8), InkWell(onTap: () { setModalState(() { _showDateInputs = !_showDateInputs; }); }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Date Range", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF334155))), Icon(_showDateInputs ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold) : PhosphorIcons.caretDown(PhosphorIconsStyle.bold), size: 16, color: const Color(0xFF334155))]))), if (_showDateInputs) Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)), child: Column(children: [Row(children: [Expanded(child: _buildDateInput("From", _tempStartDate, (d) => setModalState(() => _tempStartDate = d))), const SizedBox(width: 12), Expanded(child: _buildDateInput("To", _tempEndDate, (d) => setModalState(() => _tempEndDate = d)))]), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { if (_tempStartDate != null && _tempEndDate != null) { setState(() { _filterDate = "${DateFormat('MMM d').format(_tempStartDate!)} - ${DateFormat('MMM d').format(_tempEndDate!)}"; _startDate = _tempStartDate; _endDate = _tempEndDate; }); Navigator.pop(context); } }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 4, shadowColor: const Color(0xFFC7D2FE)), child: Text("Apply Range", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))))]))]); }

  Widget _buildDateInput(String label, DateTime? val, Function(DateTime) onPick) { return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)), const SizedBox(height: 4), InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: val ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5))), child: child!)); if (d != null) onPick(d); }, child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.centerLeft, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: Text(val == null ? "Select" : DateFormat('MMM d, y').format(val), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)))))]); }

  Widget _buildListOptions(String type) { List<String> options = []; String currentVal = ""; Function(String) onSelect = (val) {}; if (type == 'type') { options = ["All", "Cash In", "Cash Out"]; currentVal = _filterType; onSelect = (val) => setState(() => _filterType = val); } else if (type == 'category') { options = ["All", ..._categories]; currentVal = _filterCategory; onSelect = (val) => setState(() => _filterCategory = val); } else if (type == 'payment') { options = ["All", ..._paymentMethods]; currentVal = _filterPayment; onSelect = (val) => setState(() => _filterPayment = val); } else if (type == 'sort') { options = ["Newest", "Oldest"]; currentVal = _filterSort; onSelect = (val) => setState(() => _filterSort = val); } return Column(children: options.map((opt) => _buildModalItem(opt, currentVal == opt, () { onSelect(opt); Navigator.pop(context); })).toList()); }

  Widget _buildModalItem(String text, bool isSelected, VoidCallback onTap) { return InkWell(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155))), if (isSelected) Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), color: const Color(0xFF4F46E5), size: 18)]))); }

  Widget _buildRadioItem(String val, String text, IconData icon) {
    bool isSelected = _reportType == val;
    return GestureDetector(onTap: () => setState(() => _reportType = val), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isSelected ? const Color(0xFFF8FAFC) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: isSelected ? 2 : 1), boxShadow: [if (isSelected) BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)) else BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF4F46E5), size: 20)), const SizedBox(width: 12), Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B))), const Spacer(), AnimatedScale(scale: isSelected ? 1.0 : 0.0, duration: const Duration(milliseconds: 200), child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: const Color(0xFF4F46E5), size: 24))])));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)), onPressed: () => Navigator.pop(context)), title: Text("Generate Report", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold))),
          body: _isLoadingMeta ? const Center(child: CircularProgressIndicator()) : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("FILTERS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _buildAnimatedGrid(), // The fixed grid
                      const SizedBox(height: 32),
                      Text("REPORT FORMAT", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      _buildRadioItem("all", "All Entries List", PhosphorIcons.listDashes(PhosphorIconsStyle.bold)),
                      const SizedBox(height: 12),
                      _buildRadioItem("day", "Day-Wise Summary", PhosphorIcons.calendarCheck(PhosphorIconsStyle.bold)),
                      const SizedBox(height: 12),
                      _buildRadioItem("month", "Month-Wise Summary", PhosphorIcons.calendar(PhosphorIconsStyle.bold)),
                      const SizedBox(height: 12),
                      _buildRadioItem("category", "Category-Wise Summary", PhosphorIcons.tag(PhosphorIconsStyle.bold)),
                      const SizedBox(height: 12),
                      _buildRadioItem("payment", "Payment Mode Summary", PhosphorIcons.creditCard(PhosphorIconsStyle.bold)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))), child: SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(onPressed: _generateReport, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 8, shadowColor: const Color(0xFFC7D2FE)), icon: Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.bold), color: Colors.white), label: Text("Generate PDF Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))))),
            ],
          ),
        ),
        if (_isLoadingReport) Material(color: Colors.white.withOpacity(0.95), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Lottie.asset('assets/animations/paperscan.json', width: 250, height: 250), Text("Processing Data...", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))), const SizedBox(height: 4), Text("Please wait a moment", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400))]))),
      ],
    );
  }
}
