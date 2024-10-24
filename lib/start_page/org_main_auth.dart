import 'dart:async';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/widgets/textfield_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrgMainAuth extends StatefulWidget{
  const OrgMainAuth({required this.successful, required this.backToWelcome, required this.getRole, super.key});

  final Function(String) getRole;
  final Function() successful;
  final Function() backToWelcome;

  @override
  State<OrgMainAuth> createState() => _OrgMainAuthState();
}

class _OrgMainAuthState extends State<OrgMainAuth> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  bool visible = false;

  late StreamSubscription<User?> authSubscription;
  
  void signUserIn(name, pas) async {

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
        if (mounted) {
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
                child: const Text('OK'))
              ]
            );
          });
        }
      }
    }
  }

  void isUser(Function(bool) callback) {
    Future<bool> checkIfUser() async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentSnapshot details = await FirebaseFirestore.instance.collection('organizations').doc(currentUser!.uid).get();
      if (details.exists && details['role'] == 'organization') {
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
      isUser((correctWay) {
        if (correctWay) {
          widget.getRole('organization');
          widget.successful();
        }
        else {
          FirebaseAuth.instance.signOut().then((_) {
            if (mounted) {
              showDialog(context: context, builder: (context) => 
                AlertDialog(
                  actions: [TextButton(onPressed: () {Navigator.pop(context);}, child: const Text('OK'))],
                  content: const Text("You are not authorized to sign in as an organization. \n Please sign in as a user.")
                )
              ).then((_) {
                widget.backToWelcome();
              });
          }
          });
       }
      });
    });
  }

  @override 
  Widget build (context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 1000),
            duration: const Duration(milliseconds: 600),
            child: Material(
              elevation: 20,
              shadowColor: Colors.black,
              color: Colors.transparent,
              child: TextfieldWidget(
                control: emailController,
                hText: "Email", 
                pressed: ((value) {}), 
                obscure: false,
                preIcon: Icons.mail_outline,),
            )
            ),
          const SizedBox(height: 10),
          FadeInUp(
            delay: const Duration(milliseconds: 1075),
            duration: const Duration(milliseconds: 600),
            child: Material(
              elevation: 20,
              shadowColor: Colors.black,
              color: Colors.transparent,
              child: TextfieldWidget(
                control: passController,
                hText: "Password", 
                pressed: (value) {}, 
                obscure: !visible,
                preIcon: Icons.lock,
                postIcon: IconButton(onPressed: () {
                  setState(() {
                    visible = !visible;
                  });
                }, icon: Icon(visible ? Icons.visibility : Icons.visibility_off)),
              ),
            )),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [FadeInUp(
            delay: const Duration(milliseconds: 1100),
            duration: const Duration(milliseconds: 600),
              child: TextButton(
                onPressed: () {}, 
                child: const Text("Forgot Password?")
              )
            )]
          ),
          const SizedBox(height: 10),
          FadeInUp(
            delay: const Duration(milliseconds: 1150),
            duration: const Duration(milliseconds: 600),
            child: Material(
              elevation: 20,
              shadowColor: Colors.black,
              color: Colors.transparent,
                child: MaterialButton(
                  minWidth: double.infinity,
                  padding: const EdgeInsets.all(15),
                  onPressed: () {
                    signUserIn(emailController.text.trim().toLowerCase(), passController.text.trim());
                  },                                               
                  color: Theme.of(context).colorScheme.secondary,
                  child: Text("SIGN IN", style: GoogleFonts.josefinSans(
                    fontSize: 20, 
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold
                    ), 
                  )
              )
            ),
          ),
        ]
      ),
    );
  }

  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }
}