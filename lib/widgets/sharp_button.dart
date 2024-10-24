import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SharpButton extends StatelessWidget{
  const SharpButton({required this.onTap, required this.text, required this.icon, super.key, required this.color, required this.iconColor});

  final Function() onTap;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String text;

  @override
  Widget build (context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Material(
        elevation: 20,
        shadowColor: Colors.black,
        color: Colors.transparent,
        child: MaterialButton(
          color: Theme.of(context).colorScheme.secondary,
          focusElevation: 8,
          minWidth: double.infinity,
          height: 90,
          onPressed: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                text, 
                style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onPrimary, fontSize: 20),
                textAlign: TextAlign.left,
              ),
            ],
          )
        ),
      ),
    );
  }
}