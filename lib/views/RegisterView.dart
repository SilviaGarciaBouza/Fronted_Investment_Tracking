import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';
import '../utils/app_strings.dart';

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

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        iconTheme: IconThemeData(color: primary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              AppStrings.get('reg_title', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 50),
            _buildField(
              _userController,
              AppStrings.get('user', lang),
              Icons.person_outline,
              primary,
              vm.isDarkMode,
            ),
            const SizedBox(height: 25),
            _buildField(
              _emailController,
              AppStrings.get('email', lang),
              Icons.email_outlined,
              primary,
              vm.isDarkMode,
            ),
            const SizedBox(height: 25),
            _buildField(
              _passController,
              AppStrings.get('pass', lang),
              Icons.lock_outline,
              primary,
              vm.isDarkMode,
              isPass: true,
            ),
            const SizedBox(height: 60),
            vm.isLoading
                ? CircularProgressIndicator(color: primary)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: vm.isDarkMode
                          ? Colors.black
                          : Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () => _handleRegister(vm, lang),
                    child: Text(
                      AppStrings.get('btn_create', lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color color,
    bool isDark, {
    bool isPass = false,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleRegister(InvViewModel vm, String lang) async {
    if (_userController.text.isEmpty ||
        _passController.text.isEmpty ||
        _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('fields_req', lang))),
      );
      return;
    }
    final success = await vm.register(
      _userController.text.trim(),
      _passController.text.trim(),
      _emailController.text.trim(),
    );
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('reg_success', lang))),
      );
      Navigator.pop(context);
    }
  }
}
