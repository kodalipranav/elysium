import 'package:animate_do/animate_do.dart';
import 'package:elysium/start_page/org_main_auth.dart';
import 'package:elysium/start_page/user_start.dart/user_main_auth.dart';
import 'package:elysium/start_page/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class StartProcess extends StatefulWidget{
  const StartProcess({required this.signed, required this.wrongType, required this.role, super.key});

  final Function() signed;
  final Function(String) role;
  final Function() wrongType;

  @override
  State<StartProcess> createState() => _StartProcessState();
}

class _StartProcessState extends State<StartProcess> {
  Widget? widgetShowing;
  double boxSize = 460;
  String mainText = 'Welcome';
  bool boxShowing = false;
  bool backShowing = false;
  double textSize = 60;

  void userScreen() {
    setState(() {
      backShowing = true;
      boxShowing = true;
      mainText = 'User';
      widgetShowing = UserMainAuth(successful: widget.signed, backToWelcome: widget.wrongType, getRole: widget.role);
    });
  }

  void orgScreen() {
    setState(() {
      backShowing = true;
      boxShowing = true;
      mainText = 'Organization';
      textSize = 45;
      widgetShowing = OrgMainAuth(successful: widget.signed, backToWelcome: widget.wrongType, getRole: widget.role);
    });
  }

  void back() {
    setState(() {
      backShowing = false;
      boxShowing = false;
      mainText = 'Welcome';
      widgetShowing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    widgetShowing ??= WelcomeScreen(switchUser: userScreen, switchOrg: orgScreen);
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
                child: Image.asset(
                  'assets/stanford.jpg', 
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                  alignment: Alignment.center,
                  opacity: const AlwaysStoppedAnimation(0.35),)),
            SafeArea(
              child: Column(
                children: [
                  if (backShowing) 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0), 
                          child: IconButton(
                            onPressed: back, 
                            icon: const Icon(Icons.arrow_back_sharp, color: Colors.white,),
                            )
                        ),
                      ],
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeInDown(
                            delay: const Duration(milliseconds: 2000),
                            duration: const Duration(milliseconds: 1000),
                            child: Text(mainText, style: GoogleFonts.josefinSans(
                              color: const Color.fromARGB(255, 247, 248, 235), fontSize: textSize, fontWeight: FontWeight.bold)
                            )
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: FadeInUp(
                              delay: const Duration(milliseconds: 4000),
                              duration: const Duration(milliseconds: 900),
                              child: Material(
                                elevation: 20,
                                shadowColor: boxShowing ? Colors.black : Colors.transparent,
                                color: Colors.transparent,
                                child: Container(
                                  width: double.infinity,
                                  height: boxSize,
                                  decoration: BoxDecoration(
                                    color: boxShowing ? Colors.white.withOpacity(0.9) : Colors.transparent,
                                    border: Border.all(width: 4, color: boxShowing ? const Color.fromARGB(255, 251, 253, 228).withOpacity(0.2) : Colors.transparent),
                                    borderRadius: const BorderRadius.all(Radius.circular(10))
                                  ),
                                  child: widgetShowing
                                )
                              )
                            )
                          )
                        ]
                        )
                      )
                    ),
                  ),
                ],
              )
            )
          ]
        )
      )
    );
  }
}