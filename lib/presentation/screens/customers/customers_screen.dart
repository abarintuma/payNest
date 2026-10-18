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

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repo = CustomerRepository();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final provider = context.read<CustomerProvider>();
    provider.setLoading(true);
    final customers = await _repo.getAllCustomers();
    provider.setCustomers(customers);
    provider.setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
            ).then((_) => _loadCustomers()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: AppSearchBar(
              hint: 'Search customers...',
              controller: _searchCtrl,
              onChanged: (q) => context.read<CustomerProvider>().setSearch(q),
            ),
          ),
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (provider.customers.isEmpty) {
                  return const EmptyState(
                    title: 'No Customers Yet',
                    message: 'Add customers to track their purchase history',
                    icon: Icons.people_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: provider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = provider.customers[index];
                      return _CustomerCard(
                        customer: customer,
                        settings: settings,
                        index: index,
                        onTap: () => _showCustomerDetail(customer),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddCustomerScreen(customer: customer)),
                        ).then((_) => _loadCustomers()),
                        onDelete: () => _deleteCustomer(customer),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetail(Customer customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CustomerDetailSheet(customer: customer),
    );
  }

  void _deleteCustomer(Customer customer) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Customer'),
        content: Text('Delete ${customer.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await _repo.deleteCustomer(customer.id);
              if (context.mounted) {
                context.read<CustomerProvider>().removeCustomer(customer.id);
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

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final AppSettings settings;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.settings,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.info];
    final avatarColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: avatarColor.withOpacity(0.15),
          child: Text(
            customer.initials,
            style: GoogleFonts.poppins(
              color: avatarColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null)
              Text(customer.phone!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${customer.totalOrders} orders',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.payments_rounded, size: 12, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  AppUtils.formatCurrency(customer.totalSpent, symbol: settings.currencySymbol),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
          ],
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn().slideX(begin: 0.05);
  }
}

class _CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  const _CustomerDetailSheet({required this.customer});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>().settings;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                customer.initials,
                style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 24),
              ),
            ),
            const SizedBox(height: 12),
            Text(customer.name, style: Theme.of(context).textTheme.headlineMedium),
            if (customer.phone != null) Text(customer.phone!, style: Theme.of(context).textTheme.bodyMedium),
            if (customer.email != null) Text(customer.email!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatChip('Total Spent', AppUtils.formatCurrency(customer.totalSpent, symbol: settings.currencySymbol), AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(child: _StatChip('Orders', '${customer.totalOrders}', AppColors.secondary)),
                const SizedBox(width: 12),
                Expanded(child: _StatChip('Points', '${(customer.loyaltyPoints ?? 0).toInt()}', AppColors.accent)),
              ],
            ),
            if (customer.lastVisit != null) ...[
              const SizedBox(height: 16),
              Text('Last visit: ${AppUtils.formatDate(customer.lastVisit!)}', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w700, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.poppins(color: color, fontSize: 11)),
        ],
      ),
    );
  }
}

// ===== ADD/EDIT CUSTOMER SCREEN =====
class AddCustomerScreen extends StatefulWidget {
  final Customer? customer;
  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;
  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final c = widget.customer!;
      _nameCtrl.text = c.name;
      _emailCtrl.text = c.email ?? '';
      _phoneCtrl.text = c.phone ?? '';
      _addressCtrl.text = c.address ?? '';
      _notesCtrl.text = c.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = CustomerRepository();
      final customer = Customer(
        id: widget.customer?.id ?? '',
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        totalSpent: widget.customer?.totalSpent ?? 0,
        totalOrders: widget.customer?.totalOrders ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        loyaltyPoints: widget.customer?.loyaltyPoints,
      );

      if (_isEditing) {
        await repo.updateCustomer(customer);
        if (context.mounted) context.read<CustomerProvider>().updateCustomer(customer);
      } else {
        final id = await repo.addCustomer(customer);
        if (context.mounted) context.read<CustomerProvider>().addCustomer(customer.copyWith(id: id));
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'Add Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_rounded)),
              validator: (v) {
                if (v != null && v.isNotEmpty && !v.contains('@')) return 'Enter valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes', prefixIcon: Icon(Icons.note_rounded)),
            ),
            const SizedBox(height: 30),
            GradientButton(
              text: _isEditing ? 'Update Customer' : 'Add Customer',
              icon: _isEditing ? Icons.save_rounded : Icons.person_add_rounded,
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
