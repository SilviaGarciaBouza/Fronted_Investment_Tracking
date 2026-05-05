import 'package:flutter/material.dart';
import 'package:investment_tracking/views/splash_view.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/theme/app_theme.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddTransaction.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:investment_tracking/views/RegisterView.dart';
import 'package:investment_tracking/views/LoginView.dart';
import 'package:investment_tracking/views/total_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvViewModel()..initSettings(),
      child: Consumer<InvViewModel>(
        builder: (context, vm, child) {
          return MaterialApp(
            title: "Investment App",
            debugShowCheckedModeBanner: false,
            theme: vm.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            home: const SplashView(),
            routes: {
              LoginView.routeName: (_) => const LoginView(),
              Homeview.routeName: (_) => const Homeview(),
              Additem.routeName: (_) => const Additem(),
              TotalView.routeName: (_) => const TotalView(),
              RegisterView.routeName: (_) => const RegisterView(),
            },
          );
        },
      ),
    );
  }
}
