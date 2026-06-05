import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../providers/session_provider.dart';
import '../../utils/theme.dart';
import 'order_submitted.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String customerId;
  const PlaceOrderScreen({super.key, required this.customerId});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _itemsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submitOrder() async {
    if (_itemsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter items'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    try {
      final session = context.read<SessionProvider>();
      final order = await FirebaseService.instance.createOrder(
        customerId: widget.customerId,
        customerName: session.customerName ?? '',
        customerPhone: session.customerPhone ?? '',
        itemsText: _itemsCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => OrderSubmittedScreen(orderId: order.id)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Place Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Write each item on a new line for clarity',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Items Needed',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemsCtrl,
              maxLines: 10,
              decoration: InputDecoration(
                hintText:
                    '1kg Sugar\n2 Milk Packs\nTea Packet\nCooking Oil\nBiscuits',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textLight),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes (Optional)',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special instructions...',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submitOrder,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 18),
                label: const Text('Submit Order'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  _itemsCtrl.clear();
                  _notesCtrl.clear();
                },
                child: Text('Clear List',
                    style: GoogleFonts.poppins(color: AppColors.textGrey)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
