import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/start_page/user_start.dart/login_box.dart';
import 'package:elysium/start_page/user_start.dart/register_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserMainAuth extends StatefulWidget{
  const UserMainAuth({required this.successful, required this.backToWelcome, required this.getRole, super.key});

  final Function(String) getRole;
  final Function() successful;
  final Function() backToWelcome;

  @override
  State<UserMainAuth> createState() => _UserMainAuthState();
}

class _UserMainAuthState extends State<UserMainAuth> {
  bool registering = false;
  double boxSize = 460;
  int del = 1000;
  late StreamSubscription<User?> authSubscription;
  bool attempted = false;
  
  void log () {
    setState(() {
      registering = false;
      boxSize = 460;
    });
  }

  void register () {
    setState(() {
      registering = true;
      boxSize = 460;
      del = 1000;
    });
  }

  void signUpUser(name, pas) async {
    try {

      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: name, password: pas);
      
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'role' : 'user',
        'email' : name,
        'name' : '',
        'hours' : 0,
        'gender' : '',
        'applied' : [],
        'completed' : [],
        'upcoming' : [],
        'orgs_worked_with' : [],
        'pending_logs' : [],
        'contact' : '',
        'age' : '',
        'description' : '',
        'occupation' : '',
        
      });

      widget.getRole('user');
      widget.successful();
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
    } catch (e) {
      print("Error: $e");
    }
  }

  void signInWithGoogle() async {
    try {

      final GoogleSignInAccount? user = await GoogleSignIn().signIn();

      if (user == null) {
        return;
      }

      final GoogleSignInAuthentication auth = await user.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken
      );

      final UserCredential uCred = await FirebaseAuth.instance.signInWithCredential(credential);

      if (uCred.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(uCred.user!.uid).set({
          'role' : 'user',
          'email' : uCred.user!.email,
          'name' : uCred.user!.displayName ?? '',
          'hours' : 0,
          'gender' : '',
          'applied' : [],
          'completed' : [],
          'upcoming' : [],
          'orgs_worked_with' : [],
          'pending_logs' : [],
          'contact' : '',
          'age' : '',
          'description' : '',
          'occupation' : '',
        });
      }


      widget.getRole('user');
      widget.successful();

    } catch (e) {
      print("error during signing up or logging in with google: $e");
    }
  }

  void signUserIn(name, pas) async {

    setState(() {
      attempted = true;
    });

    if (name.isEmpty || pas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and password cannot be empty')));
    }

    else {
      String locale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      FirebaseAuth.instance.setLanguageCode(locale);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: name, password: pas);
      } catch (e) {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign-In Error'), 
            content: Text('Failed to sign in: $e'),
            actions: [
              TextButton(onPressed: () {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }, 
              child: const Text('OK'))]);
        });
      }
    }
  }

  void isUser(Function(bool) callback) {
    Future<bool> checkIfUser() async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot details = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (details.exists && details['role'] == 'user') {
          return true;
        }
      else {
        return false;
      }
    }

    checkIfUser().then(callback);
  }

  @override 
  void initState() {
    super.initState();

    authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && attempted) {
        isUser((correctWay) {
          if (correctWay) {
            widget.getRole('user');
            widget.successful();
          }
          else {
            FirebaseAuth.instance.signOut().then((_) {
              if (mounted) {
                showDialog(context: context, builder: (context) => 
                  AlertDialog(
                    actions: [TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('OK'))],
                    content: const Text("You are not authorized to sign in as a user. \n Please sign in as an organization.")
                  )
                ).then((_) {
                  widget.backToWelcome();
                });
            }
            });
        }
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      child: registering ? 
      RegisterBox(switchbox: log, signUp: signUpUser, timing: del, signWithGoogle: signInWithGoogle) 
      : LoginBox(switchbox: register, logIn: signUserIn, timing: del, logInWithGoogle: signInWithGoogle)
    );
  }
}
