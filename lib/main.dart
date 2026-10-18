import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:paynest/core/constants/app_constants.dart';
import 'package:paynest/core/theme/app_theme.dart';
import 'package:paynest/presentation/providers/providers.dart';
import 'package:paynest/presentation/screens/auth/splash_screen.dart';
import 'package:paynest/presentation/screens/home_screen.dart';
import 'package:paynest/presentation/screens/inventory/inventory_screen.dart';
import 'package:paynest/presentation/screens/customers/customers_screen.dart';
import 'package:paynest/presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for better POS UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PayNestApp());
}

class PayNestApp extends StatelessWidget {
  const PayNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            themeMode: settingsProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            initialRoute: AppConstants.routeSplash,
            routes: {
              AppConstants.routeSplash: (_) => const SplashScreen(),
              AppConstants.routeHome: (_) => const HomeScreen(),
              AppConstants.routeSettings: (_) => const SettingsScreen(),
              AppConstants.routeAddProduct: (_) => const AddProductScreen(),
              AppConstants.routeAddCustomer: (_) => const AddCustomerScreen(),
            },
          );
        },
      ),
    );
  }
}
