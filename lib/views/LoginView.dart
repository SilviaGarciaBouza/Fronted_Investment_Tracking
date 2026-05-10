import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/InvViewModel.dart';
import '../utils/app_strings.dart';
import 'HomeView.dart';
import 'RegisterView.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      if (args?['sessionExpired'] == true && mounted) {
        final lang = Provider.of<InvViewModel>(
          context,
          listen: false,
        ).currentLocale;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
              child: Text(
                AppStrings.get('session_expired', lang),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(InvViewModel vm, BuildContext context) async {
    if (vm.isLoading) return;

    if (await vm.login(_userController.text, _passController.text)) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Homeview.routeName);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              AppStrings.get('login_error', vm.currentLocale),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<InvViewModel>(context);
    final lang = vm.currentLocale;
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              vm.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: primary,
            ),
            onPressed: () => vm.toggleTheme(),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: primary),
            onSelected: (code) => vm.setLanguage(code),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'es', child: Text("Español")),
              const PopupMenuItem(value: 'gl', child: Text("Galego")),
              const PopupMenuItem(value: 'en', child: Text("English")),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 56,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      SizedBox(
                        width: double.infinity,
                        child: Text(
                          AppStrings.get('login_title', lang),
                          style: TextStyle(
                            color: primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),

                      // --- CAMPO USUARIO ---
                      TextField(
                        controller: _userController,
                        textInputAction: TextInputAction
                            .next, // Muestra "Siguiente" en el teclado
                        style: TextStyle(
                          color: vm.isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration: _inputStyle(
                          AppStrings.get('user', lang),
                          Icons.person_outline,
                          primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _passController,
                        obscureText: _obscureText,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(vm, context),
                        style: TextStyle(
                          color: vm.isDarkMode ? Colors.white : Colors.black,
                        ),
                        decoration:
                            _inputStyle(
                              AppStrings.get('pass', lang),
                              Icons.lock_outline,
                              primary,
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: primary,
                                ),
                                onPressed: () => setState(
                                  () => _obscureText = !_obscureText,
                                ),
                              ),
                            ),
                      ),
                      const Spacer(flex: 1),

                      vm.isLoading
                          ? CircularProgressIndicator(color: primary)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: vm.isDarkMode
                                    ? Colors.black
                                    : Colors.white,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _handleLogin(vm, context),
                              child: Text(
                                AppStrings.get('btn_access', lang),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
                              AppStrings.get('no_account', lang),
                              style: TextStyle(
                                color: vm.isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                            if (!vm.isOnline)
                              Text(
                                "Offline Mode",
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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

  InputDecoration _inputStyle(String label, IconData icon, Color accent) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accent),
        labelStyle: TextStyle(color: accent),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent.withOpacity(0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accent),
        ),
      );
}
