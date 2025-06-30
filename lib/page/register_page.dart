import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../combonent/MyButton.dart';
import '../combonent/MyTextField.dart';
import '../combonent/SquareTitle.dart';
import '../auth_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        backgroundColor: const Color(0xffB8CFCE),
      ),
    );
  }

  void signUserUp(String password) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': Timestamp.now(),
          'role': 'student',
        });
      }

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      if (e.code == 'email-already-in-use') {
        showErrorMessage('Email already in use');
      } else if (e.code == 'weak-password') {
        showErrorMessage('Password is too weak');
      } else {
        showErrorMessage('Something went wrong');
      }
    }
  }

  void onSignUpPressed() {
    final email = emailController.text.trim();
    final pass = passwordController.text;
    final confirmPass = confirmPasswordController.text;

    if (email.isEmpty || pass.isEmpty || confirmPass.isEmpty) {
      showErrorMessage('All fields are required');
      return;
    }

    if (pass != confirmPass) {
      showErrorMessage('Passwords do not match');
      return;
    }

    signUserUp(pass);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFEF9F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.lock, size: 100, color: Color(0xffB8CFCE)),
                const SizedBox(height: 20),
                const Text('Let\'s create an account for you',
                    style: TextStyle(color: Color(0xff333446), fontSize: 16)),
                const SizedBox(height: 20),
                MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false),
                const SizedBox(height: 20),
                MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    obscureText: true),
                const SizedBox(height: 20),
                MyTextField(
                    controller: confirmPasswordController,
                    hintText: 'Confirm Password',
                    obscureText: true),
                const SizedBox(height: 20),
                MyButton(text: 'Sign Up', onTap: onSignUpPressed),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(children: [
                    Expanded(
                        child: Divider(
                            thickness: 5, color: Color(0xffB8CFCE))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25.0),
                      child:
                      Text('Or continue with', style: TextStyle(color: Colors.black)),
                    ),
                    Expanded(
                        child: Divider(
                            thickness: 5, color: Color(0xffB8CFCE))),
                  ]),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTitle(
                      ontap: () => AuthService().signInWithGoogle(),
                      imagepath: 'lib/assets/google.png',
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Log in now',
                        style:
                        TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
