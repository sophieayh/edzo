import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService{

  signInWithGoogle() async{
    // begin interactive sign in process
    final GoogleSignInAccount? sUser = await GoogleSignIn().signIn();

    // المصادقة على تسجيل الدخول ي الايميل
    final GoogleSignInAuthentication sAuth = await sUser!.authentication;

    // انشاء بيانات اعتماد
    final credential = GoogleAuthProvider.credential(
        accessToken: sAuth.accessToken,
        idToken: sAuth.idToken
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

  }
}