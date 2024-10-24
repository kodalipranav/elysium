import 'dart:async';
import 'package:elysium/hive/initialize_hive.dart';
import 'package:elysium/org_running_model/org_running_model.dart';
import 'package:elysium/start_page/start_process.dart';
import 'package:elysium/user_running_model/user_running_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RunningModel extends StatefulWidget {
  const RunningModel({super.key});

  @override
  State<RunningModel> createState() => _RunningModelState();
}

class _RunningModelState extends State<RunningModel> {
  bool signedIn = false;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String? role;
  bool splashOver = false;
  bool isLoading = false;

  void signOut() async {
    print("Sign out ha been called");

    setState(() {
      isLoading = true;
    });

    FirebaseAuth.instance.signOut();
    GoogleSignIn().signOut();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userRole');    
    setState(() {
      signedIn = false;
      role = null;
      currentUser = null;
      isLoading = false;
    });
  }
  
  void alertSignedIn () {
    setState(() {
      signedIn = true;
    });
  }

  Future<void> saveRole(String role) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  void getRole (String type) {
    setState(() {
      role = type;
    });
    saveRole(type);
  }

  void reset () {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RunningModel()));
  }

  Future<void> initializeData() async {
    await initializeHive();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    role = prefs.getString('userRole');

    if (currentUser != null) {
      signedIn = true;
    }

    await Future.delayed(const Duration(seconds: 2));
    splashOver = true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!signedIn) {
          return StartProcess(signed: alertSignedIn, wrongType: reset, role: getRole);
        }

        if (role == 'user') {
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 1)),
            builder: (context, delaySnapshot) {
              if (delaySnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              } else {
                return UserRunningModel(logOut: signOut);
              }
            },
          );
        } else if (role == 'organization') {
          return OrgRunningModel(signOut: signOut);
        } else {
          return Scaffold(
            backgroundColor: Colors.red,
            body: Center(child: Text("ERROR", style: GoogleFonts.lato(fontSize: 30, color: Colors.amber)),)
          );
        }
      },
    );
  }
}
