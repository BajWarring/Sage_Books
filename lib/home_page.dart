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

          // 2. The Bottom Navigation Bar (Custom implementation)
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

          // 3. Floating Action Button (FAB)
          // Only show on Cashbooks tab (Index 0)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            bottom: _selectedIndex == 0 ? 100 : 24, // Moves down if hidden
            right: 20,
            child: AnimatedScale(
              scale: _selectedIndex == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Slate 900
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCBD5E1), // Slate 300 shadow
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                     // Open Modal logic here (Future implementation)
                  },
                  icon: Icon(PhosphorIcons.plus(PhosphorIconsStyle.bold), color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Nav Item to match HTML animation
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
            color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent, // Indigo 50
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8), // Indigo 600 vs Slate 400
                size: 20,
              ),
              // Animate text width
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 80 : 0, // Expands or shrinks
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
