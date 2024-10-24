import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InitializeScreen extends StatelessWidget{
  const InitializeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber, Colors.deepOrange], 
            begin: Alignment.bottomLeft, 
            end: Alignment.topRight
          )
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.public, size: 90,),
              const SizedBox(height: 20),
              Text("Name of App", style: GoogleFonts.josefinSans(fontSize: 30)),
          ],)
        ),
      ),
    );
  }
}