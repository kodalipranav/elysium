import 'package:flutter/material.dart';

class UserLoading extends StatelessWidget{
  const UserLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}