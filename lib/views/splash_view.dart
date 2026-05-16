import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/Inv_viewmodel.dart';
import 'package:investment_tracking/views/home_view.dart';
import 'package:investment_tracking/views/login_view.dart';
import 'package:provider/provider.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final vm = Provider.of<InvViewModel>(context, listen: false);
    final hasSession = await vm.loadUserSession();
    if (!mounted) return;
    if (hasSession) {
      Navigator.pushReplacementNamed(context, Homeview.routeName);
    } else {
      final wasExpired = vm.sessionExpired;
      if (wasExpired) vm.clearSessionExpired();
      Navigator.pushReplacementNamed(
        context,
        LoginView.routeName,
        arguments: wasExpired ? {'sessionExpired': true} : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      ),
    );
  }
}
