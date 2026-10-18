import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/core/utils/app_utils.dart';
import 'package:paynest/core/widgets/common_widgets.dart';
import 'package:paynest/data/models/models.dart';

class ReceiptScreen extends StatelessWidget {
  final Transaction transaction;
  final AppSettings settings;

  const ReceiptScreen({super.key, required this.transaction, required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Receipt'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Success animation
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Lottie.asset(
                      'assets/animations/payment_success.json',
                      width: 90,
                      height: 90,
                      repeat: false,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.success, Color(0xFF00A87A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 44),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.elasticOut)
                      .fadeIn(),
                  const SizedBox(height: 16),
                  Text(
                    'Payment Successful!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 4),
                  Text(
                    AppUtils.formatDateTime(transaction.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),

                  // Receipt card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Business header
                              Text(
                                settings.businessName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.businessAddress ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),

                              // Receipt info
                              _ReceiptRow('Receipt No', transaction.receiptNumber),
                              const SizedBox(height: 6),
                              _ReceiptRow('Date', AppUtils.formatDateTime(transaction.createdAt)),
                              _ReceiptRow('Payment', transaction.paymentMethod),
                              if (transaction.customerName != null)
                                _ReceiptRow('Customer', transaction.customerName!),
                            ],
                          ),
                        ),

                        // Dashed divider
                        _DashedDivider(),

                        // Items
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text('Item', style: Theme.of(context).textTheme.labelLarge)),
                                  Text('Qty', style: Theme.of(context).textTheme.labelLarge),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 80,
                                    child: Text('Amount', style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.right),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...transaction.items.map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.productName,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'x${item.quantity}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          AppUtils.formatCurrency(item.total, symbol: settings.currencySymbol),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),

                        _DashedDivider(),

                        // Totals
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _ReceiptRow('Subtotal', AppUtils.formatCurrency(transaction.subtotal, symbol: settings.currencySymbol)),
                              _ReceiptRow('Tax (VAT ${settings.taxRate.toStringAsFixed(0)}%)', AppUtils.formatCurrency(transaction.taxAmount, symbol: settings.currencySymbol)),
                              if (transaction.discountAmount > 0) ...[
                                const SizedBox(height: 6),
                                _ReceiptRow('Discount', '- ${AppUtils.formatCurrency(transaction.discountAmount, symbol: settings.currencySymbol)}', valueColor: AppColors.success),
                              ],
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('TOTAL', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  Text(
                                    AppUtils.formatCurrency(transaction.total, symbol: settings.currencySymbol),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              if (transaction.paymentMethod == AppConstants.paymentCash) ...[
                                const SizedBox(height: 10),
                                _ReceiptRow('Paid', AppUtils.formatCurrency(transaction.amountPaid, symbol: settings.currencySymbol)),
                                const SizedBox(height: 4),
                                _ReceiptRow('Change', AppUtils.formatCurrency(transaction.change, symbol: settings.currencySymbol), valueColor: AppColors.success),
                              ],
                            ],
                          ),
                        ),

                        if (settings.receiptFooter != null) ...[
                          _DashedDivider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              settings.receiptFooter!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ] else ...[
                          _DashedDivider(),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Thank you for shopping with us! 🎉',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondaryLight,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                ],
              ),
            ),
          ),

          // Action buttons
          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GradientButton(
                      text: 'New Sale',
                      icon: Icons.add_shopping_cart_rounded,
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 8.0;
          const dashSpace = 5.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return Container(
                width: dashWidth,
                height: 1.5,
                color: Colors.grey.withOpacity(0.3),
              );
            }),
          );
        },
      ),
    );
  }
}
