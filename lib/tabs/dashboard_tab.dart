import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardTab extends StatefulWidget {
  final User user;

  const DashboardTab({super.key, required this.user});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  
  // --- ACTION: Open Add Modal ---
  void _showAddCashbookModal(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCurrency = 'USD (\$)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24, 
          right: 24, 
          top: 24, 
          bottom: MediaQuery.of(context).viewInsets.bottom + 40
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, 
                height: 6,
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add Cashbook", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 16, color: Colors.grey),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Text("Cashbook Name", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: "e.g. Office Expenses",
                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
                filled: true, 
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5))),
              ),
            ),
            const SizedBox(height: 16),
            Text("Currency", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCurrency,
              items: ['USD (\$)', 'EUR (€)', 'GBP (£)', 'INR (₹)']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit(fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: (v) => selectedCurrency = v!,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').add({
                      'name': nameController.text,
                      'currency': selectedCurrency,
                      'createdAt': FieldValue.serverTimestamp(),
                      'balance': 0.0,
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18, color: Colors.white),
                label: Text("Create Cashbook", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACTION: Show Options Popup (Long Press) ---
  void _showOptionsDialog(BuildContext context, String docId, String bookName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                bookName,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Options List
              _buildOptionItem(
                icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.duotone), 
                text: "Book Details", 
                color: const Color(0xFF334155),
                onTap: () { Navigator.pop(context); /* TODO: Navigate to Details */ }
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildOptionItem(
                icon: PhosphorIcons.pencilSimple(PhosphorIconsStyle.duotone), 
                text: "Edit Book", 
                color: const Color(0xFF334155),
                onTap: () { Navigator.pop(context); /* TODO: Show Edit Modal */ }
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildOptionItem(
                icon: PhosphorIcons.trash(PhosphorIconsStyle.duotone), 
                text: "Delete Book", 
                color: const Color(0xFFE11D48), // Rose 600
                onTap: () {
                  Navigator.pop(context); // Close Options
                  _showDeleteConfirmation(context, docId, bookName); // Open Confirmation
                }
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTION: Delete Confirmation (Type to Delete) ---
  void _showDeleteConfirmation(BuildContext context, String docId, String bookName) {
    final confirmationController = TextEditingController();
    bool isMatch = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Delete Cashbook?", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48))),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
                        children: [
                          const TextSpan(text: "This action cannot be undone. Type "),
                          TextSpan(text: bookName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const TextSpan(text: " to confirm."),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmationController,
                      onChanged: (val) {
                        setState(() {
                          isMatch = val == bookName;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: bookName,
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFFCBD5E1)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE11D48))),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Cancel", style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isMatch ? () async {
                              await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').doc(docId).delete();
                              Navigator.pop(context);
                            } : null, // Disabled until match
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE11D48),
                              disabledBackgroundColor: const Color(0xFFFDA4AF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text("Delete", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = widget.user.displayName?.split(' ')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(widget.user.photoURL ?? 'https://i.pravatar.cc/150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Text(
              "Hi, $firstName",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
        actions: [
          _buildHeaderBtn(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
          _buildHeaderBtn(PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold)),
          _buildHeaderBtn(PhosphorIcons.dotsThreeCircle(PhosphorIconsStyle.bold)),
          const SizedBox(width: 16),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('cashbooks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // EMPTY STATE (Big Center Button)
          if (docs.isEmpty) {
            return Center(
              child: GestureDetector(
                onTap: () => _showAddCashbookModal(context),
                child: Container(
                  width: 200,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF), // Blue 50
                          shape: BoxShape.circle,
                        ),
                        child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: const Color(0xFF2563EB)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Add First Cashbook",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // LIST STATE
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == docs.length) return const SizedBox(height: 100);

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildBookCard(
                docId: doc.id,
                title: data['name'] ?? 'Untitled',
                currency: data['currency'] ?? '\$',
                balance: (data['balance'] ?? 0.0).toStringAsFixed(2),
              );
            },
          );
        },
      ),

      // FAB
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => _showAddCashbookModal(context),
                backgroundColor: const Color(0xFF0F172A),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HELPERS ---

  Widget _buildHeaderBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Icon(icon, color: const Color(0xFF475569), size: 20),
    );
  }

  Widget _buildOptionItem({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(text, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  // 🔴 RESTORED ORIGINAL UI CARD
  Widget _buildBookCard({required String docId, required String title, required String currency, required String balance}) {
    final double val = double.tryParse(balance) ?? 0;
    final isPositive = val >= 0;
    String symbol = currency.split(' ')[1].replaceAll(RegExp(r'[()]'), '');

    return GestureDetector(
      // ✨ ADDED: LONG PRESS TO SHOW OPTIONS
      onLongPress: () => _showOptionsDialog(context, docId, title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), offset: const Offset(0, 2), blurRadius: 4)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), // Emerald 50 vs Rose 50
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    PhosphorIcons.wallet(PhosphorIconsStyle.duotone), // Using Wallet as generic placeholder like original HTML used different icons
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48), 
                    size: 20
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                    ),
                    Text(
                      "Updated just now",
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$symbol $balance",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                  ),
                ),
                // ✨ ADDED: The "Surplus/Deficit" Badge
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isPositive ? "Surplus" : "Deficit",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
