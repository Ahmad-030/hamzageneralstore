import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textGrey),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: FirebaseService.instance.customersStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const LoadingOverlay();
                }
                var customers = snap.data ?? [];
                if (_search.isNotEmpty) {
                  final q = _search.toLowerCase();
                  customers = customers
                      .where((c) =>
                          c.name.toLowerCase().contains(q) ||
                          c.phone.toLowerCase().contains(q))
                      .toList();
                }
                if (customers.isEmpty) {
                  return const EmptyState(
                    title: 'No customers yet',
                    subtitle: 'Customers will appear once they log in',
                    icon: Icons.people_outline_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final c = customers[i];
                    return AppCard(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailScreen(customerId: c.id))),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              c.name[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600)),
                                Text(c.phone,
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rs. ${c.totalDue.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.totalDue > 0
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                              Text('due',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textLight)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
