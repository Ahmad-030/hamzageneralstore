import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../providers/session_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../AboutScreen.dart';
import '../splash_screen.dart';
import 'ContactStoreScreen.dart';

class ProfileScreen extends StatelessWidget {
  final String customerId;
  const ProfileScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<Customer>(
        stream: FirebaseService.instance.customerStream(customerId),
        builder: (ctx, snap) {
          final customer = snap.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          (session.customerName ?? 'A')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        session.customerName ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        session.customerPhone ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Info Card
                AppCard(
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Name',
                          value: session.customerName ?? ''),
                      const Divider(color: AppColors.border),
                      _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: session.customerPhone ?? ''),
                      if (customer != null) ...[
                        const Divider(color: AppColors.border),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: DateFormat('MMMM yyyy')
                              .format(customer.memberSince),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StoreActionButton(
                        icon: Icons.headset_mic_rounded,
                        label: 'Contact Store',
                        color: const Color(0xFF25D366),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ContactStoreScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StoreActionButton(
                        icon: Icons.info_outline_rounded,
                        label: 'About App',
                        color: AppColors.primaryDark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutScreen())),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20,),
                // Actions
                AppCard(
                  child: Column(
                    children: [
                      _ActionRow(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        color: AppColors.error,
                        onTap: () async {
                          await context.read<SessionProvider>().logout();
                          if (!ctx.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) => const SplashScreen()),
                            (r) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textGrey)),
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StoreActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StoreActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}