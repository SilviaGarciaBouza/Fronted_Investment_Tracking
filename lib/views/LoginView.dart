import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:provider/provider.dart';

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
      final vm = Provider.of<Invviewmodel>(context, listen: false);
      if (await vm.checkLocalSession()) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, Homeview.routeName);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<Invviewmodel>(context);
    const accentGreen = Colors.lightGreenAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "BIENVENIDO A TU",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const Text(
              "GESTOR DE INVERSIONES",
              style: TextStyle(
                color: accentGreen,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),

            // Campo Usuario
            TextField(
              controller: _userController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle(
                "Usuario de MariaDB",
                Icons.person_outline,
              ),
            ),
            const SizedBox(height: 20),

            // Campo Contraseña
            TextField(
              controller: _passController,
              obscureText: _obscureText,
              style: const TextStyle(color: Colors.white),
              decoration: _inputStyle("Contraseña", Icons.lock_outline)
                  .copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: accentGreen.withOpacity(0.6),
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
            ),
            const SizedBox(height: 50),

            // Botón Entrar
            vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: accentGreen),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      // Pasoo usuario Y contraseña al ViewModel
                      if (await vm.login(
                        _userController.text,
                        _passController.text,
                      )) {
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            Homeview.routeName,
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error: Credenciales no válidas"),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      "ACCEDER AL PANEL",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.lightGreenAccent, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.lightGreenAccent, size: 20),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.lightGreenAccent),
      ),
    );
  }
}
