import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sage_books/cashbook/entry_form.dart';

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
  String _formatDate(Timestamp t) {
    final date = t.toDate();
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) return "Today";
    return DateFormat('MMM d, y').format(date);
  }

  String _formatTime(Timestamp t) => DateFormat('h:mm a').format(t.toDate());

  @override
  Widget build(BuildContext context) {
    final String symbol = widget.currency.split(' ')[0].replaceAll(RegExp(r'[()]'), ''); // Extract '$' or '€'

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // --- HEADER ---
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
            onPressed: () {}, // TODO: Cashbook Settings (Edit/Delete)
          ),
        ],
      ),

      // --- BODY ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('cashbooks')
            .doc(widget.cashbookId)
            .collection('entries')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data?.docs ?? [];

          // --- CALCULATE TOTALS ON THE FLY ---
          double totalIn = 0;
          double totalOut = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount = (data['amount'] ?? 0).toDouble();
            if (data['type'] == 'in') totalIn += amount;
            else totalOut += amount;
          }
          double netBalance = totalIn - totalOut;

          return Column(
            children: [
              // 1. SUMMARY CARD
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Text("Net Balance", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
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
                    ],
                  ),
                ),
              ),

              // 2. ENTRIES LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final bool isIncome = data['type'] == 'in';
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['remarks'] ?? 'No Remarks', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildTag(_formatTime(data['date'] as Timestamp), Colors.grey.shade100, Colors.grey.shade500),
                                  const SizedBox(width: 6),
                                  _buildTag(data['paymentMethod'] ?? 'Cash', Colors.grey.shade100, Colors.grey.shade500),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${isIncome ? '+' : '-'} $symbol ${(data['amount'] ?? 0).toStringAsFixed(2)}",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isIncome ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                                ),
                              ),
                              Text(_formatDate(data['date'] as Timestamp), style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade400)),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // --- BOTTOM ACTION BUTTONS ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openEntryForm('in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), // Emerald
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
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
                  elevation: 0,
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

  Widget _buildTag(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
