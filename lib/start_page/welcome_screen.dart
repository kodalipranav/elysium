import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({required this.switchUser, required this.switchOrg, super.key});

  final Function() switchUser;
  final Function() switchOrg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Center(
            child: Text("Log-in as", style: GoogleFonts.libreBaskerville(fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white))
          ),
          Material(
            elevation: 20,
            shadowColor: Colors.black,
            color: Colors.transparent,
            child: MaterialButton(
              minWidth: double.infinity,
              onPressed: switchUser, 
              color: Theme.of(context).colorScheme.secondary,
              child: Text(
                'User',
                style: GoogleFonts.lato(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),
          Material(
            elevation: 20,
            shadowColor: Colors.black,
            color: Colors.transparent,
            child: MaterialButton(
              minWidth: double.infinity,
              onPressed: switchOrg, 
              color: Theme.of(context).colorScheme.secondary,
              child: Text(
                'Organization',
                style: GoogleFonts.lato(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ),              
        ],
      ),
    );
  }
}