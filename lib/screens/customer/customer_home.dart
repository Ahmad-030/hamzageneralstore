import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../providers/session_provider.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import 'place_order.dart';
import 'my_orders.dart';
import 'khata_screen.dart';
import 'profile_screen.dart';
import 'order_details.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final pages = [
      _HomeTab(
        customerId: session.customerId!,
        onNavigate: (i) => setState(() => _currentIndex = i),
      ),
      MyOrdersScreen(customerId: session.customerId!),
      KhataScreen(customerId: session.customerId!),
      ProfileScreen(customerId: session.customerId!),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle:
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Khata'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final String customerId;
  final void Function(int) onNavigate;
  const _HomeTab({required this.customerId, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome 👋',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textGrey)),
                      Text(session.customerName ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => onNavigate(3),
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        (session.customerName ?? 'A')[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Balance Card ─────────────────────────────────────────────
              StreamBuilder<Customer>(
                stream:
                    FirebaseService.instance.customerStream(customerId),
                builder: (ctx, snap) {
                  final due = snap.data?.totalDue ?? 0;
                  return GestureDetector(
                    onTap: () => onNavigate(2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Outstanding Balance',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text('Rs. ${due.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            'Last updated: ${DateFormat('d MMM yyyy').format(DateTime.now())}',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white60),
                          ),
                          const SizedBox(height: 12),
                          Text('View Khata →',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────────────────────
              Text('Quick Actions',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_shopping_cart_rounded,
                      label: 'Place\nOrder',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PlaceOrderScreen(customerId: customerId))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.receipt_long_rounded,
                      label: 'My\nOrders',
                      color: AppColors.orange,
                      onTap: () => onNavigate(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Khata\nHistory',
                      color: AppColors.success,
                      onTap: () => onNavigate(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Recent Activity ──────────────────────────────────────────
              SectionHeader(
                title: 'Recent Activity',
                action: 'See All',
                onAction: () => onNavigate(1),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<StoreOrder>>(
                stream: FirebaseService.instance
                    .customerOrdersStream(customerId),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: LoadingOverlay(),
                    );
                  }
                  final orders = snap.data ?? [];
                  if (orders.isEmpty) {
                    return const EmptyState(
                      title: 'No activity yet',
                      subtitle: 'Place your first order!',
                      icon: Icons.shopping_bag_outlined,
                    );
                  }
                  return Column(
                    children: orders
                        .take(3)
                        .map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: OrderCard(
                                order: o,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            CustomerOrderDetailsScreen(
                                                orderId: o.id))),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
