import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:investment_tracking/views/total_view.dart';
import 'package:investment_tracking/views/LoginView.dart'; // Importa el nuevo login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Invviewmodel(),
      child: MaterialApp(
        title: "Investment App",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          // Eliminamos primarySwatch para evitar azules ocultos
          primaryColor: Colors.lightGreenAccent,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.lightGreenAccent,
            secondary: Colors.lightGreenAccent,
          ),
        ),
        initialRoute: LoginView.routeName, // Empezamos por el login
        routes: {
          LoginView.routeName: (_) => LoginView(),
          Homeview.routeName: (_) => const Homeview(),
          Additem.routeName: (_) => const Additem(),
          TotalView.routeName: (_) => const TotalView(),
        },
      ),
    );
  }
}
