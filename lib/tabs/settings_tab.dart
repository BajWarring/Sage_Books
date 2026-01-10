import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SettingsTab extends StatelessWidget {
  final User user;

  const SettingsTab({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.disconnect();
      }
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error signing out: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text("Settings", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
        actions: [
          Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 20), decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle), child: Icon(PhosphorIcons.bell(PhosphorIconsStyle.bold), size: 20, color: const Color(0xFF64748B)))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(user.photoURL ?? 'https://i.pravatar.cc/150', width: 56, height: 56, fit: BoxFit.cover)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.displayName ?? "User Name", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                      Text(user.email ?? "no-email@example.com", style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF94A3B8))),
                  ]),
                ),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)), child: Text("Edit", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF4F46E5))))
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Account"),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildListItem(icon: PhosphorIcons.user(PhosphorIconsStyle.fill), color: const Color(0xFF4F46E5), bgColor: const Color(0xFFEEF2FF), text: "Profile", isLast: false),
                _buildListItem(icon: PhosphorIcons.crown(PhosphorIconsStyle.fill), color: const Color(0xFF9333EA), bgColor: const Color(0xFFFAF5FF), text: "Premium Plan", isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("App Settings"),
          Container(
            decoration: _boxDecoration(),
            child: Column(
              children: [
                _buildListItem(icon: PhosphorIcons.gear(PhosphorIconsStyle.fill), color: const Color(0xFF2563EB), bgColor: const Color(0xFFEFF6FF), text: "General Preferences", isLast: false),
                _buildListItem(icon: PhosphorIcons.database(PhosphorIconsStyle.fill), color: const Color(0xFF10B981), bgColor: const Color(0xFFECFDF5), text: "Data Management", isLast: false),
                _buildListItem(icon: PhosphorIcons.moon(PhosphorIconsStyle.fill), color: const Color(0xFF475569), bgColor: const Color(0xFFF1F5F9), text: "Dark Mode", isLast: true, hasSwitch: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Support"),
           Container(
            decoration: _boxDecoration(),
            child: _buildListItem(icon: PhosphorIcons.lifebuoy(PhosphorIconsStyle.fill), color: const Color(0xFFE11D48), bgColor: const Color(0xFFFFF1F2), text: "Help & Support", isLast: true),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _signOut(context),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(16)), child: Center(child: Text("Log Out", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFE11D48))))),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Text(title.toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1.0)));
  }

  Widget _buildListItem({required IconData icon, required Color color, required Color bgColor, required String text, required bool isLast, bool hasSwitch = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: const Color(0xFFF8FAFC)))),
      child: Row(
        children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155)))),
          if (hasSwitch) Container(width: 40, height: 24, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)), child: Stack(children: [Positioned(left: 4, top: 4, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)))])) else Icon(PhosphorIcons.caretRight(PhosphorIconsStyle.bold), size: 16, color: const Color(0xFFCBD5E1))
        ],
      ),
    );
  }
}
