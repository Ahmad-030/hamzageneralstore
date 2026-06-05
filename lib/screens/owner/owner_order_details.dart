import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class OwnerOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const OwnerOrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<StoreOrder?>(
        stream: FirebaseService.instance.orderStream(orderId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingOverlay();
          }
          final order = snap.data;
          if (order == null) {
            return const EmptyState(
                title: 'Order not found',
                subtitle: '',
                icon: Icons.error_outline);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textGrey)),
                      const SizedBox(height: 6),
                      Text(order.customerName,
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(order.customerPhone,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textGrey)),
                      const SizedBox(height: 8),
                      StreamBuilder<Customer>(
                        stream: FirebaseService.instance
                            .customerStream(order.customerId),
                        builder: (ctx, csnap) {
                          final due = csnap.data?.totalDue ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Current Due: Rs. ${due.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Order info
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order ${order.orderNumber}',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          StatusBadge(order.status),
                        ],
                      ),
                      Text(
                        DateFormat('d MMM yyyy • hh:mm a')
                            .format(order.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textGrey),
                      ),
                      const Divider(height: 20, color: AppColors.border),
                      Text('Items Requested',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      ...order.itemsList.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.circle,
                                    size: 6, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(item,
                                    style:
                                        GoogleFonts.poppins(fontSize: 13)),
                              ],
                            ),
                          )),
                      if (order.notes != null &&
                          order.notes!.isNotEmpty) ...[
                        const Divider(height: 20, color: AppColors.border),
                        Text('Notes: ${order.notes}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons based on status
                _buildActionButtons(context, order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, StoreOrder order) {
    switch (order.status) {
      case OrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus(
                    context, order.id, OrderStatus.rejected),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                child: Text('Reject',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(
                    context, order.id, OrderStatus.accepted),
                child: Text('Accept',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
      case OrderStatus.accepted:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(
                context, order.id, OrderStatus.preparing),
            icon: const Icon(Icons.food_bank_sharp, size: 18),
            label: const Text('Mark Preparing'),
          ),
        );
      case OrderStatus.preparing:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProcessOrderScreen(order: order)),
            ),
            icon: const Icon(Icons.local_shipping_rounded, size: 18),
            label: const Text('Mark Delivered'),
          ),
        );
      case OrderStatus.delivered:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text('Order Delivered',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success)),
              if (order.totalAmount != null)
                Text(
                  ' • Rs. ${order.totalAmount!.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.success),
                ),
            ],
          ),
        );
      case OrderStatus.rejected:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel_rounded,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text('Order Rejected',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error)),
            ],
          ),
        );
    }
  }

  Future<void> _updateStatus(
      BuildContext context, String orderId, OrderStatus status) async {
    try {
      await FirebaseService.instance.updateOrderStatus(orderId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order ${status.label}'),
          backgroundColor: status.color,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error));
      }
    }
  }
}

// ─── PROCESS ORDER ───────────────────────────────────────────────────────────

class ProcessOrderScreen extends StatefulWidget {
  final StoreOrder order;
  const ProcessOrderScreen({super.key, required this.order});

  @override
  State<ProcessOrderScreen> createState() => _ProcessOrderScreenState();
}

class _ProcessOrderScreenState extends State<ProcessOrderScreen> {
  final _amountCtrl = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _addToKhata = false;
  bool _loading = false;

  Future<void> _confirm() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    try {
      // Mark delivered
      await FirebaseService.instance.updateOrderWithAmount(
          widget.order.id, amount, _addToKhata ? null : _method);

      // Add transaction
      if (_addToKhata) {
        await FirebaseService.instance.addTransaction(
          customerId: widget.order.customerId,
          type: TransactionType.order,
          amount: amount,
          reason: 'Order ${widget.order.orderNumber}',
          orderId: widget.order.id,
        );
        await FirebaseService.instance
            .updateCustomerDue(widget.order.customerId, amount);
      } else {
        await FirebaseService.instance.addTransaction(
          customerId: widget.order.customerId,
          type: TransactionType.payment,
          amount: amount,
          reason: 'Paid for Order ${widget.order.orderNumber}',
          orderId: widget.order.id,
          paymentMethod: _method,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order processed successfully'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Process Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivered banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                  const SizedBox(width: 10),
                  Text('Order Delivered',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.success)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Order Total Amount',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: 'Rs. 1,500',
                prefixText: 'Rs. ',
              ),
            ),
            const SizedBox(height: 20),
            Text('Choose an option',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            // Paid Instantly
            GestureDetector(
              onTap: () => setState(() => _addToKhata = false),
              child: AppCard(
                color: !_addToKhata
                    ? AppColors.primaryLight
                    : AppColors.white,
                child: Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _addToKhata,
                      onChanged: (v) =>
                          setState(() => _addToKhata = false),
                      activeColor: AppColors.primary,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paid Instantly',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('Customer paid the amount',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (!_addToKhata) ...[
              ...PaymentMethod.values.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _method = m),
                      child: AppCard(
                        color: _method == m
                            ? AppColors.primaryLight
                            : AppColors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Radio<PaymentMethod>(
                              value: m,
                              groupValue: _method,
                              onChanged: (v) =>
                                  setState(() => _method = v!),
                              activeColor: AppColors.primary,
                            ),
                            Icon(m.icon,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text(m.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 6),
            ],
            // Add to Khata
            GestureDetector(
              onTap: () => setState(() => _addToKhata = true),
              child: AppCard(
                color:
                    _addToKhata ? AppColors.primaryLight : AppColors.white,
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _addToKhata,
                      onChanged: (v) => setState(() => _addToKhata = true),
                      activeColor: AppColors.primary,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add to Khata',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        Text('Add amount in customer khata',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirm,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
