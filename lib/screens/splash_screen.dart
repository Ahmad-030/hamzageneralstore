import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../utils/theme.dart';
import 'customer/customer_home.dart';
import 'customer/customer_login.dart';
import 'owner/owner_dashboard.dart';
import 'owner/owner_login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final session = context.read<SessionProvider>();
    await session.loadSession();
    if (!mounted) return;

    if (session.isOwner) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const OwnerDashboardScreen()));
    } else if (session.isCustomerLoggedIn) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const CustomerHomeScreen()));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const RoleSelectionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.shopping_cart_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 20),
            Text('Hamza General Store',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 6),
            Text('Order, Khata & Customer Management',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white70)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ROLE SELECTION ──────────────────────────────────────────────────────────

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.shopping_cart_rounded,
                    color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Hamza General Store',
                  style: GoogleFonts.poppins(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Who are you?',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textGrey)),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.person_rounded,
                title: 'Customer',
                subtitle: 'Place orders, view khata & history',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerLoginScreen())),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.store_rounded,
                title: 'Store Owner',
                subtitle: 'Manage orders, customers & payments',
                color: AppColors.primaryDark,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OwnerLoginScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textLight, size: 16),
          ],
        ),
      ),
    );
  }
}
