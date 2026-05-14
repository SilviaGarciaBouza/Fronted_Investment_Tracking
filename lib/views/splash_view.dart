import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/Inv_viewmodel.dart';
import 'package:investment_tracking/views/home_view.dart';
import 'package:investment_tracking/views/login_view.dart';
import 'package:provider/provider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context, listen: false);
    return FutureBuilder<bool>(
      future: vm.loadUserSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const LoginView();
        } else if (snapshot.data == true) {
          return const Homeview();
        } else {
          return const LoginView();
        }
      },
    );
  }
}
