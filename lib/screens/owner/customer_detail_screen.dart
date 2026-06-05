import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import 'transaction_history_screen.dart';
import 'generate_pdf_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Details')),
      body: StreamBuilder<Customer>(
        stream: FirebaseService.instance.customerStream(customerId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingOverlay();
          }
          final customer = snap.data;
          if (customer == null) {
            return const EmptyState(
                title: 'Customer not found',
                subtitle: '',
                icon: Icons.error_outline);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(customer.name,
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(customer.phone,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textGrey)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Due amount
                AmountCard(
                    label: 'Current Due Amount', amount: customer.totalDue),
                const SizedBox(height: 16),

                // Action buttons
                AppCard(
                  child: Column(
                    children: [
                      _ActionTile(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Add Amount',
                        color: AppColors.error,
                        onTap: () => _showAddAmountDialog(context, customer),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      _ActionTile(
                        icon: Icons.payments_rounded,
                        label: 'Record Payment',
                        color: AppColors.success,
                        onTap: () =>
                            _showRecordPaymentDialog(context, customer),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      _ActionTile(
                        icon: Icons.history_rounded,
                        label: 'View Transactions',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TransactionHistoryScreen(
                                    customerId: customerId))),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      _ActionTile(
                        icon: Icons.picture_as_pdf_rounded,
                        label: 'Generate PDF',
                        color: AppColors.orange,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => GeneratePdfScreen(
                                    customer: customer))),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                      _ActionTile(
                        icon: Icons.chat,
                        label: 'Send WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () =>
                            _sendWhatsApp(context, customer),
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

  void _showAddAmountDialog(BuildContext context, Customer customer) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Amount to Khata',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount', prefixText: 'Rs. '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration:
                  const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim());
                  if (amt == null || amt <= 0) return;
                  await FirebaseService.instance.addTransaction(
                    customerId: customer.id,
                    type: TransactionType.order,
                    amount: amt,
                    reason: reasonCtrl.text.trim().isEmpty
                        ? 'Manual entry'
                        : reasonCtrl.text.trim(),
                  );
                  await FirebaseService.instance
                      .updateCustomerDue(customer.id, amt);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentDialog(BuildContext context, Customer customer) {
    final amountCtrl = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record Payment',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  'Current Due: Rs. ${customer.totalDue.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.error)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Payment Amount', prefixText: 'Rs. '),
              ),
              const SizedBox(height: 12),
              Text('Payment Method',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PaymentMethod.values.map((m) {
                  final sel = method == m;
                  return GestureDetector(
                    onTap: () => setS(() => method = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : AppColors.white,
                        border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.border),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(m.label,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: sel ? Colors.white : AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final amt =
                        double.tryParse(amountCtrl.text.trim());
                    if (amt == null || amt <= 0) return;
                    await FirebaseService.instance.addTransaction(
                      customerId: customer.id,
                      type: TransactionType.payment,
                      amount: amt,
                      reason: 'Payment received (${method.label})',
                      paymentMethod: method,
                    );
                    await FirebaseService.instance
                        .updateCustomerDue(customer.id, -amt);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save Payment'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWhatsApp(
      BuildContext context, Customer customer) async {
    final msg = Uri.encodeComponent(
        'Hello ${customer.name},\nYour current balance at Hamza General Store is Rs. ${customer.totalDue.toStringAsFixed(0)}.\nPlease clear your dues. Thank you!');
    final phone = customer.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: AppColors.error));
      }
    }
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}
