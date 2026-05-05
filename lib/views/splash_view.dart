import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:investment_tracking/views/LoginView.dart';
import 'package:provider/provider.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context, listen: false);
    return FutureBuilder<bool>(
      future: vm.hasUserSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const Homeview();
        } else {
          return const LoginView();
        }
      },
    );
  }
}
