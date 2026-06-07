import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_service.dart';
import '../../models/models.dart';
import '../../providers/session_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/widgets.dart';
import '../AboutScreen.dart';
import 'owner_orders.dart';
import 'customers_screen.dart';
import 'owner_order_details.dart';
import '../splash_screen.dart';
import 'change_credentials_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(onNavigate: (i) => setState(() => _currentIndex = i)),
      const OwnerOrdersScreen(),
      const CustomersScreen(),
      const _MoreTab(),
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
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Customers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz_rounded),
              label: 'More'),
        ],
      ),
    );
  }
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const _DashboardTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: FirebaseService.instance.dashboardStream(),
          builder: (ctx, snap) {
            // Show error indicator if the stream itself errored (e.g. permission denied)
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Could not load dashboard data.\nCheck your connection.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: AppColors.textGrey)),
                    ],
                  ),
                ),
              );
            }
            final data = snap.data ??
                {
                  'totalCustomers': 0,
                  'totalOrders': 0,
                  'pendingOrders': 0,
                  'totalDue': 0.0,
                  'recentOrders': <StoreOrder>[],
                };
            final recentOrders =
            (data['recentOrders'] as List).cast<StoreOrder>();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dashboard',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          Text('Hamza General Store',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store_rounded,
                            color: AppColors.primary, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stats grid ─────────────────────────────────────────
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.55,
                    children: [
                      _StatCard(
                          label: 'Total Customers',
                          value: '${data['totalCustomers']}',
                          icon: Icons.people_rounded,
                          color: AppColors.primary,
                          onTap: () => onNavigate(2)),
                      _StatCard(
                          label: 'Total Orders',
                          value: '${data['totalOrders']}',
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.success,
                          onTap: () => onNavigate(1)),
                      _StatCard(
                          label: 'Pending Orders',
                          value: '${data['pendingOrders']}',
                          icon: Icons.pending_rounded,
                          color: AppColors.warning,
                          onTap: () => onNavigate(1)),
                      _StatCard(
                          label: 'Total Due',
                          value:
                          'Rs. ${(data['totalDue'] as num).toStringAsFixed(0)}',
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.error,
                          onTap: () => onNavigate(2)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Quick Actions ──────────────────────────────────────
                  SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Orders',
                          color: AppColors.primary,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.people_rounded,
                          label: 'Customers',
                          color: AppColors.success,
                          onTap: () => onNavigate(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.pending_rounded,
                          label: 'Pending',
                          color: AppColors.warning,
                          onTap: () => onNavigate(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Orders ──────────────────────────────────────
                  SectionHeader(
                    title: 'Recent Orders',
                    action: 'View All',
                    onAction: () => onNavigate(1),
                  ),
                  const SizedBox(height: 12),
                  if (recentOrders.isEmpty)
                    const EmptyState(
                        title: 'No orders yet',
                        subtitle: 'Orders from customers will appear here',
                        icon: Icons.receipt_long_outlined)
                  else
                    ...recentOrders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OrderCard(
                        order: o,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => OwnerOrderDetailsScreen(
                                    orderId: o.id))),
                        showCustomer: true,
                      ),
                    )),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── MORE TAB ─────────────────────────────────────────────────────────────────

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('More')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live owner credentials card
            StreamBuilder<Map<String, dynamic>>(
              stream: FirebaseService.instance.ownerCredentialsStream(),
              builder: (ctx, snap) {
                final data = snap.data ?? {};
                final username = data['username'] ?? '—';
                final password = data['password'] ?? '—';
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.store_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text(password,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            AppCard(
              child: Column(
                children: [
                  _MoreTile(
                    icon: Icons.store_rounded,
                    label: 'Store Info',
                    color: AppColors.primary,
                    onTap: () => _showStoreInfo(context),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _MoreTile(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change Credentials',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangeCredentialsScreen())),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _MoreTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    color: AppColors.primary,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AboutScreen())),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  _MoreTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.error,
                    onTap: () async {
                      await context.read<SessionProvider>().logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
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
      ),
    );
  }

  void _showStoreInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Store Info',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hamza General Store',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Order, Khata & Customer Management App',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textGrey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MoreTile(
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

// ─── REUSABLE WIDGETS ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 17, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textGrey)),
              ],
            ),
          ],
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

  const _QuickAction(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
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
                    color: color)),
          ],
        ),
      ),
    );
  }
}