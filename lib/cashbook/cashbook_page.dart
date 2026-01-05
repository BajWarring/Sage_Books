import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sage_books/cashbook/entry_form.dart';
import 'package:sage_books/cashbook/entry_details.dart';

class CashbookPage extends StatefulWidget {
  final User user;
  final String cashbookId;
  final String cashbookName;
  final String currency;

  const CashbookPage({super.key, required this.user, required this.cashbookId, required this.cashbookName, required this.currency});

  @override
  State<CashbookPage> createState() => _CashbookPageState();
}

class _CashbookPageState extends State<CashbookPage> {
  String _searchText = "";
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchCtrl = TextEditingController();

  // Show "From - To" Dialog
  void _showDateFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Filter by Date", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text("From Date", style: GoogleFonts.outfit(color: Colors.grey)),
                subtitle: Text(_startDate == null ? "Select Date" : DateFormat('MMM d, y').format(_startDate!), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
                leading: const Icon(PhosphorIcons.calendar),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) { setState(() => _startDate = d); Navigator.pop(context); _showDateFilterDialog(); }
                },
              ),
              ListTile(
                title: Text("To Date", style: GoogleFonts.outfit(color: Colors.grey)),
                subtitle: Text(_endDate == null ? "Select Date" : DateFormat('MMM d, y').format(_endDate!), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
                leading: const Icon(PhosphorIcons.calendar),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                  if (d != null) { setState(() => _endDate = d); Navigator.pop(context); _showDateFilterDialog(); }
                },
              ),
              if (_startDate != null || _endDate != null)
                TextButton(onPressed: (){ setState(() { _startDate = null; _endDate = null; }); Navigator.pop(context); }, child: const Text("Clear Filter", style: TextStyle(color: Colors.red)))
            ],
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate == today) return "Today";
    if (checkDate == yesterday) return "Yesterday";
    return DateFormat('MMM d, y').format(date);
  }
  String _formatTime(Timestamp t) => DateFormat('h:mm a').format(t.toDate());

  @override
  Widget build(BuildContext context) {
    final String symbol = widget.currency;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)), onPressed: () => Navigator.pop(context)),
        title: Text(widget.cashbookName, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [IconButton(icon: Icon(PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold), color: const Color(0xFF475569)), onPressed: () {})],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search by text...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true, fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // FILTER BUTTON
                InkWell(
                  onTap: _showDateFilterDialog,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: (_startDate != null) ? Colors.indigo.shade50 : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                    child: Icon(PhosphorIcons.faders(PhosphorIconsStyle.bold), color: (_startDate != null) ? Colors.indigo : Colors.grey),
                  ),
                )
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').doc(widget.cashbookId).collection('entries').orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // 1. Get All Docs
                var docs = snapshot.data?.docs ?? [];
                
                // 2. Filter (Text + Date)
                if (_searchText.isNotEmpty || _startDate != null) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    bool matchText = _searchText.isEmpty || data['remarks'].toString().toLowerCase().contains(_searchText);
                    bool matchDate = true;
                    if (_startDate != null && _endDate != null) {
                      matchDate = date.isAfter(_startDate!.subtract(const Duration(days: 1))) && date.isBefore(_endDate!.add(const Duration(days: 1)));
                    }
                    return matchText && matchDate;
                  }).toList();
                }

                // 3. Calculate Running Balance
                // We must sort ASCENDING to calc balance over time
                List<QueryDocumentSnapshot> sortedAsc = List.from(docs);
                sortedAsc.sort((a, b) => (a.data() as Map)['date'].compareTo((b.data() as Map)['date']));
                
                Map<String, double> runningBalances = {};
                double tempBalance = 0;
                double totalIn = 0; 
                double totalOut = 0;

                for (var doc in sortedAsc) {
                  Map data = doc.data() as Map;
                  double amount = (data['amount'] ?? 0).toDouble();
                  if (data['type'] == 'in') {
                    tempBalance += amount;
                    totalIn += amount;
                  } else {
                    tempBalance -= amount;
                    totalOut += amount;
                  }
                  runningBalances[doc.id] = tempBalance;
                }
                
                // 4. Group (using original DESC list)
                Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in docs) {
                  String key = _formatDate((doc.data() as Map)['date'].toDate());
                  if (!grouped.containsKey(key)) grouped[key] = [];
                  grouped[key]!.add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))]),
                      child: Column(children: [Text("NET BALANCE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)), Text("$symbol ${tempBalance.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5))), const SizedBox(height: 16), Row(children: [Expanded(child: _buildSummaryBox("TOTAL IN", "$symbol ${totalIn.toStringAsFixed(0)}", const Color(0xFFECFDF5), const Color(0xFF10B981))), const SizedBox(width: 12), Expanded(child: _buildSummaryBox("TOTAL OUT", "$symbol ${totalOut.toStringAsFixed(0)}", const Color(0xFFFFF1F2), const Color(0xFFE11D48)))]), const SizedBox(height: 16), InkWell(onTap: (){}, child: Container(height: 40, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE0E7FF))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.bold), size: 18, color: const Color(0xFF4338CA)), const SizedBox(width: 8), Text("Generate Report", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)))])))]),
                    ),
                    const SizedBox(height: 24),
                    ...grouped.entries.map((entry) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: Text(entry.key, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
                          ...entry.value.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            double rBal = runningBalances[doc.id] ?? 0.0;
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailsPage(user: widget.user, cashbookId: widget.cashbookId, entryId: doc.id, data: data, currencySymbol: symbol))),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)]),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(data['remarks'] ?? 'No Remarks', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                                    const SizedBox(height: 6),
                                    Row(children: [_buildTag(_formatTime(data['date'] as Timestamp)), const SizedBox(width: 6), _buildTag(data['paymentMethod'] ?? 'Cash')]),
                                  ]),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                     Text("${data['type'] == 'in' ? '+' : '-'} $symbol ${(data['amount'] ?? 0).toStringAsFixed(2)}", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: data['type'] == 'in' ? const Color(0xFF10B981) : const Color(0xFFE11D48))),
                                     // RUNNING BALANCE VISIBLE HERE
                                     Text("Bal: $symbol${rBal.toStringAsFixed(2)}", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade400)),
                                  ]),
                                ]),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 12),
                        ]);
                    }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))), child: Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => _openEntryForm('in'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white), label: Text("Cash In", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))), const SizedBox(width: 16), Expanded(child: ElevatedButton.icon(onPressed: () => _openEntryForm('out'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold), color: Colors.white), label: Text("Cash Out", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white))))])),
    );
  }

  void _openEntryForm(String type) { Navigator.push(context, MaterialPageRoute(builder: (_) => EntryForm(user: widget.user, cashbookId: widget.cashbookId, initialType: type, currencySymbol: widget.currency))); }
  Widget _buildSummaryBox(String label, String amount, Color bg, Color text) { return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: text.withOpacity(0.7))), const SizedBox(height: 4), Text(amount, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: text))])); }
  Widget _buildTag(String text) { return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE0E7FF))), child: Text(text, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF4338CA)))); }
}
