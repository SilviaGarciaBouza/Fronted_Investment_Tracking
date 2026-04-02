import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';

class RegisterView extends StatefulWidget {
  static const routeName = '/register';
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final Color _accentGreen = Colors.lightGreenAccent;

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: _accentGreen),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      Flexible(
                        flex: 2,
                        child: Center(
                          child: Text(
                            "NUEVA CUENTA",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _accentGreen,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),

                      Column(
                        children: [
                          _buildTextField(
                            _userController,
                            "Usuario",
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 25),
                          _buildTextField(
                            _emailController,
                            "Email",
                            Icons.email_outlined,
                          ),
                          const SizedBox(height: 25),
                          _buildTextField(
                            _passController,
                            "Contraseña",
                            Icons.lock_outline,
                            isPass: true,
                          ),
                        ],
                      ),

                      const Expanded(flex: 2, child: SizedBox()),

                      vm.isLoading
                          ? CircularProgressIndicator(color: _accentGreen)
                          : Flexible(
                              flex: 1,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentGreen,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () => _handleRegister(vm),
                                child: const Text(
                                  "CREAR CUENTA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),

                      const Spacer(flex: 1),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.lightGreenAccent),
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _accentGreen),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleRegister(InvViewModel vm) async {
    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _emailController.text.isEmpty) {
      _showMsg("Todos los campos son obligatorios");
      return;
    }

    final success = await vm.register(
      _userController.text.trim(),
      _passController.text.trim(),
      _emailController.text.trim(),
    );

    if (mounted && success) {
      _showMsg("¡Usuario registrado!");
      Navigator.pop(context);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
