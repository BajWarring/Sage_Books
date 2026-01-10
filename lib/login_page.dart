import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isPasswordVisible = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      print("Success! Signed in as: ${googleUser.displayName}");
      // NO NAVIGATION CODE HERE - main.dart handles it

    } catch (e) {
      print("Error signing in: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC), 
          image: DecorationImage(image: NetworkImage("https://grainy-gradients.vercel.app/noise.svg"), fit: BoxFit.cover, opacity: 0.05),
        ),
        child: Stack(
          children: [
            Positioned(top: 40, right: 40, child: _buildBlurBlob(Colors.indigo.shade200.withOpacity(0.4))),
            Positioned(bottom: 80, left: 40, child: _buildBlurBlob(Colors.pink.shade200.withOpacity(0.4))),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 350),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 50, offset: const Offset(0, 25))]),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 200, height: 200, child: Lottie.asset('assets/animations/paperplane.json', fit: BoxFit.contain)),
                                Text("Welcome", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                                const SizedBox(height: 24),
                                _buildInput(icon: PhosphorIcons.envelopeSimple(PhosphorIconsStyle.bold), hint: "Email"),
                                const SizedBox(height: 14),
                                _buildInput(icon: PhosphorIcons.lockKey(PhosphorIconsStyle.bold), hint: "Password", isPassword: true),
                                Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: Text("Forgot Password?", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))))),
                                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4F46E5), elevation: 4, shadowColor: const Color(0xFFC7D2FE), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text("Login", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)))),
                                Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Row(children: [Expanded(child: Divider(color: Colors.grey.shade200)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("OR", style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8)))), Expanded(child: Divider(color: Colors.grey.shade200))])),
                                SizedBox(width: double.infinity, height: 48, child: OutlinedButton.icon(onPressed: _handleGoogleSignIn, icon: SizedBox(width: 18, height: 18, child: Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png')), label: Text("Continue with Google", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF334155), fontSize: 12)), style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE2E8F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                                const SizedBox(height: 24),
                                Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account?", style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)), TextButton(onPressed: () {}, child: Text("Sign up", style: GoogleFonts.outfit(color: const Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)))]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required IconData icon, required String hint, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        obscureText: isPassword ? !_isPasswordVisible : false,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(_isPasswordVisible ? PhosphorIcons.eye(PhosphorIconsStyle.bold) : PhosphorIcons.eyeSlash(PhosphorIconsStyle.bold), color: const Color(0xFF94A3B8)), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)) : null,
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBlurBlob(Color color) {
    return Container(width: 140, height: 140, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent)));
  }
}
