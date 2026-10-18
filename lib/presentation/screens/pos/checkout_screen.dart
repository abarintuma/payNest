import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'package:paynest/presentation/screens/pos/receipt_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = AppConstants.paymentCash;
  final _amountController = TextEditingController();
  bool _isProcessing = false;

  final List<_PaymentOption> _paymentOptions = [
    _PaymentOption(AppConstants.paymentCash, Icons.payments_rounded, AppColors.cashColor, svgAsset: 'assets/icons/cash.svg'),
    _PaymentOption(AppConstants.paymentMtnMomo, Icons.phone_android_rounded, AppColors.mtnMomoColor, svgAsset: 'assets/icons/mtn_momo.svg'),
    _PaymentOption(AppConstants.paymentAirtelMoney, Icons.contactless_rounded, AppColors.airtelMoneyColor, svgAsset: 'assets/icons/airtel_money.svg'),
    _PaymentOption(AppConstants.paymentCard, Icons.credit_card_rounded, AppColors.cardColor, svgAsset: 'assets/icons/credit_card.svg'),
    _PaymentOption(AppConstants.paymentBank, Icons.account_balance_rounded, AppColors.bankColor),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cart = context.read<CartProvider>();
      _amountController.text = cart.total % 1 == 0
          ? cart.total.toInt().toString()
          : cart.total.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amountPaid => double.tryParse(_amountController.text) ?? 0;
  double get _change {
    final cart = context.read<CartProvider>();
    return (_amountPaid - cart.total).clamp(0, double.infinity);
  }

  Future<void> _processPayment() async {
    final cart = context.read<CartProvider>();
    final settings = context.read<SettingsProvider>().settings;

    if (_amountPaid < cart.total && _selectedPayment == AppConstants.paymentCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient amount paid'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final txnRepo = TransactionRepository();
      final productRepo = ProductRepository();
      final uuid = const Uuid();

      // Build transaction
      final items = cart.items.map((i) => TransactionItem(
        productId: i.product.id,
        productName: i.product.name,
        price: i.product.price,
        quantity: i.quantity,
        discountPercent: i.discountPercent,
      )).toList();

      final txn = Transaction(
        id: uuid.v4(),
        receiptNumber: AppUtils.generateReceiptNumber(),
        items: items,
        subtotal: cart.subtotal,
        taxAmount: cart.taxAmount,
        discountAmount: cart.discountAmount,
        total: cart.total,
        amountPaid: _selectedPayment == AppConstants.paymentCash ? _amountPaid : cart.total,
        change: _selectedPayment == AppConstants.paymentCash ? _change : 0,
        paymentMethod: _selectedPayment,
        status: AppConstants.statusCompleted,
        type: AppConstants.transactionSale,
        customerId: cart.selectedCustomer?.id,
        customerName: cart.selectedCustomer?.name,
        notes: cart.notes,
        createdAt: DateTime.now(),
      );

      // Save transaction
      await txnRepo.addTransaction(txn);

      // Update stock
      for (final item in cart.items) {
        if (item.product.trackInventory) {
          await productRepo.updateStock(item.product.id, -item.quantity);
        }
      }

      // Update customer stats
      if (cart.selectedCustomer != null) {
        final customerRepo = CustomerRepository();
        await customerRepo.updateCustomerStats(cart.selectedCustomer!.id, cart.total);
      }

      // Add to provider
      if (mounted) {
        context.read<TransactionProvider>().addTransaction(txn);
      }

      // Navigate to receipt
      if (!mounted) return;
      cart.clearCart();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptScreen(transaction: txn, settings: settings),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>().settings;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Order summary card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Order Total',
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppUtils.formatCurrency(cart.total, symbol: settings.currencySymbol),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _OrderStat('Items', '${cart.itemCount}'),
                              _OrderStat('Subtotal', AppUtils.formatCurrency(cart.subtotal, symbol: settings.currencySymbol)),
                              _OrderStat('Tax', AppUtils.formatCurrency(cart.taxAmount, symbol: settings.currencySymbol)),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 24),

                    // Payment Method Selection
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: _paymentOptions.map((opt) {
                        final isSelected = _selectedPayment == opt.method;
                        return InkWell(
                          onTap: () => setState(() => _selectedPayment = opt.method),
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? opt.color.withOpacity(0.15)
                                  : isDark ? AppColors.cardDark : AppColors.cardLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? opt.color : isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (opt.svgAsset != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: SvgPicture.asset(
                                      opt.svgAsset!,
                                      width: 22,
                                      height: 22,
                                    ),
                                  )
                                else
                                  Icon(opt.icon, color: opt.color, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  opt.method,
                                  style: GoogleFonts.poppins(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                    color: isSelected ? opt.color : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate(delay: 100.ms).fadeIn(),
                    const SizedBox(height: 24),

                    // Amount paid (cash only)
                    if (_selectedPayment == AppConstants.paymentCash) ...[
                      Text(
                        'Amount Received',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          prefixText: '${settings.currencySymbol} ',
                          prefixStyle: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          hintText: '0.00',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      // Quick amount buttons
                      Wrap(
                        spacing: 8,
                        children: [1000, 2000, 5000, 10000, 20000, 50000].map((amount) {
                          return ActionChip(
                            label: Text(
                              '${settings.currencySymbol} ${amount >= 1000 ? "${amount ~/ 1000}k" : amount}',
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              _amountController.text = amount.toString();
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),

                      if (_amountPaid >= cart.total) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Change to return',
                                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.success),
                                  ),
                                  Text(
                                    AppUtils.formatCurrency(_change, symbol: settings.currencySymbol),
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: GradientButton(
                    text: 'Complete Payment',
                    icon: Icons.check_circle_rounded,
                    isLoading: _isProcessing,
                    onPressed: _processPayment,
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

class _PaymentOption {
  final String method;
  final IconData icon;
  final Color color;
  final String? svgAsset;
  const _PaymentOption(this.method, this.icon, this.color, {this.svgAsset});
}

class _OrderStat extends StatelessWidget {
  final String label;
  final String value;
  const _OrderStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}
