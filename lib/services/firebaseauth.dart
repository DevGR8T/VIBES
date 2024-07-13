import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Authservices {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  //USER REGISTER
  Future register(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      return userCredential.user;
    } on FirebaseException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'The email address is already in use by another account':
          errorMessage =
              'The email address is already in use by another account';
        default:
          errorMessage =
              'The email address is already in use by another account';
      }
      Future.delayed(Duration(seconds: 3), () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 1),
          content: Text(
            errorMessage,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ));
      });
    } catch (e) {
      print(e);
    }
  }

//USER LOGIN

  Future login(String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseException {
      Future.delayed(Duration(seconds: 5), () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(seconds: 2),
          content: Text(
            'Incorrect email or password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ));
      });
    }
  }

  ///USER LOGOUT
  Future logout() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      print(e);
    }
  }

  //SPLASH PAGE
}
