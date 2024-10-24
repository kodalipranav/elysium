import 'package:flutter/material.dart';

class TextfieldWidget extends StatelessWidget{
  const TextfieldWidget({
    required this.hText, this.preIcon, this.postIcon, required this.pressed, required this.obscure, required this.control, super.key
    });

  final String hText;
  final IconData? preIcon;
  final IconButton? postIcon;
  final ValueChanged<String> pressed;
  final bool obscure;
  final TextEditingController control;

  @override  
  Widget build (context) {
    return TextField(
      controller: control,
      onChanged: pressed,
      obscureText: obscure,
      decoration: InputDecoration(
        fillColor: Theme.of(context).colorScheme.onPrimary,
        filled: true,
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        labelText: hText,
        prefixIcon: Icon(preIcon, size: 20),
        suffixIcon: postIcon,
      )
    );
  }

}