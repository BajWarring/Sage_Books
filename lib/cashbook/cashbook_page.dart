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

  const CashbookPage({
    super.key,
    required this.user,
    required this.cashbookId,
    required this.cashbookName,
    required this.currency,
  });

  @override
  State<CashbookPage> createState() => _CashbookPageState();
}

class _CashbookPageState extends State<CashbookPage> {
  // --- HELPERS ---
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
      // --- APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.cashbookName,
          style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.dotsThreeVertical(PhosphorIconsStyle.bold), color: const Color(0xFF475569)),
            onPressed: () {}, // Options
          ),
        ],
      ),

      // --- BODY ---
      body: Column(
        children: [
          // 1. SEARCH BAR
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search entries...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 2. MAIN LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .collection('cashbooks')
                  .doc(widget.cashbookId)
                  .collection('entries')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // --- A. CALCULATE TOTALS ---
                double totalIn = 0;
                double totalOut = 0;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  double val = (data['amount'] ?? 0).toDouble();
                  if (data['type'] == 'in') {
                    totalIn += val;
                  } else {
                    totalOut += val;
                  }
                }
                double netBalance = totalIn - totalOut;

                // --- B. GROUP ENTRIES BY DATE ---
                // We use a Map<String, List> to group them
                Map<String, List<QueryDocumentSnapshot>> groupedEntries = {};
                
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['date'] as Timestamp;
                  final dateKey = _formatDate(timestamp.toDate());

                  if (!groupedEntries.containsKey(dateKey)) {
                    groupedEntries[dateKey] = [];
                  }
                  groupedEntries[dateKey]!.add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // --- SUMMARY CARD ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text("NET BALANCE", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
                          Text(
                            "$symbol ${netBalance.toStringAsFixed(2)}",
                            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xFF4F46E5)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryBox("TOTAL IN", "$symbol ${totalIn.toStringAsFixed(0)}", const Color(0xFFECFDF5), const Color(0xFF10B981)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryBox("TOTAL OUT", "$symbol ${totalOut.toStringAsFixed(0)}", const Color(0xFFFFF1F2), const Color(0xFFE11D48)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton.icon(
                              onPressed: (){}, 
                              icon: Icon(PhosphorIcons.filePdf(PhosphorIconsStyle.bold), size: 18), 
                              label: const Text("Generate Report"), 
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.indigo, 
                                backgroundColor: Colors.indigo.shade50, 
                                side: BorderSide.none, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- GROUPED LIST RENDER ---
                    // Iterate through the map entries
                    ...groupedEntries.entries.map((entry) {
                      String dateLabel = entry.key; // e.g., "Today"
                      List<QueryDocumentSnapshot> dayDocs = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // DATE HEADER (Displays once per group)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateLabel,
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                          ),

                          // LIST OF CARDS FOR THIS DATE
                          ...dayDocs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final bool isIncome = data['type'] == 'in';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (_) => EntryDetailsPage(
                                      user: widget.user, 
                                      cashbookId: widget.cashbookId, 
                                      entryId: doc.id, 
                                      data: data, 
                                      currencySymbol: symbol
                                    )
                                  )
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Left Side: Remarks & Tags
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['remarks'] ?? 'No Remarks',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _buildTag(_formatTime(data['date'] as Timestamp)),
                                            const SizedBox(width: 6),
                                            _buildTag(data['paymentMethod'] ?? 'Cash'),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Right Side: Amount
                                    Text(
                                      "${isIncome ? '+' : '-'} $symbol ${(data['amount'] ?? 0).toStringAsFixed(2)}",
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }), // End of map docs
                          
                          const SizedBox(height: 12), // Spacer between groups
                        ],
                      );
                    }), // End of map groupedEntries
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // --- BOTTOM BUTTONS ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openEntryForm('in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white),
                label: Text("Cash In", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openEntryForm('out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48), // Rose
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(PhosphorIcons.minus(PhosphorIconsStyle.bold), color: Colors.white),
                label: Text("Cash Out", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEntryForm(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EntryForm(
          user: widget.user,
          cashbookId: widget.cashbookId,
          initialType: type,
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, String amount, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: text.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(amount, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
      ),
    );
  }
}
