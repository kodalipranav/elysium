import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignWithGoogle {

  static signInWithGoogle() async {

    final GoogleSignInAccount? gAccount = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication gAuth = await gAccount!.authentication;

    final details = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken
    );

    return await FirebaseAuth.instance.signInWithCredential(details);

  }
}