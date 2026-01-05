import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart'; // Import Lottie

class GenerateReportPage extends StatefulWidget {
  final User user;
  final String cashbookId;

  const GenerateReportPage({super.key, required this.user, required this.cashbookId});

  @override
  State<GenerateReportPage> createState() => _GenerateReportPageState();
}

class _GenerateReportPageState extends State<GenerateReportPage> {
  // --- STATE VARIABLES ---
  String _filterDate = "All Time";
  String _filterType = "All";
  String _filterCategory = "All";
  String _filterPayment = "All";
  String _filterSort = "Newest";
  String _filterSearch = "None";
  String _reportType = "all"; // 'all', 'day', 'month', 'category', 'payment'

  bool _isLoadingReport = false; // Controls Lottie Overlay

  // Custom Date Range
  DateTime? _startDate;
  DateTime? _endDate;

  // Dynamic Lists
  List<String> _categories = [];
  List<String> _paymentMethods = [];
  bool _isLoadingMeta = true;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    final docs = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .collection('cashbooks')
        .doc(widget.cashbookId)
        .collection('entries')
        .get();

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
    // 1. Show Loading Overlay
    setState(() => _isLoadingReport = true);

    // 2. Simulate Processing (3 Seconds)
    await Future.delayed(const Duration(seconds: 3));

    // 3. Hide Loading
    if (mounted) setState(() => _isLoadingReport = false);

    // 4. Show Success Modal
    if (mounted) _showSuccessModal();
  }

  void _showSuccessModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(width: 48, height: 6, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
            
            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), shape: BoxShape.circle), // Emerald 100
              child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: const Color(0xFF059669), size: 32), // Emerald 600
            ),
            const SizedBox(height: 16),
            
            // Text
            Text("Report Ready!", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 4),
            Text("Your PDF has been generated successfully.", style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 32),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () { 
                  Navigator.pop(context); // Close Success
                  // TODO: Open PDF Preview
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: Icon(PhosphorIcons.eye(PhosphorIconsStyle.bold), color: Colors.white),
                label: Text("See Preview", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close Success
                  Navigator.pop(context); // Go back to Cashbook
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold), color: const Color(0xFF334155)),
                label: Text("Save To Downloads", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MODALS ---
  // (Kept _openFilterModal and helper widgets mostly the same, adjusted for context)
  void _openFilterModal(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 24),
            Text(_getModalTitle(type), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
            const SizedBox(height: 16),
            if (type == 'search') _buildSearchInput() else if (type == 'date') _buildDateOptions() else _buildListOptions(type),
          ],
        ),
      ),
    );
  }

  // ... (Keep helper methods _getModalTitle, _buildSearchInput, _buildDateOptions, _buildListOptions, _setDate, _buildModalItem from previous response exactly as is) ...
  // RE-INCLUDED FOR COMPLETENESS:
  String _getModalTitle(String type) {
    switch (type) {
      case 'date': return "Select Date Range";
      case 'type': return "Select Entry Type";
      case 'category': return "Select Category";
      case 'payment': return "Select Payment Method";
      case 'sort': return "Sort By";
      case 'search': return "Search Term";
      default: return "Filter";
    }
  }

  Widget _buildSearchInput() {
    final TextEditingController searchCtrl = TextEditingController();
    return Column(children: [TextField(controller: searchCtrl, decoration: InputDecoration(hintText: "Enter keywords...", filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)))), const SizedBox(height: 16), SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () { setState(() => _filterSearch = searchCtrl.text.isEmpty ? "None" : searchCtrl.text); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Apply Search", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))))]);
  }

  Widget _buildDateOptions() {
    return Column(children: [_buildModalItem("All Time", _filterDate == "All Time", () => _setDate("All Time")), _buildModalItem("Last Week", _filterDate == "Last Week", () => _setDate("Last Week")), _buildModalItem("Last Month", _filterDate == "Last Month", () => _setDate("Last Month")), _buildModalItem("Last Year", _filterDate == "Last Year", () => _setDate("Last Year")), const SizedBox(height: 8), InkWell(onTap: () async { Navigator.pop(context); final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030), builder: (ctx, child) => Theme(data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5))), child: child!)); if (picked != null) { setState(() { _startDate = picked.start; _endDate = picked.end; _filterDate = "${DateFormat('MMM d').format(picked.start)} - ${DateFormat('MMM d').format(picked.end)}"; }); } }, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Date Range (From - To)", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))), Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16, color: Colors.grey.shade400)])))]);
  }

  Widget _buildListOptions(String type) {
    List<String> options = []; String currentVal = ""; Function(String) onSelect = (val) {};
    if (type == 'type') { options = ["All", "Cash In", "Cash Out"]; currentVal = _filterType; onSelect = (val) => setState(() => _filterType = val); } else if (type == 'category') { options = ["All", ..._categories]; currentVal = _filterCategory; onSelect = (val) => setState(() => _filterCategory = val); } else if (type == 'payment') { options = ["All", ..._paymentMethods]; currentVal = _filterPayment; onSelect = (val) => setState(() => _filterPayment = val); } else if (type == 'sort') { options = ["Newest", "Oldest"]; currentVal = _filterSort; onSelect = (val) => setState(() => _filterSort = val); }
    return Column(children: options.map((opt) => _buildModalItem(opt, currentVal == opt, () { onSelect(opt); Navigator.pop(context); })).toList());
  }

  void _setDate(String val) { setState(() { _filterDate = val; _startDate = null; _endDate = null; }); Navigator.pop(context); }

  Widget _buildModalItem(String text, bool isSelected, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155))), if (isSelected) Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), color: const Color(0xFF4F46E5), size: 18)])));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- MAIN CONTENT ---
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)), onPressed: () => Navigator.pop(context)),
            title: Text("Generate Report", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
          ),
          body: _isLoadingMeta ? const Center(child: CircularProgressIndicator()) : Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FILTERS (3 COLUMNS) ---
                      Text("FILTERS", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
                      const SizedBox(height: 12),
                      
                      GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildFilterBtn("Date", _filterDate, () => _openFilterModal('date')),
                          _buildFilterBtn("Type", _filterType, () => _openFilterModal('type')),
                          _buildFilterBtn("Category", _filterCategory, () => _openFilterModal('category')),
                          _buildFilterBtn("Payment", _filterPayment, () => _openFilterModal('payment')),
                          _buildFilterBtn("Sort By", _filterSort, () => _openFilterModal('sort')),
                          _buildFilterBtn("Search", _filterSearch, () => _openFilterModal('search')),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- REPORT FORMAT ---
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

              // --- GENERATE BUTTON ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
                child: ElevatedButton.icon(
                  onPressed: _generateReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF4F46E5).withOpacity(0.3),
                  ),
                  icon: Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.bold), color: Colors.white),
                  label: Text("Generate PDF Report", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        // --- LOADING OVERLAY ---
        if (_isLoadingReport)
          Container(
            color: Colors.white.withOpacity(0.95),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // LOTTIE ANIMATION
                  Lottie.asset('assets/animations/paperscan.json', width: 250, height: 250),
                  // Text
                  Text("Processing Data...", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5))),
                  const SizedBox(height: 4),
                  Text("Please wait a moment", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterBtn(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400), maxLines: 1),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4F46E5)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(String val, String text, IconData icon) {
    bool isSelected = _reportType == val;
    return GestureDetector(
      onTap: () => setState(() => _reportType = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.white, // Subtle tint when selected
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [if (isSelected) BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)) else BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]
        ),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xFF4F46E5), size: 20)),
            const SizedBox(width: 12),
            Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF1E293B))),
            const Spacer(),
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill), color: const Color(0xFF4F46E5), size: 24),
            )
          ],
        ),
      ),
    );
  }
}
