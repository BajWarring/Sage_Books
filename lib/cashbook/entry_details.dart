import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sage_books/cashbook/entry_form.dart';

class EntryDetailsPage extends StatelessWidget {
  final User user;
  final String cashbookId;
  final String entryId;
  final Map<String, dynamic> data;
  final String currencySymbol;

  const EntryDetailsPage({
    super.key,
    required this.user,
    required this.cashbookId,
    required this.entryId,
    required this.data,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = data['type'] == 'in';
    final Color mainColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    final Color bgColor = isIncome ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2);
    final DateTime date = (data['date'] as Timestamp).toDate();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Details", style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
               // EDIT: Open Entry Form with Data
               Navigator.push(context, MaterialPageRoute(builder: (_) => EntryForm(
                 user: user, cashbookId: cashbookId, initialType: data['type'],
                 existingEntryId: entryId, existingData: data,
               )));
            },
            child: Text("Edit", style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- MAIN CARD ---
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Top Strip
                  Container(height: 6, color: mainColor),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Badge & Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                              child: Text(isIncome ? "CASH IN" : "CASH OUT", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: mainColor)),
                            ),
                            Row(children: [
                              Icon(PhosphorIcons.calendar(PhosphorIconsStyle.bold), size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(DateFormat('MMM d, y').format(date), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Title & Amount
                        Text(data['remarks'] ?? 'No Remarks', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        const SizedBox(height: 4),
                        Text(
                          "${isIncome ? '+' : '-'} $currencySymbol ${(data['amount'] ?? 0).toStringAsFixed(2)}",
                          style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        // Grid
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             _buildDetailItem("Time", DateFormat('h:mm a').format(date), PhosphorIcons.clock(PhosphorIconsStyle.fill)),
                             _buildDetailItem("Category", data['category'] ?? '-', PhosphorIcons.tag(PhosphorIconsStyle.fill)),
                             _buildDetailItem("Method", data['paymentMethod'] ?? 'Cash', PhosphorIcons.creditCard(PhosphorIconsStyle.fill)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- HISTORY LOGS ---
            Align(alignment: Alignment.centerLeft, child: Text("HISTORY", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
              child: Column(
                children: [
                  _buildLogItem(
                    color: Colors.grey.shade300,
                    title: "Entry Created",
                    time: DateFormat('MMM d, h:mm a').format((data['createdAt'] as Timestamp).toDate()),
                    isLast: true,
                  ),
                  // Note: Real editing logs would require a sub-collection. This is static for creation.
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
        child: ElevatedButton.icon(
          onPressed: () {}, // TODO: Share Logic
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(PhosphorIcons.shareNetwork(PhosphorIconsStyle.bold), color: Colors.white),
          label: Text("Share Entry", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(icon, size: 14, color: Colors.grey.shade300),
          const SizedBox(width: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ]),
      ],
    );
  }

  Widget _buildLogItem({required Color color, required String title, required String time, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)])),
            if (!isLast) Container(width: 2, height: 30, color: Colors.grey.shade100),
          ],
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade400)),
            Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
          ],
        )
      ],
    );
  }
}
