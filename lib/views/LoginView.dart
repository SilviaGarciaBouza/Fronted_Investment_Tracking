import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';
import 'HomeView.dart';
import 'RegisterView.dart';

/// Pantalla de autenticación inicial con diseño responsive y centrado.
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
  final Color _accentGreen = Colors.lightGreenAccent;

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

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      SizedBox(
                        width: double.infinity,
                        child: Column(
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
                            Text(
                              "INVERSIONES",
                              style: TextStyle(
                                color: _accentGreen,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),

                      TextField(
                        controller: _userController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputStyle(
                          "Usuario",
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passController,
                        obscureText: _obscureText,
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _inputStyle(
                              "Contraseña",
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: _accentGreen,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                            ),
                      ),

                      const Spacer(flex: 1),

                      vm.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.lightGreenAccent,
                              ),
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentGreen,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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

                      TextButton(
                        onPressed: vm.isOnline
                            ? () => Navigator.pushNamed(
                                context,
                                RegisterView.routeName,
                              )
                            : null,
                        child: Column(
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

                      const Spacer(flex: 3),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _accentGreen),
    labelStyle: TextStyle(color: _accentGreen),
    enabledBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: _accentGreen),
    ),
  );
}
