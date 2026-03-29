import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/views/LoginView.dart';
import 'package:investment_tracking/views/total_view.dart';

/// Punto de entrada de la aplicación.
void main() {
  runApp(const MyApp());
}

/// Configura el tema visual y las rutas de navegación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InvViewModel(),
      child: MaterialApp(
        title: "Investment App",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.lightGreenAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.lightGreenAccent,
            secondary: Colors.lightGreenAccent,
          ),
        ),
        initialRoute: LoginView.routeName,
        routes: {
          LoginView.routeName: (_) => const LoginView(),
          Homeview.routeName: (_) => const Homeview(),
          Additem.routeName: (_) => const Additem(),
          TotalView.routeName: (_) => const TotalView(),
        },
      ),
    );
  }
}
