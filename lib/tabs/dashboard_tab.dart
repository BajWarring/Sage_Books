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
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Cashbook",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    // FIX 1: Added (PhosphorIconsStyle.bold)
                    child: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), size: 16, color: Colors.grey),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Form: Name
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

            // Form: Currency
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

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    // SAVE TO FIREBASE
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user.uid)
                        .collection('cashbooks')
                        .add({
                      'name': nameController.text,
                      'currency': selectedCurrency,
                      'createdAt': FieldValue.serverTimestamp(),
                      'balance': 0.0, // Start with 0
                    });
                    Navigator.pop(context); // Close Modal
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A), // Slate 900
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                // FIX 2: Added (PhosphorIconsStyle.bold)
                icon: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold), size: 18, color: Colors.white),
                label: Text("Create Cashbook", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
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
          // FIX 3: Added (PhosphorIconsStyle.bold) to all header icons
          _buildHeaderBtn(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold)),
          _buildHeaderBtn(PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold)),
          _buildHeaderBtn(PhosphorIcons.dotsThreeCircle(PhosphorIconsStyle.bold)),
          const SizedBox(width: 16),
        ],
      ),

      // --- BODY: CONNECTED TO FIREBASE ---
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('cashbooks')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // 2. EMPTY STATE (Big Center Button)
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
                        // FIX 4: Added (PhosphorIconsStyle.bold)
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

          // 3. LIST STATE (Show List)
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: docs.length + 1, // +1 for spacer
            itemBuilder: (context, index) {
              if (index == docs.length) return const SizedBox(height: 100); // Spacer

              final data = docs[index].data() as Map<String, dynamic>;
              return _buildBookCard(
                title: data['name'] ?? 'Untitled',
                currency: data['currency'] ?? '\$',
                balance: (data['balance'] ?? 0.0).toStringAsFixed(2),
              );
            },
          );
        },
      ),

      // --- FAB: LOGIC FOR VISIBILITY ---
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox(); // Hide if empty
          
          // SHOW IF DATA EXISTS
          return Padding(
            padding: const EdgeInsets.only(bottom: 80), // Push up above nav bar
            child: SizedBox(
              width: 56,
              height: 56,
              child: FloatingActionButton(
                onPressed: () => _showAddCashbookModal(context),
                backgroundColor: const Color(0xFF0F172A),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                // FIX 5: Added (PhosphorIconsStyle.bold)
                child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---
  
  Widget _buildHeaderBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Icon(icon, color: const Color(0xFF475569), size: 20),
    );
  }

  Widget _buildBookCard({required String title, required String currency, required String balance}) {
    // Determine color based on balance (Simple Logic)
    final double val = double.tryParse(balance) ?? 0;
    final isPositive = val >= 0;
    
    // Extract Symbol
    String symbol = currency.split(' ')[1].replaceAll(RegExp(r'[()]'), '');

    return Container(
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  shape: BoxShape.circle,
                ),
                // FIX 6: Added (PhosphorIconsStyle.duotone) to match HTML design
                child: Icon(
                  PhosphorIcons.notebook(PhosphorIconsStyle.duotone), 
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
                    "Just now",
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "$symbol $balance",
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
  }
}
