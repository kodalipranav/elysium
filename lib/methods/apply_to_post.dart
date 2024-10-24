import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> applyToPost (context, bool recurring, String docID) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  String userID = currentUser!.uid;
  Box postBox = recurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
  Map<String, dynamic> postDetails = postBox.get(docID);
  Map alreadyApplied = postDetails['applied_volunteers'];
  List accepted = postDetails['accepted_volunteers'];
  List denied = postDetails['denied'];

  bool acceptedAlready(String userID) {
    for (Map singleUser in accepted) {
      if (singleUser.keys.contains(userID)) {
        return true;
      }
    }
    return false;
  }

  bool deniedAlready(String userID) {
    for (Map singleUser in denied) {
      if (singleUser.keys.contains(userID)) {
        return true;
      }
    }
    return false;
  }

  bool accept = acceptedAlready(userID);
  bool deny = deniedAlready(userID);

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  if (!alreadyApplied.containsKey(userID) && !accept && !deny) {
    Box userBox = Hive.box(userID);

    Map<String, dynamic> userInfo = {
      'email' : userBox.get('email'),
      'name' : userBox.get('name'),
      'gender' : userBox.get('gender'),
      'contact' : userBox.get('contact'),
      'age' : userBox.get('age'),
      'description' : userBox.get('description'),
      'occupation' : userBox.get('occupation'),
      'timestamp' : FieldValue.serverTimestamp(),
    };

    String collect = recurring ? 'recurring' : 'non_recurring';

    await FirebaseFirestore.instance.collection(collect).doc(docID).update({
      'applied_volunteers.$userID' : userInfo
    });

    await FirebaseFirestore.instance.collection('users').doc(userID).update({
      'applied' : FieldValue.arrayUnion([docID])
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Succesfully applied for the post!"),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'Undo', onPressed: () async {
          await FirebaseFirestore.instance.collection(collect).doc(docID).update({
            'applied_volunteers.$userID' : FieldValue.delete()
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Application undone."))
          );
        }),
      )
    );

  } else {
    if (alreadyApplied.containsKey(userID)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already applied for this post!"))
      );
    } else if (accept) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already been accepted for this post!"))
      );
    } else if (deny) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You have already been rejected for this post."))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ERROR"))
      );
    }
  }
}