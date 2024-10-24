import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GetUserInfo {
  // Singleton pattern
  static final GetUserInfo _instance = GetUserInfo._internal();
  factory GetUserInfo() => _instance;
  GetUserInfo._internal();

  Future<Map<String, dynamic>?> fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String uid = currentUser.uid;
        print('User uid is: $uid');
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (userDoc.exists) {
          return userDoc.data() as Map<String, dynamic>?;
        } else {
          print("User document does not exist.");
          return null;
        }
      } else {
        print("No user is currently logged in.");
        return null;
      }
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}