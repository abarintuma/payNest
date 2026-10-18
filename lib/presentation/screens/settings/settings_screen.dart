import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/presentation/providers/providers.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _businessNameCtrl;
  late TextEditingController _businessAddressCtrl;
  late TextEditingController _businessPhoneCtrl;
  late TextEditingController _businessEmailCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _footerCtrl;
  late TextEditingController _currencyCtrl;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().settings;
    _businessNameCtrl = TextEditingController(text: settings.businessName);
    _businessAddressCtrl = TextEditingController(text: settings.businessAddress ?? '');
    _businessPhoneCtrl = TextEditingController(text: settings.businessPhone ?? '');
    _businessEmailCtrl = TextEditingController(text: settings.businessEmail ?? '');
    _taxRateCtrl = TextEditingController(text: settings.taxRate.toString());
    _footerCtrl = TextEditingController(text: settings.receiptFooter ?? '');
    _currencyCtrl = TextEditingController(text: settings.currencySymbol);
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _businessEmailCtrl.dispose();
    _taxRateCtrl.dispose();
    _footerCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final provider = context.read<SettingsProvider>();
    final current = provider.settings;
    await provider.updateSettings(current.copyWith(
      businessName: _businessNameCtrl.text.trim(),
      businessAddress: _businessAddressCtrl.text.trim().isEmpty ? null : _businessAddressCtrl.text.trim(),
      businessPhone: _businessPhoneCtrl.text.trim().isEmpty ? null : _businessPhoneCtrl.text.trim(),
      businessEmail: _businessEmailCtrl.text.trim().isEmpty ? null : _businessEmailCtrl.text.trim(),
      taxRate: double.tryParse(_taxRateCtrl.text) ?? 18.0,
      receiptFooter: _footerCtrl.text.trim().isEmpty ? null : _footerCtrl.text.trim(),
      currencySymbol: _currencyCtrl.text.trim().isEmpty ? 'UGX' : _currencyCtrl.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings saved'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          final settings = settingsProvider.settings;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Business Profile Section
              _SettingsSection(
                title: 'Business Profile',
                icon: Icons.store_rounded,
                color: AppColors.primary,
                children: [
                  TextFormField(
                    controller: _businessNameCtrl,
                    decoration: const InputDecoration(labelText: 'Business Name', prefixIcon: Icon(Icons.business_rounded)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _businessAddressCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_rounded)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _businessPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _businessEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_rounded)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tax & Currency
              _SettingsSection(
                title: 'Tax & Currency',
                icon: Icons.percent_rounded,
                color: AppColors.success,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxRateCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Tax Rate (%)',
                            prefixIcon: Icon(Icons.percent_rounded),
                            suffixText: '%',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _currencyCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Currency Symbol',
                            prefixIcon: Icon(Icons.attach_money_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['UGX', 'USh', 'USD', 'EUR', 'GBP'].map((curr) {
                      final isSelected = _currencyCtrl.text == curr;
                      return ChoiceChip(
                        label: Text(curr),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currencyCtrl.text = curr;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Appearance
              _SettingsSection(
                title: 'Appearance',
                icon: Icons.palette_rounded,
                color: AppColors.accent,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.darkMode,
                    onChanged: (_) => settingsProvider.toggleDarkMode(),
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Switch between light and dark theme'),
                    secondary: Icon(
                      settings.darkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: settings.darkMode ? AppColors.primary : AppColors.warning,
                    ),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Security
              _SettingsSection(
                title: 'Security',
                icon: Icons.security_rounded,
                color: AppColors.info,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.pinEnabled,
                    onChanged: (v) => settingsProvider.updateSettings(settings.copyWith(pinEnabled: v)),
                    title: const Text('PIN Lock'),
                    subtitle: const Text('Require PIN to open the app'),
                    secondary: const Icon(Icons.pin_rounded, color: AppColors.info),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.biometricEnabled,
                    onChanged: (v) => settingsProvider.updateSettings(settings.copyWith(biometricEnabled: v)),
                    title: const Text('Biometric Auth'),
                    subtitle: const Text('Use fingerprint or face ID'),
                    secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Receipt Settings
              _SettingsSection(
                title: 'Receipt',
                icon: Icons.receipt_rounded,
                color: AppColors.secondary,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.printReceiptAuto,
                    onChanged: (v) => settingsProvider.updateSettings(settings.copyWith(printReceiptAuto: v)),
                    title: const Text('Auto-Print Receipts'),
                    subtitle: const Text('Automatically print after each sale'),
                    secondary: const Icon(Icons.print_rounded, color: AppColors.secondary),
                    activeColor: AppColors.primary,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _footerCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Receipt Footer Message',
                      hintText: 'e.g. Thank you for your purchase!',
                      prefixIcon: Icon(Icons.message_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About
              _SettingsSection(
                title: 'About',
                icon: Icons.info_rounded,
                color: AppColors.textSecondaryLight,
                children: [
                  _InfoTile('App Version', '1.0.0', Icons.verified_rounded),
                  const Divider(),
                  _InfoTile('Database', 'SQLite (Local)', Icons.storage_rounded),
                  const Divider(),
                  _InfoTile('Platform', 'Android & iOS', Icons.phone_android_rounded),
                ],
              ),
              const SizedBox(height: 20),

              // Danger Zone
              _SettingsSection(
                title: 'Data Management',
                icon: Icons.warning_rounded,
                color: AppColors.error,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_rounded, color: AppColors.info),
                    title: const Text('Export Data'),
                    subtitle: const Text('Export all data as CSV'),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                    title: const Text('Clear All Data', style: TextStyle(color: AppColors.error)),
                    subtitle: const Text('This cannot be undone'),
                    onTap: () => _confirmClear(context),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('⚠️ Clear All Data'),
        content: const Text('This will permanently delete all transactions, products, and customer data. Are you absolutely sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand, Clear'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
