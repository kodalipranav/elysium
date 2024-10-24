import 'package:hive_flutter/hive_flutter.dart';
import 'package:elysium/running_model/running_model.dart';
import 'package:flutter/material.dart';
import "package:firebase_core/firebase_core.dart";
import 'firebase_options.dart';
var lColorScheme = ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 225, 214, 179));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  runApp(
    MaterialApp(
      theme: ThemeData().copyWith(
        colorScheme: lColorScheme,
      ),
      home: const RunningModel()
      )
    );
}
