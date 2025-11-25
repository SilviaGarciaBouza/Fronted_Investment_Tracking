
import 'package:flutter/material.dart';
import 'package:investment_tracking/viewmodels/InvViewModel.dart';
import 'package:provider/provider.dart';

class Additem extends StatefulWidget{
  const Additem({super.key});
    static const routeName = '/additem';

  
  @override
  State<Additem> createState() => _AddItem();
}
 


class _AddItem extends State<Additem>{
  @override
  Widget build(BuildContext context) {
    final invViewModel = Provider.of<Invviewmodel>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Center(
          child: Text("My investment", style: TextStyle(color: Colors.green)),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(), 
                  labelText: 'Name'), 

             )
            ),
            Expanded(
              child: TextField(
                controller: TextEditingController(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(), 
                  labelText: 'Category')
            ),),
            Expanded(
              child: TextField(
                controller: TextEditingController(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(), 
                  labelText: 'Quantity')
            ),),

          ],
        ),
        )
    );
  }
}
