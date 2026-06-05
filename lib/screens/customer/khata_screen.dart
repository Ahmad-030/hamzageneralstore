import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';

class KhataScreen extends StatefulWidget {
  final String customerId;
  const KhataScreen({super.key, required this.customerId});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  int _filterIndex = 0; // 0=All, 1=Payments, 2=Orders

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Khata History')),
      body: Column(
        children: [
          // Balance card
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<Customer>(
              stream: FirebaseService.instance
                  .customerStream(widget.customerId),
              builder: (ctx, snap) {
                final due = snap.data?.totalDue ?? 0;
                return AmountCard(
                    label: 'Current Due Amount', amount: due);
              },
            ),
          ),
          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Added to Khata', 'Payments']
                  .asMap()
                  .entries
                  .map((e) => GestureDetector(
                        onTap: () =>
                            setState(() => _filterIndex = e.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _filterIndex == e.key
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: _filterIndex == e.key
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Text(e.value,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _filterIndex == e.key
                                    ? Colors.white
                                    : AppColors.textGrey,
                              )),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Transactions list
          Expanded(
            child: StreamBuilder<List<KhataTransaction>>(
              stream: FirebaseService.instance
                  .customerTransactionsStream(widget.customerId),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingOverlay();
                }
                var txs = snap.data ?? [];
                if (_filterIndex == 1) {
                  txs = txs
                      .where((t) => t.type == TransactionType.order)
                      .toList();
                } else if (_filterIndex == 2) {
                  txs = txs
                      .where((t) => t.type == TransactionType.payment)
                      .toList();
                }
                if (txs.isEmpty) {
                  return const EmptyState(
                      title: 'No transactions',
                      subtitle: 'Your khata history will appear here',
                      icon: Icons.account_balance_wallet_outlined);
                }

                // Summary
                final totalAdded = txs
                    .where((t) => t.type == TransactionType.order)
                    .fold(0.0, (sum, t) => sum + t.amount);
                final totalPaid = txs
                    .where((t) => t.type == TransactionType.payment)
                    .fold(0.0, (sum, t) => sum + t.amount);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                                label: 'Total Added',
                                amount: totalAdded,
                                color: AppColors.error),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                                label: 'Total Paid',
                                amount: totalPaid,
                                color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: txs.length,
                        separatorBuilder: (_, __) => const Divider(
                            color: AppColors.border, height: 1),
                        itemBuilder: (ctx, i) =>
                            TransactionTile(txs[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.textGrey)),
          Text('Rs. ${amount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
