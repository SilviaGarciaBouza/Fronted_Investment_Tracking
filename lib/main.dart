import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:investment_tracking/views/AddItem.dart';
import 'package:investment_tracking/views/HomeView.dart';
import 'package:investment_tracking/views/total_view.dart';
import 'package:investment_tracking/views/LoginView.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

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

          primaryColor: Colors.lightGreenAccent,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Colors.lightGreenAccent,
            secondary: Colors.lightGreenAccent,
          ),
        ),
        initialRoute: LoginView.routeName,

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
