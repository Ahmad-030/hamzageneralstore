import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/theme.dart';
import 'customer_home.dart';
import 'my_orders.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';

class OrderSubmittedScreen extends StatelessWidget {
  final String orderId;
  const OrderSubmittedScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final session = context.read<SessionProvider>();
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 64),
              ),
              const SizedBox(height: 28),
              Text('Order Submitted\nSuccessfully!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      height: 1.3)),
              const SizedBox(height: 12),
              Text(
                'We have received your order\nand will process it soon.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.textGrey, height: 1.6),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            MyOrdersScreen(customerId: session.customerId!)),
                    (r) => false,
                  ),
                  child: const Text('View Orders'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerHomeScreen()),
                    (r) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Back to Home',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
