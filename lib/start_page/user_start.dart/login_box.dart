import 'package:animate_do/animate_do.dart';
import 'package:elysium/widgets/textfield_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginBox extends StatefulWidget{
  const LoginBox({required this.switchbox, required this.logIn, required this.logInWithGoogle, required this.timing, super.key});

  final Function switchbox;
  final Function logInWithGoogle;
  final Function logIn;
  final int timing;

  @override
  State<LoginBox> createState() => _LoginBoxState();
}

class _LoginBoxState extends State<LoginBox> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();
  String? name;
  String? pas;
  bool visible = false;

  @override
  void dispose() {
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build (context) {
    int del = widget.timing;
    return Padding(
      padding: const EdgeInsets.all(20),
      child:Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeInUp(
          delay: Duration(milliseconds: del),
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
          delay: Duration(milliseconds: del + 75),
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
          delay: Duration(milliseconds: del + 100),
          duration: const Duration(milliseconds: 600),
            child: TextButton(
              onPressed: () {}, 
              child: const Text("Forgot Password?")
            )
          )]
        ),
        const SizedBox(height: 10),
        FadeInUp(
          delay: Duration(milliseconds: del + 150),
          duration: const Duration(milliseconds: 600),
          child: Material(
            elevation: 20,
            shadowColor: Colors.black,
            color: Colors.transparent,
              child: MaterialButton(
                minWidth: double.infinity,
                padding: const EdgeInsets.all(15),
                onPressed: () {
                  name = emailController.text.trim().toLowerCase();
                  pas = passController.text.trim();
                  widget.logIn(name, pas);
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
        FadeInUp(
          delay: Duration(milliseconds: del + 200),
          duration: const Duration(milliseconds: 600),
          child: Row(
            children: [
              Expanded(child: Divider(thickness: 0.5, color: Theme.of(context).colorScheme.primary)),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 10, 20),
                child: Text("OR")
              ),
              Expanded(child: Divider(thickness: 0.5, color: Theme.of(context).colorScheme.primary))
            ],
          ),
        ),
        FadeInUp(
          delay: Duration(milliseconds: del + 275),
          duration: const Duration(milliseconds: 600),                                      
          child: MaterialButton(
            color: Theme.of(context).colorScheme.onPrimary,
            height: 40,
            minWidth: double.infinity,
            onPressed: () {widget.logInWithGoogle();}, 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(height: 30, "assets/google-logo.png"),
                const SizedBox(width: 10,),
                Text("Continue with Google", style: GoogleFonts.ptSans(fontSize: 20))
              ]
            )
          ),
        ),
        const SizedBox(height: 12),
        FadeInUp(
          delay: Duration(milliseconds: del + 350),
          duration: const Duration(milliseconds: 600),                                      
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? "),
              TextButton(
                onPressed: () => widget.switchbox(),
                child: Text("Register Now", style: GoogleFonts.lato(color: const Color.fromARGB(255, 29, 86, 255))
              ),)
            ]
          )
        )
      ]
      )
    );
  }
}