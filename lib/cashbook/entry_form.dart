import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EntryForm extends StatefulWidget {
  final User user;
  final String cashbookId;
  final String initialType;
  final String? existingEntryId;
  final Map<String, dynamic>? existingData;
  final String currencySymbol;

  const EntryForm({
    super.key,
    required this.user,
    required this.cashbookId,
    required this.initialType,
    required this.currencySymbol,
    this.existingEntryId,
    this.existingData,
  });

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late String _type;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();
  
  // Fields
  String? _category; // Optional
  String? _paymentMethod; // Required
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Validation State
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _amountCtrl.text = data['amount'].toString();
      _remarksCtrl.text = data['remarks'];
      _category = data['category'];
      _paymentMethod = data['paymentMethod'];
      final date = (data['date'] as Timestamp).toDate();
      _selectedDate = date;
      _selectedTime = TimeOfDay.fromDateTime(date);
    }
  }

  Future<void> _saveEntry({bool addNew = false}) async {
    // 1. VALIDATION LOGIC
    // Amount, Remarks, Payment are REQUIRED. Category is OPTIONAL.
    if (_amountCtrl.text.isEmpty || _remarksCtrl.text.isEmpty || _paymentMethod == null) {
      setState(() => _showErrors = true); // Trigger Red Borders
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all required fields marked in red.", style: GoogleFonts.outfit()),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    final double amount = double.parse(_amountCtrl.text);
    final DateTime fullDate = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day, 
      _selectedTime.hour, _selectedTime.minute
    );
    
    final bookRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid)
        .collection('cashbooks').doc(widget.cashbookId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot bookSnapshot = await transaction.get(bookRef);
      if (!bookSnapshot.exists) return;
      
      double currentBalance = (bookSnapshot.get('balance') ?? 0).toDouble();
      List<dynamic> history = [];
      
      // 2. DETAILED HISTORY LOGGING
      if (widget.existingEntryId != null) {
        // Edit Mode: Revert old balance
        final oldData = widget.existingData!;
        double oldAmount = (oldData['amount'] as num).toDouble();
        String oldType = oldData['type'];
        currentBalance = oldType == 'in' ? currentBalance - oldAmount : currentBalance + oldAmount;
        
        // Load existing history
        if (oldData['history'] != null) history = List.from(oldData['history']);

        // --- CHECK CHANGES ---
        final now = Timestamp.now();

        // Amount Change
        if (oldAmount != amount) {
          history.add({'field': 'Amount', 'old': oldAmount, 'new': amount, 'date': now});
        }
        // Remark Change
        if (oldData['remarks'] != _remarksCtrl.text) {
          history.add({'field': 'Remarks', 'old': oldData['remarks'], 'new': _remarksCtrl.text, 'date': now});
        }
        // Payment Change
        if (oldData['paymentMethod'] != _paymentMethod) {
          history.add({'field': 'Payment', 'old': oldData['paymentMethod'], 'new': _paymentMethod, 'date': now});
        }
        // Category Change
        if (oldData['category'] != _category) {
          history.add({'field': 'Category', 'old': oldData['category'] ?? '-', 'new': _category ?? '-', 'date': now});
        }
        // Date/Time Change
        Timestamp oldTs = oldData['date'];
        if (oldTs.toDate().compareTo(fullDate) != 0) {
           String oldTimeStr = DateFormat('MMM d, h:mm a').format(oldTs.toDate());
           String newTimeStr = DateFormat('MMM d, h:mm a').format(fullDate);
           history.add({'field': 'Date/Time', 'old': oldTimeStr, 'new': newTimeStr, 'date': now});
        }

      } else {
        // Create Mode: Initial Log
        history.add({
          'field': 'Created',
          'date': Timestamp.now(),
        });
      }

      // Calc New Balance
      double newBalance = _type == 'in' ? currentBalance + amount : currentBalance - amount;

      final data = {
        'type': _type,
        'amount': amount,
        'remarks': _remarksCtrl.text,
        'category': _category ?? '', // Allow empty
        'paymentMethod': _paymentMethod,
        'date': Timestamp.fromDate(fullDate),
        'createdAt': widget.existingData?['createdAt'] ?? FieldValue.serverTimestamp(),
        'history': history,
      };

      if (widget.existingEntryId != null) {
        transaction.update(bookRef.collection('entries').doc(widget.existingEntryId), data);
      } else {
        transaction.set(bookRef.collection('entries').doc(), data);
      }
      transaction.update(bookRef, {'balance': newBalance});
    });

    if (!mounted) return;
    if (addNew) {
      _amountCtrl.clear();
      _remarksCtrl.clear();
      setState(() {
        _category = null;
        _paymentMethod = null;
        _showErrors = false; // Reset validation
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Entry Saved! Add another.")));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIn = _type == 'in';
    final Color mainColor = isIn ? const Color(0xFF059669) : const Color(0xFFE11D48);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: Icon(PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold), color: const Color(0xFF475569)), onPressed: () => Navigator.pop(context)),
        title: Container(
          padding: const EdgeInsets.all(4),
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
            Row(children: [
              Expanded(child: _buildInputLabel("Date", _buildDatePicker())),
              const SizedBox(width: 16),
              Expanded(child: _buildInputLabel("Time", _buildTimePicker())),
            ]),
            const SizedBox(height: 24),
            
            // AMOUNT (Required)
            Text("Amount *", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Container(
              decoration: _showErrors && _amountCtrl.text.isEmpty 
                  ? BoxDecoration(border: Border.all(color: Colors.red, width: 1.5), borderRadius: BorderRadius.circular(12)) 
                  : null,
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: mainColor),
                decoration: InputDecoration(
                  prefixText: "${widget.currencySymbol} ", 
                  prefixStyle: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: mainColor), 
                  border: InputBorder.none, 
                  hintText: "0.00", 
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12)
                ),
              ),
            ),
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 24),
            
            // REMARKS (Required)
            _buildInputLabel("Remarks *", 
              TextField(
                controller: _remarksCtrl, 
                decoration: _inputDeco("What is this for?", isError: _showErrors && _remarksCtrl.text.isEmpty)
              )
            ),
            const SizedBox(height: 24),
            
            // CATEGORY (Optional - No Error State)
            _buildInputLabel("Category (Optional)", Wrap(spacing: 8, children: ['Food', 'Transport', 'Salary', 'Shopping'].map((c) => _buildChip(c, _category == c, (val) => setState(() => _category = val))).toList())),
            const SizedBox(height: 24),
            
            // PAYMENT (Required)
            _buildInputLabel("Payment Method *", 
              Container(
                padding: const EdgeInsets.all(4),
                decoration: _showErrors && _paymentMethod == null ? BoxDecoration(border: Border.all(color: Colors.red, width: 1.5), borderRadius: BorderRadius.circular(16)) : null,
                child: Wrap(spacing: 8, children: ['Cash', 'Online', 'Card'].map((c) => _buildChip(c, _paymentMethod == c, (val) => setState(() => _paymentMethod = val))).toList())
              )
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade100))),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveEntry(addNew: true),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), foregroundColor: const Color(0xFF334155), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text("Save & Add New", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveEntry(addNew: false),
                style: ElevatedButton.styleFrom(backgroundColor: mainColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 4, shadowColor: mainColor.withOpacity(0.3)),
                child: Text("Save Entry", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildToggleBtn(String text, String val) {
    bool isSelected = _type == val;
    Color activeColor = val == 'in' ? const Color(0xFF059669) : const Color(0xFFE11D48);
    return GestureDetector(
      onTap: () => setState(() => _type = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: isSelected ? activeColor : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
        child: Text(text, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? Colors.white : Colors.grey.shade500)),
      ),
    );
  }
  
  Widget _buildInputLabel(String label, Widget child) { 
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 1.0)), const SizedBox(height: 8), child]); 
  }
  
  // Updated to show Error Border
  InputDecoration _inputDeco(String hint, {bool isError = false}) { 
    return InputDecoration(
      hintText: hint, 
      filled: true, 
      fillColor: Colors.white, 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isError ? Colors.red : Colors.grey.shade200, width: isError ? 1.5 : 1)), 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isError ? Colors.red : Colors.grey.shade200, width: isError ? 1.5 : 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isError ? Colors.red : const Color(0xFF4F46E5), width: 1.5))
    ); 
  }
  
  Widget _buildChip(String label, bool isActive, Function(String) onTap) {
    final bool isIn = _type == 'in';
    final Color activeBg = isIn ? const Color(0xFF059669) : const Color(0xFFE11D48);
    final Color activeText = Colors.white;
    final Color inactiveBorder = Colors.grey.shade200;
    return GestureDetector(onTap: () => onTap(label), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isActive ? activeBg : Colors.white, border: Border.all(color: isActive ? activeBg : inactiveBorder), borderRadius: BorderRadius.circular(12), boxShadow: isActive ? [BoxShadow(color: activeBg.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : []), child: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: isActive ? activeText : Colors.grey.shade600))));
  }
  
  Widget _buildDatePicker() { return GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _selectedDate = d); }, child: Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))); }
  Widget _buildTimePicker() { return GestureDetector(onTap: () async { final t = await showTimePicker(context: context, initialTime: _selectedTime); if (t != null) setState(() => _selectedTime = t); }, child: Container(height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_selectedTime.format(context), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)))); }
}
