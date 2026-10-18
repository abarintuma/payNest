import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/core/utils/app_utils.dart';
import 'package:paynest/core/widgets/common_widgets.dart';
import 'package:paynest/data/models/models.dart';
import 'package:paynest/data/repositories/repositories.dart';
import 'package:paynest/presentation/providers/providers.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  final _repo = ProductRepository();
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final provider = context.read<ProductProvider>();
    provider.setLoading(true);
    final products = await _repo.getAllProducts();
    provider.setProducts(products);
    provider.setLoading(false);
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
            floating: false,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            elevation: 0,
            title: const Text('Inventory'),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                onPressed: () {},
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: AppSearchBar(
                      hint: 'Search products...',
                      controller: _searchController,
                      onChanged: (q) => context.read<ProductProvider>().setSearch(q),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondaryLight,
                    indicatorColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'All Products'),
                      Tab(text: 'Low Stock'),
                      Tab(text: 'Out of Stock'),
                    ],
                  ),
                  Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ProductList(filter: 'all'),
            _ProductList(filter: 'low'),
            _ProductList(filter: 'out'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Product', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    ).then((_) => _loadProducts());
  }
}

class _ProductList extends StatelessWidget {
  final String filter;

  const _ProductList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        List<Product> products;
        switch (filter) {
          case 'low':
            products = provider.allProducts.where((p) => p.isLowStock).toList();
            break;
          case 'out':
            products = provider.allProducts.where((p) => p.isOutOfStock).toList();
            break;
          default:
            products = provider.products;
        }

        if (products.isEmpty) {
          return EmptyState(
            title: filter == 'low' ? 'No Low Stock Items' : filter == 'out' ? 'All Items In Stock' : 'No Products Found',
            message: filter == 'all' ? 'Add products to your inventory' : 'Great! Your stock levels look good',
            icon: Icons.inventory_2_rounded,
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final repo = ProductRepository();
            final p = await repo.getAllProducts();
            context.read<ProductProvider>().setProducts(p);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductListTile(
                product: products[index],
                index: index,
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final int index;

  const _ProductListTile({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>().settings;

    Color stockColor;
    if (product.isOutOfStock) {
      stockColor = AppColors.error;
    } else if (product.isLowStock) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getCategoryIcon(product.category), color: AppColors.primary, size: 24),
        ),
        title: Text(
          product.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.sku ?? product.category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: stockColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${product.stockQuantity} units',
                  style: GoogleFonts.poppins(fontSize: 12, color: stockColor, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppUtils.formatCurrency(product.price, symbol: settings.currencySymbol),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => _handleAction(context, value, product),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'stock', child: Row(children: [Icon(Icons.add_circle_outline_rounded, size: 16), SizedBox(width: 8), Text('Update Stock')])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food': return Icons.restaurant_rounded;
      case 'beverages': return Icons.local_cafe_rounded;
      case 'electronics': return Icons.devices_rounded;
      case 'clothing': return Icons.checkroom_rounded;
      default: return Icons.category_rounded;
    }
  }

  void _handleAction(BuildContext context, String action, Product product) {
    if (action == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AddProductScreen(product: product)));
    } else if (action == 'stock') {
      _showStockUpdateDialog(context, product);
    } else if (action == 'delete') {
      _confirmDelete(context, product);
    }
  }

  void _showStockUpdateDialog(BuildContext context, Product product) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Stock: ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(
            hintText: 'e.g. +50 or -10',
            helperText: 'Use + to add, - to subtract',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(controller.text) ?? 0;
              if (qty != 0) {
                await ProductRepository().updateStock(product.id, qty);
                final products = await ProductRepository().getAllProducts();
                if (context.mounted) {
                  context.read<ProductProvider>().setProducts(products);
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ProductRepository().deleteProduct(product.id);
              if (context.mounted) {
                context.read<ProductProvider>().removeProduct(product.id);
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ===== ADD/EDIT PRODUCT SCREEN =====
class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  String _selectedCategory = 'food';
  bool _trackInventory = true;
  bool _isLoading = false;
  bool get _isEditing => widget.product != null;

  final _categories = [
    {'id': 'food', 'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'id': 'beverages', 'label': 'Drinks', 'icon': Icons.local_cafe_rounded},
    {'id': 'electronics', 'label': 'Electronics', 'icon': Icons.devices_rounded},
    {'id': 'clothing', 'label': 'Clothing', 'icon': Icons.checkroom_rounded},
    {'id': 'beauty', 'label': 'Beauty', 'icon': Icons.spa_rounded},
    {'id': 'other', 'label': 'Other', 'icon': Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _descCtrl.text = p.description ?? '';
      _priceCtrl.text = p.price.toString();
      _costCtrl.text = p.costPrice?.toString() ?? '';
      _stockCtrl.text = p.stockQuantity.toString();
      _skuCtrl.text = p.sku ?? '';
      _barcodeCtrl.text = p.barcode ?? '';
      _selectedCategory = p.category;
      _trackInventory = p.trackInventory;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _costCtrl.dispose(); _stockCtrl.dispose(); _skuCtrl.dispose();
    _barcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ProductRepository();
      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: _selectedCategory,
        price: double.parse(_priceCtrl.text),
        costPrice: _costCtrl.text.isEmpty ? null : double.tryParse(_costCtrl.text),
        stockQuantity: int.tryParse(_stockCtrl.text) ?? 0,
        sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        barcode: _barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim(),
        trackInventory: _trackInventory,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await repo.updateProduct(product);
        if (context.mounted) context.read<ProductProvider>().updateProduct(product);
      } else {
        final id = await repo.addProduct(product);
        if (context.mounted) context.read<ProductProvider>().addProduct(product.copyWith(id: id));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Basic Information'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name *', prefixIcon: Icon(Icons.label_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_rounded)),
            ),
            const SizedBox(height: 20),

            _SectionLabel('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return FilterChip(
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedCategory = cat['id'] as String),
                  avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? AppColors.primary : null),
                  label: Text(cat['label'] as String),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _SectionLabel('Pricing'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Selling Price *', prefixIcon: Icon(Icons.attach_money_rounded)),
                    validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cost Price', prefixIcon: Icon(Icons.money_rounded)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel('Inventory'),
            SwitchListTile(
              value: _trackInventory,
              onChanged: (v) => setState(() => _trackInventory = v),
              title: const Text('Track Inventory'),
              subtitle: const Text('Monitor stock levels for this product'),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_trackInventory) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Quantity *', prefixIcon: Icon(Icons.inventory_rounded)),
                validator: (v) => _trackInventory && (v == null || int.tryParse(v) == null) ? 'Enter valid quantity' : null,
              ),
            ],
            const SizedBox(height: 20),

            _SectionLabel('Identification'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(labelText: 'SKU', prefixIcon: Icon(Icons.tag_rounded)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _barcodeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Barcode',
                      prefixIcon: const Icon(Icons.qr_code_rounded),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            GradientButton(
              text: _isEditing ? 'Update Product' : 'Add Product',
              icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
              isLoading: _isLoading,
              onPressed: _save,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
