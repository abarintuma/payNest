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
import 'package:paynest/presentation/screens/pos/checkout_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> with SingleTickerProviderStateMixin {
  final _productRepo = ProductRepository();
  final _searchController = TextEditingController();
  late TabController _tabController;

  final List<String> _categories = ['All', 'Food', 'Drinks', 'Electronics', 'Clothing', 'Other'];
  final List<String> _categoryIds = ['all', 'food', 'beverages', 'electronics', 'clothing', 'other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onCategoryChange);
    _loadProducts();
  }

  void _onCategoryChange() {
    if (!_tabController.indexIsChanging) return;
    final provider = context.read<ProductProvider>();
    provider.setCategory(_categoryIds[_tabController.index]);
  }

  Future<void> _loadProducts() async {
    final provider = context.read<ProductProvider>();
    provider.setLoading(true);
    final products = await _productRepo.getAllProducts();
    provider.setProducts(products);
    provider.setLoading(false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Top bar
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Point of Sale',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                AppUtils.formatDate(DateTime.now()),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        // Cart button
                        _CartButton(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: AppSearchBar(
                      hint: 'Search products or scan barcode...',
                      controller: _searchController,
                      onChanged: (q) => context.read<ProductProvider>().setSearch(q),
                    ),
                  ),
                  // Category tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: _categories.map((c) => Tab(text: c)).toList(),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ],
              ),
            ),
          ),

          // Products grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (provider.products.isEmpty) {
                  return const EmptyState(
                    title: 'No Products Found',
                    message: 'Add products to start selling',
                    icon: Icons.inventory_2_rounded,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    return _ProductCard(
                      product: provider.products[index],
                      onTap: () => _addToCart(provider.products[index]),
                    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is out of stock'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${product.name} added to cart'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                if (cart.itemCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${cart.itemCount}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>().settings;
    final isOutOfStock = product.isOutOfStock;

    return InkWell(
      onTap: isOutOfStock ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isOutOfStock ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image / icon
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.secondary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Icon(
                          _getCategoryIcon(product.category),
                          size: 48,
                          color: AppColors.primary.withOpacity(0.6),
                        ),
                        if (product.isLowStock)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.warning_rounded, size: 10, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Product info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOutOfStock
                            ? 'Out of Stock'
                            : '${product.stockQuantity} in stock',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isOutOfStock
                              ? AppColors.error
                              : product.isLowStock
                                  ? AppColors.warning
                                  : AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              AppUtils.formatCurrency(product.price, symbol: settings.currencySymbol),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              gradient: isOutOfStock
                                  ? null
                                  : const LinearGradient(
                                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                                    ),
                              color: isOutOfStock ? Colors.grey : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food': return Icons.restaurant_rounded;
      case 'beverages': return Icons.local_cafe_rounded;
      case 'electronics': return Icons.devices_rounded;
      case 'clothing': return Icons.checkroom_rounded;
      case 'beauty': return Icons.spa_rounded;
      case 'health': return Icons.favorite_rounded;
      default: return Icons.category_rounded;
    }
  }
}

// ===== CART SCREEN =====
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => cart.isEmpty
                ? const SizedBox()
                : TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Clear Cart'),
                          content: const Text('Remove all items from cart?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                cart.clearCart();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    label: Text('Clear', style: GoogleFonts.poppins(color: AppColors.error, fontSize: 13)),
                  ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const EmptyState(
              title: 'Cart is Empty',
              message: 'Add products from the POS screen to start a sale',
              icon: Icons.shopping_cart_outlined,
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Customer selector
                    _CustomerSelector(),
                    const SizedBox(height: 16),

                    // Cart items
                    ...cart.items.map((item) => _CartItemTile(
                      item: item,
                      settings: settings,
                    )),

                    const SizedBox(height: 16),
                    // Notes
                    _NotesField(),
                  ],
                ),
              ),

              // Order summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _SummaryRow('Subtotal', AppUtils.formatCurrency(cart.subtotal, symbol: settings.currencySymbol)),
                      _SummaryRow('Tax (VAT ${settings.taxRate.toStringAsFixed(0)}%)', AppUtils.formatCurrency(cart.taxAmount, symbol: settings.currencySymbol)),
                      if (cart.discountAmount > 0) ...[
                        const SizedBox(height: 6),
                        _SummaryRow(
                          'Discount',
                          '- ${AppUtils.formatCurrency(cart.discountAmount, symbol: settings.currencySymbol)}',
                          color: AppColors.success,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            AppUtils.formatCurrency(cart.total, symbol: settings.currencySymbol),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GradientButton(
                        text: 'Proceed to Checkout',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final AppSettings settings;

  const _CartItemTile({required this.item, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.read<CartProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppUtils.formatCurrency(item.product.price, symbol: settings.currencySymbol),
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: () => cart.updateQuantity(item.product.id, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${item.quantity}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _QtyButton({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : AppColors.primary,
          size: 18,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        return InkWell(
          onTap: () => _showCustomerPicker(context, cart),
          borderRadius: BorderRadius.circular(12),
          child: Container(
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
                Icon(
                  cart.selectedCustomer != null
                      ? Icons.person_rounded
                      : Icons.person_add_alt_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cart.selectedCustomer?.name ?? 'Add Customer (optional)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cart.selectedCustomer != null
                          ? null
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomerPicker(BuildContext context, CartProvider cart) {
    final repo = CustomerRepository();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder<List<Customer>>(
              future: repo.getAllCustomers(),
              builder: (ctx, snap) {
                final customers = snap.data ?? [];
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Select Customer', style: Theme.of(ctx).textTheme.titleLarge),
                    ),
                    if (cart.selectedCustomer != null)
                      ListTile(
                        leading: const Icon(Icons.person_off_rounded, color: AppColors.error),
                        title: const Text('Remove customer'),
                        onTap: () {
                          cart.setCustomer(null);
                          Navigator.pop(ctx);
                        },
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: customers.length,
                        itemBuilder: (ctx, i) {
                          final c = customers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.15),
                              child: Text(
                                c.initials,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(c.name),
                            subtitle: Text(c.phone ?? c.email ?? ''),
                            onTap: () {
                              cart.setCustomer(c);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _NotesField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return TextField(
      maxLines: 2,
      decoration: const InputDecoration(
        hintText: 'Add order notes (optional)...',
        prefixIcon: Icon(Icons.note_alt_rounded, color: AppColors.primary),
      ),
      onChanged: cart.setNotes,
    );
  }
}
