import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/user_running_model/demographics_screen.dart';
import 'package:elysium/user_running_model/user_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserRunningModel extends StatefulWidget{
  const UserRunningModel({required this.logOut, super.key});

  final Function() logOut;

  @override
  State<UserRunningModel> createState() => _UserRunningModelState();
}

class _UserRunningModelState extends State<UserRunningModel> {
  late Box userBox;
  late StreamSubscription<DocumentSnapshot> userListener;
  bool initialized = false;
  User? user = FirebaseAuth.instance.currentUser;
  bool demographics = false;

  @override
  void initState() {
    super.initState();
    initializeUser();
  }

  Future<void> initializeUser() async {
    String userID = user!.uid;
    
    userBox = await Hive.openBox(userID);

    if (userBox.isEmpty) {
      DocumentSnapshot userData = await FirebaseFirestore.instance.collection('users').doc(userID).get();
      Map<String, dynamic> mappedData = userData.data() as Map<String, dynamic>;
      await userBox.putAll(mappedData);
    }

    userListener = FirebaseFirestore.instance.collection('users').doc(userID).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic> update = snapshot.data() as Map<String, dynamic>;
        await userBox.putAll(update);
      }
    });
    setState(() {
      initialized = true;
    });
  }

  void doneSettingUp() {
    setState(() {
      demographics = true;
    });
  }

  bool checkData() {
    demographics = userBox.get('gender') != null && userBox.get('gender') != '';
    return demographics;
  }

  @override
  Widget build(BuildContext context) {
    if (!initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator())
      );
    }
    checkData();
    return demographics ? UserHome(signOut: widget.logOut,) : DemographicsScreen(back: widget.logOut, success: () {doneSettingUp();});
  }

  @override
  void dispose() {
    userListener.cancel();
    super.dispose();
  }
}