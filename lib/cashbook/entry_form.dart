import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntryForm extends StatefulWidget {
  final User user;
  final String cashbookId;
  final String initialType; // 'in' or 'out'

  const EntryForm({
    super.key,
    required this.user,
    required this.cashbookId,
    required this.initialType,
  });

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late String _type;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();
  String _category = 'Food';
  String _paymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _saveEntry() async {
    if (_amountCtrl.text.isEmpty || _remarksCtrl.text.isEmpty) return;

    final double amount = double.parse(_amountCtrl.text);
    
    // Create Date Object
    final DateTime fullDate = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute
    );

    // 1. Reference
    final bookRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('cashbooks').doc(widget.cashbookId);
    
    // 2. Transaction (Safe Update)
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Get current book data to update balance
      DocumentSnapshot bookSnapshot = await transaction.get(bookRef);
      if (!bookSnapshot.exists) return;
      
      double currentBalance = (bookSnapshot.get('balance') ?? 0).toDouble();
      double newBalance = _type == 'in' ? currentBalance + amount : currentBalance - amount;

      // Add Entry
      transaction.set(bookRef.collection('entries').doc(), {
        'type': _type,
        'amount': amount,
        'remarks': _remarksCtrl.text,
        'category': _category,
        'paymentMethod': _paymentMethod,
        'date': Timestamp.fromDate(fullDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update Balance
      transaction.update(bookRef, {'balance': newBalance});
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isIn = _type == 'in';
    final Color mainColor = isIn ? const Color(0xFF10B981) : const Color(0xFFE11D48);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleBtn("Cash In", 'in'),
              _buildToggleBtn("Cash Out", 'out'),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DATE & TIME
            Row(
              children: [
                Expanded(child: _buildInputLabel("Date", _buildDatePicker())),
                const SizedBox(width: 16),
                Expanded(child: _buildInputLabel("Time", _buildTimePicker())),
              ],
            ),
            const SizedBox(height: 24),

            // AMOUNT
            Text("Amount", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: mainColor),
              decoration: InputDecoration(
                prefixText: "\$ ",
                prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                border: InputBorder.none,
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.grey.shade300),
              ),
            ),
            const Divider(),
            const SizedBox(height: 24),

            // REMARKS
            _buildInputLabel("Remarks", TextField(
              controller: _remarksCtrl,
              decoration: _inputDeco("What is this for?"),
            )),
            const SizedBox(height: 24),

            // CATEGORY
            _buildInputLabel("Category", Wrap(
              spacing: 8,
              children: ['Food', 'Transport', 'Salary', 'Shopping'].map((c) => _buildChip(c, _category == c, (val) => setState(() => _category = val))).toList(),
            )),
            const SizedBox(height: 24),

            // PAYMENT
            _buildInputLabel("Payment Method", Wrap(
              spacing: 8,
              children: ['Cash', 'Online', 'Card'].map((c) => _buildChip(c, _paymentMethod == c, (val) => setState(() => _paymentMethod = val))).toList(),
            )),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
        child: ElevatedButton(
          onPressed: _saveEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: mainColor.withOpacity(0.4),
          ),
          child: Text("Save Entry", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // --- WIDGETS ---
  
  Widget _buildToggleBtn(String text, String val) {
    bool isSelected = _type == val;
    return GestureDetector(
      onTap: () => setState(() => _type = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? (val == 'in' ? const Color(0xFF10B981) : const Color(0xFFE11D48)) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }

  Widget _buildInputLabel(String label, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
      const SizedBox(height: 8),
      child,
    ]);
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    );
  }

  Widget _buildChip(String label, bool isActive, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.indigo.shade50 : Colors.white,
          border: Border.all(color: isActive ? Colors.indigo : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: isActive ? Colors.indigo : Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (d != null) setState(() => _selectedDate = d);
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: _selectedTime);
        if (t != null) setState(() => _selectedTime = t);
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(_selectedTime.format(context), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
