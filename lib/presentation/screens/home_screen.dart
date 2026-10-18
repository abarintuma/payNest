import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/core/utils/app_utils.dart';
import 'package:paynest/core/widgets/common_widgets.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/repositories/repositories.dart';
import 'package:paynest/presentation/providers/providers.dart';
import 'package:paynest/presentation/screens/pos/pos_screen.dart';
import 'package:paynest/presentation/screens/inventory/inventory_screen.dart';
import 'package:paynest/presentation/screens/customers/customers_screen.dart';
import 'package:paynest/presentation/screens/reports/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const POSScreen(),
    const InventoryScreen(),
    const CustomersScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.point_of_sale_rounded,
                label: 'POS',
                isSelected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
                isPrimary: true,
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Inventory',
                isSelected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Customers',
                isSelected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                isSelected: _currentIndex == 4,
                onTap: () => setState(() => _currentIndex = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPrimary;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Icon(icon, color: isSelected ? Colors.white : AppColors.primary, size: 28),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== DASHBOARD TAB ==================
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final _txnRepo = TransactionRepository();
  final _productRepo = ProductRepository();

  Map<String, dynamic> _stats = {};
  List<Product> _lowStock = [];
  List<Transaction> _recentTxns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _txnRepo.getRevenueStats();
      final lowStock = await _productRepo.getLowStockProducts();
      final txns = await _txnRepo.getAllTransactions();
      if (mounted) {
        setState(() {
          _stats = stats;
          _lowStock = lowStock;
          _recentTxns = txns.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12, bottom: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.point_of_sale_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppUtils.getGreeting()} 👋',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              settings.businessName,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Revenue Hero Card
                    _buildRevenueHeroCard(settings),
                    const SizedBox(height: 20),

                    // Stats Grid
                    _buildStatsGrid(settings),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Low Stock Alert
                    if (_lowStock.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Low Stock Alert',
                        action: 'View All',
                        onAction: () {},
                      ),
                      const SizedBox(height: 12),
                      _buildLowStockSection(),
                      const SizedBox(height: 24),
                    ],

                    // Recent Transactions
                    SectionHeader(
                      title: 'Recent Sales',
                      action: 'View All',
                      onAction: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTransactions(settings),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueHeroCard(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Revenue',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      AppUtils.formatDate(DateTime.now()),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppUtils.formatCurrency(
              (_stats['todayRevenue'] as num?)?.toDouble() ?? 0,
              symbol: settings.currencySymbol,
            ),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.shopping_cart_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${_stats['todayCount'] ?? 0} transactions today',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroStat(
                label: 'This Month',
                value: AppUtils.formatCurrency(
                  (_stats['monthRevenue'] as num?)?.toDouble() ?? 0,
                  symbol: settings.currencySymbol,
                ),
              ),
              _HeroStat(
                label: 'All Time',
                value: AppUtils.formatCurrency(
                  (_stats['totalRevenue'] as num?)?.toDouble() ?? 0,
                  symbol: settings.currencySymbol,
                ),
              ),
              _HeroStat(
                label: 'Total Orders',
                value: '${_stats['totalCount'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsGrid(AppSettings settings) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        StatCard(
          title: 'Total Products',
          value: '${context.read<ProductProvider>().allProducts.length}',
          icon: Icons.inventory_2_rounded,
          color: AppColors.info,
          changePercent: 5.2,
        ),
        StatCard(
          title: 'Customers',
          value: '${context.read<CustomerProvider>().customers.length}',
          icon: Icons.people_rounded,
          color: AppColors.secondary,
          changePercent: 12.0,
        ),
        StatCard(
          title: 'Low Stock',
          value: '${_lowStock.length}',
          subtitle: 'Need attention',
          icon: Icons.warning_amber_rounded,
          color: AppColors.warning,
        ),
        StatCard(
          title: 'Monthly Sales',
          value: '${_stats['monthCount'] ?? 0}',
          icon: Icons.trending_up_rounded,
          color: AppColors.success,
          changePercent: 8.5,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_shopping_cart_rounded,
            label: 'New Sale',
            color: AppColors.primary,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.add_box_rounded,
            label: 'Add Product',
            color: AppColors.secondary,
            onTap: () => Navigator.pushNamed(context, AppConstants.routeAddProduct),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.person_add_rounded,
            label: 'Add Customer',
            color: AppColors.accent,
            onTap: () => Navigator.pushNamed(context, AppConstants.routeAddCustomer),
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockSection() {
    return Column(
      children: _lowStock.take(3).map((product) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                    Text(
                      '${product.stockQuantity} units remaining',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: AppUtils.getStockStatus(product.stockQuantity),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(AppSettings settings) {
    if (_recentTxns.isEmpty) {
      return const EmptyState(
        title: 'No Transactions Yet',
        message: 'Start making sales to see them here',
        icon: Icons.receipt_long_rounded,
      );
    }

    return Column(
      children: _recentTxns.map((txn) => _TransactionTile(txn: txn, settings: settings)).toList(),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  final AppSettings settings;

  const _TransactionTile({required this.txn, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData payIcon;
    Color payColor;
    switch (txn.paymentMethod) {
      case AppConstants.paymentCard:
        payIcon = Icons.credit_card_rounded;
        payColor = AppColors.cardColor;
        break;
      case AppConstants.paymentMtnMomo:
        payIcon = Icons.phone_android_rounded;
        payColor = AppColors.mtnMomoColor;
        break;
      case AppConstants.paymentAirtelMoney:
        payIcon = Icons.contactless_rounded;
        payColor = AppColors.airtelMoneyColor;
        break;
      case AppConstants.paymentMpesa:
        payIcon = Icons.phone_android_rounded;
        payColor = AppColors.mpesaColor;
        break;
      case AppConstants.paymentBank:
        payIcon = Icons.account_balance_rounded;
        payColor = AppColors.bankColor;
        break;
      default:
        payIcon = Icons.payments_rounded;
        payColor = AppColors.cashColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: payColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(payIcon, color: payColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.receiptNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
                Text(
                  '${txn.items.length} items • ${AppUtils.timeAgo(txn.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppUtils.formatCurrency(txn.total, symbol: settings.currencySymbol),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StatusBadge(label: txn.status),
            ],
          ),
        ],
      ),
    );
  }
}
