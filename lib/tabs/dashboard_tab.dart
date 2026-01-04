import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardTab extends StatelessWidget {
  final User user;

  const DashboardTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Helper to get First Name only
    final String firstName = user.displayName?.split(' ')[0] ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      // --- HEADER ---
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
            // Profile Pic with Green Dot
            Stack(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(user.photoURL ?? 'https://i.pravatar.cc/150'),
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
                      color: const Color(0xFF10B981), // Emerald 500
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
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B), // Slate 800
              ),
            ),
          ],
        ),
        actions: [
          _buildHeaderBtn(PhosphorIcons.magnifyingGlass()),
          _buildHeaderBtn(PhosphorIcons.slidersHorizontal()),
          _buildHeaderBtn(PhosphorIcons.dotsThreeCircle()),
          const SizedBox(width: 16),
        ],
      ),

      // --- BODY ---
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Your Books",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  "Sorted by Recent",
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8), // Slate 400
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- LIST ITEMS (Replicating HTML Data) ---
          
          // 1. Personal Wallet (Surplus)
          _buildBookCard(
            icon: PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
            iconColor: const Color(0xFF10B981), // Emerald
            bgIconColor: const Color(0xFFECFDF5), // Emerald 50
            title: "Personal Wallet",
            updated: "Updated 2m ago",
            amount: "+ \$840.00",
            tag: "Surplus",
            tagColor: const Color(0xFF10B981),
            tagBg: const Color(0xFFECFDF5),
          ),

          // 2. Bakery Shop (Deficit)
          _buildBookCard(
            icon: PhosphorIcons.storefront(PhosphorIconsStyle.duotone),
            iconColor: const Color(0xFFE11D48), // Rose
            bgIconColor: const Color(0xFFFFF1F2), // Rose 50
            title: "Bakery Shop",
            updated: "Updated 1h ago",
            amount: "- \$1,250.00",
            tag: "Deficit",
            tagColor: const Color(0xFFE11D48),
            tagBg: const Color(0xFFFFF1F2),
          ),

          // 3. Travel Fund (Surplus)
          _buildBookCard(
            icon: PhosphorIcons.airplane(PhosphorIconsStyle.duotone),
            iconColor: const Color(0xFF7C3AED), // Violet
            bgIconColor: const Color(0xFFF5F3FF),
            title: "Travel Fund",
            updated: "Updated Yesterday",
            amount: "+ \$3,400.00",
            tag: null, // No tag
            tagColor: Colors.transparent,
            tagBg: Colors.transparent,
          ),

           // 4. House Rent (Neutral)
          _buildBookCard(
            icon: PhosphorIcons.house(PhosphorIconsStyle.duotone),
            iconColor: const Color(0xFFEA580C), // Orange
            bgIconColor: const Color(0xFFFFF7ED),
            title: "House Rent",
            updated: "Updated 3d ago",
            amount: "\$0.00",
            amountColor: const Color(0xFF334155), // Slate 700
            tag: null,
            tagColor: Colors.transparent,
            tagBg: Colors.transparent,
          ),

          // Spacer for Bottom Nav
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---
  
  Widget _buildHeaderBtn(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        // hover effect isn't needed for mobile touch usually, but structure is here
      ),
      child: Icon(icon, color: const Color(0xFF475569), size: 20),
    );
  }

  Widget _buildBookCard({
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required String title,
    required String updated,
    required String amount,
    Color? amountColor,
    String? tag,
    required Color tagColor,
    required Color tagBg,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
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
                  color: bgIconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    updated,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: amountColor ?? (tag == "Deficit" ? const Color(0xFFE11D48) : const Color(0xFF10B981)),
                ),
              ),
              if (tag != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: tagColor.withOpacity(0.8),
                    ),
                  ),
                )
              ]
            ],
          )
        ],
      ),
    );
  }
}
