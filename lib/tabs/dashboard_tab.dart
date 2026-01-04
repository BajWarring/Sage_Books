import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sage_books/cashbook/cashbook_page.dart';

class DashboardTab extends StatefulWidget {
  final User user;
  const DashboardTab({super.key, required this.user});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _sortBy = 'createdAt';

  void _toggleSearch() { setState(() { _isSearchVisible = !_isSearchVisible; if (!_isSearchVisible) { _searchController.clear(); _searchText = ""; } }); }
  
  void _showSortMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(Rect.fromPoints(button.localToGlobal(Offset.zero, ancestor: overlay), button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay)), Offset.zero & overlay.size);
    final String? result = await showMenu<String>(context: context, position: position.shift(const Offset(20, 50)), color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), items: [PopupMenuItem(value: 'name', child: _buildSortItem("By Name", PhosphorIcons.textAa(PhosphorIconsStyle.bold))), PopupMenuItem(value: 'createdAt', child: _buildSortItem("Last Updated", PhosphorIcons.clock(PhosphorIconsStyle.bold)))]);
    if (result != null) setState(() => _sortBy = result);
  }

  Widget _buildSortItem(String text, IconData icon) { return Row(children: [Icon(icon, size: 18, color: const Color(0xFF64748B)), const SizedBox(width: 12), Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)))]); }

  // --- CHANGED TO DIALOG (MIDDLE POPUP) ---
  void _showAddCashbookModal(BuildContext context) {
    final nameController = TextEditingController();
    String selectedCurrency = '🇺🇸 USD (\$)';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Cashbook", style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
              const SizedBox(height: 24),
              
              Text("Cashbook Name", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "e.g. Office Expenses",
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 20),
              
              Text("Currency", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCurrency,
                // ADDED FLAGS AS "LOGOS"
                items: ['🇺🇸 USD (\$)','🇪🇺 EUR (€)','🇬🇧 GBP (£)','🇮🇳 INR (₹)']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))).toList(),
                onChanged: (v) => selectedCurrency = v!,
                decoration: InputDecoration(
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.3)
                  ),
                  child: Text("Create Cashbook", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, 
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.user.photoURL ?? 'https://i.pravatar.cc/150'), radius: 18),
            const SizedBox(width: 12),
            Text("Hi, ${widget.user.displayName?.split(' ')[0] ?? 'User'}", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
          ],
        ),
        actions: [
          IconButton(onPressed: _toggleSearch, icon: Icon(PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold), color: const Color(0xFF64748B))),
          Builder(builder: (ctx) => IconButton(onPressed: () => _showSortMenu(ctx), icon: Icon(PhosphorIcons.slidersHorizontal(PhosphorIconsStyle.bold), color: const Color(0xFF64748B)))),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchVisible ? 60 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: _isSearchVisible ? TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchText = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search cashbooks...",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true, fillColor: Colors.white, contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
            ) : null,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').orderBy(_sortBy, descending: _sortBy == 'createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data?.docs ?? [];
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['name'].toString().toLowerCase().contains(_searchText)).toList();
                }
                if (docs.isEmpty) return Center(child: Text("No cashbooks found", style: GoogleFonts.outfit(color: Colors.grey.shade400)));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) return Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Your Books", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)), child: Text(_sortBy == 'createdAt' ? "Sorted by Recent" : "Sorted by Name", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))))]));
                    return _buildBookCard(context, docs[index - 1].id, docs[index - 1].data() as Map<String, dynamic>);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showAddCashbookModal(context),
          backgroundColor: const Color(0xFF0F172A),
          child: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final balance = (data['balance'] ?? 0.0).toStringAsFixed(2);
    // SAFELY EXTRACT SYMBOL (Split by space or take first char)
    String rawCurr = data['currency'] ?? '\$';
    String currency = rawCurr.contains('(') ? rawCurr.split('(')[1].replaceAll(')', '') : rawCurr.split(' ').last;
    
    final isPositive = (data['balance'] ?? 0) >= 0;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CashbookPage(user: widget.user, cashbookId: docId, cashbookName: data['name'], currency: currency))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), shape: BoxShape.circle), child: Icon(PhosphorIcons.notebook(PhosphorIconsStyle.duotone), color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48), size: 20)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['name'], style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                Text("Tap to view entries", style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8))),
              ]),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text("$currency $balance", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48))),
              Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(4)), child: Text(isPositive ? "Surplus" : "Deficit", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFE11D48)))),
            ]),
          ],
        ),
      ),
    );
  }
}
