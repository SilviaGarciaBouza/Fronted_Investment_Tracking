import 'package:flutter/material.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/RegisterView.dart';

/// Pantalla de autenticación inicial.
class LoginView extends StatefulWidget {
  const LoginView({super.key});
  static const routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = Provider.of<InvViewModel>(context, listen: false);
      if (await vm.checkLocalSession()) {
        if (mounted)
          Navigator.pushReplacementNamed(context, Homeview.routeName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    const accentGreen = Colors.lightGreenAccent;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GESTOR DE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "INVERSIONES",
              style: TextStyle(
                color: accentGreen,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _userController,
              decoration: _inputStyle("Usuario", Icons.person_outline),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passController,
              obscureText: _obscureText,
              decoration: _inputStyle("Contraseña", Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: accentGreen,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
            ),
            const SizedBox(height: 50),
            vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    onPressed: () async {
                      if (await vm.login(
                        _userController.text,
                        _passController.text,
                      )) {
                        if (mounted)
                          Navigator.pushReplacementNamed(
                            context,
                            Homeview.routeName,
                          );
                      }
                    },
                    child: const Text(
                      "ACCEDER",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: vm.isOnline
                    ? () => Navigator.pushNamed(context, RegisterView.routeName)
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "¿No tienes cuenta? Regístrate aquí",
                      style: TextStyle(
                        color: vm.isOnline
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white24,
                        fontSize: 14,
                      ),
                    ),
                    if (!vm.isOnline)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "(Requiere conexión)",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.lightGreenAccent),
    labelStyle: const TextStyle(color: Colors.lightGreenAccent),
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.lightGreenAccent),
    ),
  );
}
