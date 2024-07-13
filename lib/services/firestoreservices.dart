import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireStoreServices {
  //ADDING THE INFO OF USERS TO FIRESTORE

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future addUserData(
    String profilephoto,
    String name,
    String email,
    String useruid,
  ) async {
    try {
      final User user = firebaseAuth.currentUser!;
      final userId = user.uid;
      await firestore.collection('users').doc(userId).set({
        'name': name,
        'profilephotourl': profilephoto,
        'email': email,
        'date': DateTime.now(),
        'userId': userId,
      });
    } catch (e) {
      print(e);
    }
  }

//GETDATA FROM FIRESTORE
  Future<DocumentSnapshot> getUserData(String userId) async {
    return await firestore.collection('users').doc(userId).get();
  }

  // UPDATE INFO FROM PROFILEPEAGE AND RETRIEVING IT ON UI
  Future updateUserProfile(
    String profileImageUrl,
    String name,
    String about,
    String userId,
  ) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'profilephotourl': profileImageUrl,
        'name': name,
        'about': about,
      });
    } catch (e) {
      print(e);
    }
  }
}
