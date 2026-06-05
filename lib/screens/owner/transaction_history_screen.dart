import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String customerId;
  const TransactionHistoryScreen({super.key, required this.customerId});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transaction History')),
      body: StreamBuilder<List<KhataTransaction>>(
        stream: FirebaseService.instance
            .customerTransactionsStream(widget.customerId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingOverlay();
          }
          var txs = snap.data ?? [];
          final totalAdded = txs
              .where((t) => t.type == TransactionType.order)
              .fold(0.0, (s, t) => s + t.amount);
          final totalPaid = txs
              .where((t) => t.type == TransactionType.payment)
              .fold(0.0, (s, t) => s + t.amount);
          final due = totalAdded - totalPaid;

          if (_filter == 1) {
            txs =
                txs.where((t) => t.type == TransactionType.order).toList();
          } else if (_filter == 2) {
            txs = txs
                .where((t) => t.type == TransactionType.payment)
                .toList();
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                        child: _SummaryCard(
                            label: 'Total Added',
                            value: 'Rs. ${totalAdded.toStringAsFixed(0)}',
                            color: AppColors.error)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _SummaryCard(
                            label: 'Total Paid',
                            value: 'Rs. ${totalPaid.toStringAsFixed(0)}',
                            color: AppColors.success)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _SummaryCard(
                            label: 'Current Due',
                            value: 'Rs. ${due.toStringAsFixed(0)}',
                            color: AppColors.primary)),
                  ],
                ),
              ),
              // Filter tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _tab('All', 0),
                    _tab('Added', 1),
                    _tab('Payments', 2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: txs.isEmpty
                    ? const EmptyState(
                        title: 'No transactions',
                        subtitle: 'Nothing to show here',
                        icon: Icons.history_rounded)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: AppColors.border, height: 1),
                        itemBuilder: (ctx, i) => TransactionTile(txs[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(String label, int index) {
    final sel = _filter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = index),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: sel ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: sel ? Colors.white : AppColors.textGrey,
              )),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: AppColors.textGrey)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
