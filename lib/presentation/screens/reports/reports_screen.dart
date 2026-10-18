import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/core/utils/app_utils.dart';
import 'package:paynest/core/widgets/common_widgets.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/repositories/repositories.dart';
import 'package:paynest/presentation/providers/providers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _txnRepo = TransactionRepository();
  final _productRepo = ProductRepository();
  final _customerRepo = CustomerRepository();

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _weeklySales = [];
  List<Product> _allProducts = [];
  List<Customer> _topCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _txnRepo.getRevenueStats();
      final weekly = await _txnRepo.getWeeklySales();
      final products = await _productRepo.getAllProducts();
      final customers = await _customerRepo.getTopCustomers(limit: 5);
      if (mounted) {
        setState(() {
          _stats = stats;
          _weeklySales = weekly;
          _allProducts = products; // all products, not capped
          _topCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: 0,
            title: const Text('Analytics & Reports'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: _loadData,
              ),
              IconButton(
                icon: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondaryLight,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Sales'),
                Tab(text: 'Products'),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(stats: _stats, settings: settings, weeklySales: _weeklySales, topCustomers: _topCustomers),
                  _SalesTab(stats: _stats, settings: settings, weeklySales: _weeklySales),
                  _ProductsTab(products: _allProducts, settings: settings),
                ],
              ),
      ),
    );
  }
}

// ===== OVERVIEW TAB =====
class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AppSettings settings;
  final List<Map<String, dynamic>> weeklySales;
  final List<Customer> topCustomers;

  const _OverviewTab({
    required this.stats,
    required this.settings,
    required this.weeklySales,
    required this.topCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  title: 'Today\'s Revenue',
                  value: AppUtils.formatCurrency(
                    (stats['todayRevenue'] as num?)?.toDouble() ?? 0,
                    symbol: settings.currencySymbol,
                  ),
                  subtitle: '${stats['todayCount'] ?? 0} sales',
                  icon: Icons.today_rounded,
                  color: AppColors.primary,
                  changePercent: 12.5,
                ),
                StatCard(
                  title: 'Monthly Revenue',
                  value: AppUtils.formatCurrency(
                    (stats['monthRevenue'] as num?)?.toDouble() ?? 0,
                    symbol: settings.currencySymbol,
                  ),
                  subtitle: '${stats['monthCount'] ?? 0} sales',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.secondary,
                  changePercent: 8.3,
                ),
                StatCard(
                  title: 'Total Revenue',
                  value: AppUtils.formatCurrency(
                    (stats['totalRevenue'] as num?)?.toDouble() ?? 0,
                    symbol: settings.currencySymbol,
                  ),
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
                StatCard(
                  title: 'Total Transactions',
                  value: '${stats['totalCount'] ?? 0}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.info,
                ),
              ],
            ).animate().fadeIn(),
            const SizedBox(height: 24),

            // Weekly chart
            const SectionHeader(title: 'Weekly Sales Trend'),
            const SizedBox(height: 16),
            _WeeklySalesChart(weeklySales: weeklySales, settings: settings),
            const SizedBox(height: 24),

            // Top Customers
            const SectionHeader(title: 'Top Customers'),
            const SizedBox(height: 12),
            if (topCustomers.isEmpty)
              const Center(child: Text('No customer data yet'))
            else
              ...topCustomers.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.cardDark
                        : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#${i + 1}',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.secondary.withOpacity(0.15),
                        child: Text(c.initials, style: GoogleFonts.poppins(color: AppColors.secondary, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(c.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                      ),
                      Text(
                        AppUtils.formatCurrency(c.totalSpent, symbol: settings.currencySymbol),
                        style: GoogleFonts.poppins(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _WeeklySalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklySales;
  final AppSettings settings;

  const _WeeklySalesChart({required this.weeklySales, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (weeklySales.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: const Center(
          child: Text('No sales data for this period'),
        ),
      );
    }

    final spots = weeklySales.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['revenue'] as num?)?.toDouble() ?? 0);
    }).toList();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= weeklySales.length) return const SizedBox();
                  final date = weeklySales[value.toInt()]['date'] as String? ?? '';
                  final parts = date.split('-');
                  final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : date;
                  return Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondaryLight));
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (weeklySales.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== SALES TAB =====
class _SalesTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final AppSettings settings;
  final List<Map<String, dynamic>> weeklySales;

  const _SalesTab({required this.stats, required this.settings, required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: TransactionRepository().getAllTransactions(),
      builder: (context, snap) {
        final txns = snap.data ?? [];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Payment method breakdown
        final paymentBreakdown = <String, double>{};
        for (final txn in txns) {
          paymentBreakdown[txn.paymentMethod] =
              (paymentBreakdown[txn.paymentMethod] ?? 0) + txn.total;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment breakdown chart
              const SectionHeader(title: 'Payment Methods'),
              const SizedBox(height: 16),
              if (paymentBreakdown.isNotEmpty)
                Container(
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: paymentBreakdown.entries.map((e) {
                        final colors = {
                          'Cash': AppColors.cashColor,
                          'Card': AppColors.cardColor,
                          'MTN MoMo': AppColors.mtnMomoColor,
                          'Airtel Money': AppColors.airtelMoneyColor,
                          'M-Pesa': AppColors.mpesaColor,
                          'Bank Transfer': AppColors.bankColor,
                        };
                        final color = colors[e.key] ?? AppColors.primary;
                        final total = paymentBreakdown.values.fold(0.0, (a, b) => a + b);
                        final pct = total > 0 ? (e.value / total) * 100 : 0;
                        return PieChartSectionData(
                          value: e.value,
                          title: '${pct.toStringAsFixed(0)}%',
                          color: color,
                          radius: 60,
                          titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              ...paymentBreakdown.entries.map((e) {
                final colors = {
                  'Cash': AppColors.cashColor,
                  'Card': AppColors.cardColor,
                  'MTN MoMo': AppColors.mtnMomoColor,
                  'Airtel Money': AppColors.airtelMoneyColor,
                  'M-Pesa': AppColors.mpesaColor,
                  'Bank Transfer': AppColors.bankColor,
                };
                final color = colors[e.key] ?? AppColors.primary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key, style: Theme.of(context).textTheme.bodyMedium)),
                      Text(AppUtils.formatCurrency(e.value, symbol: settings.currencySymbol), style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Recent transactions
              const SectionHeader(title: 'All Transactions'),
              const SizedBox(height: 12),
              if (txns.isEmpty)
                const EmptyState(title: 'No Transactions', message: 'Complete sales to see them here', icon: Icons.receipt_long_rounded)
              else
                ...txns.take(20).map((txn) => _TxnRow(txn: txn, settings: settings)),
            ],
          ),
        );
      },
    );
  }
}

class _TxnRow extends StatelessWidget {
  final Transaction txn;
  final AppSettings settings;
  const _TxnRow({required this.txn, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn.receiptNumber, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
                Text(AppUtils.formatDateTime(txn.createdAt), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppUtils.formatCurrency(txn.total, symbol: settings.currencySymbol), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success)),
              StatusBadge(label: txn.paymentMethod),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== PRODUCTS TAB =====
class _ProductsTab extends StatelessWidget {
  final List<Product> products;
  final AppSettings settings;

  const _ProductsTab({required this.products, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Product Inventory Value'),
          const SizedBox(height: 16),

          // Inventory value card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1B2E), Color(0xFF252640)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Inventory Value', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  AppUtils.formatCurrency(
                    products.fold(0.0, (sum, p) => sum + (p.costPrice ?? p.price) * p.stockQuantity),
                    symbol: settings.currencySymbol,
                  ),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InvStat('Products', '${products.length}', Colors.white),
                    const SizedBox(width: 24),
                    _InvStat('Low Stock', '${products.where((p) => p.isLowStock).length}', AppColors.warning),
                    const SizedBox(width: 24),
                    _InvStat('Out of Stock', '${products.where((p) => p.isOutOfStock).length}', AppColors.error),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader(title: 'Products by Category'),
          const SizedBox(height: 16),
          _CategoryBar(products: products, settings: settings),
          const SizedBox(height: 24),

          const SectionHeader(title: 'All Products'),
          const SizedBox(height: 12),
          ...products.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                      Text('${p.stockQuantity} units in stock', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(AppUtils.formatCurrency(p.price, symbol: settings.currencySymbol), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                    StatusBadge(label: AppUtils.getStockStatus(p.stockQuantity)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _InvStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InvStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<Product> products;
  final AppSettings settings;

  const _CategoryBar({required this.products, required this.settings});

  @override
  Widget build(BuildContext context) {
    final categoryMap = <String, int>{};
    for (final p in products) {
      categoryMap[p.category] = (categoryMap[p.category] ?? 0) + 1;
    }

    final total = products.length;
    if (total == 0) return const SizedBox();

    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info, AppColors.warning];

    return Column(
      children: categoryMap.entries.toList().asMap().entries.map((entry) {
        final i = entry.key;
        final cat = entry.value.key;
        final count = entry.value.value;
        final color = colors[i % colors.length];
        final pct = count / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Text(cat, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                  Text('$count items', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
