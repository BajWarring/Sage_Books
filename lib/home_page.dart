import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sage_books/tabs/dashboard_tab.dart';
import 'package:sage_books/tabs/settings_tab.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. The Content Layer
          IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardTab(user: widget.user),
              SettingsTab(user: widget.user),
            ],
          ),

          // 2. The Bottom Navigation Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavOneItem("Cashbooks", PhosphorIcons.notebook(PhosphorIconsStyle.bold), 0),
                  _buildNavOneItem("Settings", PhosphorIcons.gear(PhosphorIconsStyle.bold), 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavOneItem(String label, IconData icon, int index) {
    bool isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 48,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent, 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                size: 20,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 80 : 0,
                child: ClipRect(
                  child: Center(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
