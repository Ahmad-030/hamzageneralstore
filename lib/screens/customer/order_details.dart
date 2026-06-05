import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class CustomerOrderDetailsScreen extends StatelessWidget {
  final String orderId;
  const CustomerOrderDetailsScreen({super.key, required this.orderId});

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
                title: 'Order not found', subtitle: '', icon: Icons.error_outline);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order ${order.orderNumber}',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          StatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM yyyy • hh:mm a')
                            .format(order.createdAt),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textGrey),
                      ),
                      if (order.totalAmount != null) ...[
                        const SizedBox(height: 8),
                        Text('Total: Rs. ${order.totalAmount!.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Items
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items Requested',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ...order.itemsList.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Text(item,
                                    style: GoogleFonts.poppins(fontSize: 14)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Timeline
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Status',
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      _timeline(order.status),
                    ],
                  ),
                ),
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes',
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(order.notes!,
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.textGrey)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timeline(OrderStatus currentStatus) {
    final steps = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.delivered,
    ];
    if (currentStatus == OrderStatus.rejected) {
      return _timelineStep('Order Rejected', true, AppColors.error, isLast: true);
    }
    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final s = entry.value;
        final reached = steps.indexOf(currentStatus) >= i;
        return _timelineStep(
          s.label,
          reached,
          reached ? AppColors.primary : AppColors.border,
          isLast: i == steps.length - 1,
        );
      }).toList(),
    );
  }

  Widget _timelineStep(String label, bool done, Color color,
      {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done ? color : AppColors.white,
                border: Border.all(color: color, width: 2),
                shape: BoxShape.circle,
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                  width: 2,
                  height: 28,
                  color: done ? color : AppColors.border),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? AppColors.textDark : AppColors.textLight)),
        ),
      ],
    );
  }
}
