import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/pages/individualchat.dart';
import 'package:first_chat_app/pages/loginpage.dart';
import 'package:first_chat_app/services/firebaseauth.dart';
import 'package:first_chat_app/services/firestoreservices.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({required this.user, super.key});
  final User user;

  @override
  State<CommunityPage> createState() => CommunityPageState();
}

class CommunityPageState extends State<CommunityPage> {
  bool isLoading = true;
  bool isSearched = false;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  late UserModel? userModel;
  List<UserModel> userslist = [];
  File? selectedImage;
  String? fileName;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    getUsersData(); //GETTING DATA FROM FIRESTORE
  }

  //FETCHING USERS FROM FIRESTORE

  void getUsersData() async {
    try {
      // Fetch all users from Firestore
      QuerySnapshot usersQuery =
          await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        // Filter out the logged-in user
        userslist = usersQuery.docs
            .map((doc) => UserModel.fromDocumentSnapshot(doc))
            .where((user) => user.userId != widget.user.uid)
            .toList();

        // Assuming the first user in the list is the current user
        userModel = userslist.isNotEmpty ? userslist.first : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  // UPLOADING USER IMAGE(Allows the user to pick an image from the gallery and sets selectedImage and fileName accordingly.)

  Future<void> uploadProfileImage() async {
    final picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        fileName = pickedImage.name;
        selectedImage = File(pickedImage.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //LOADING BEFORE ALLCHATSPAGE OPENS
    if (isLoading) {
      return Scaffold(
          body: Center(
        child: CircularProgressIndicator(),
      ));
    }

    // Check if userModel is null and handle accordingly
    if (userModel == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No Messages',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    //BUT IF THERE IS DATA
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[900],
          title: Text(
            'Community',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    isSearched = !isSearched;
                    if (!isSearched) {
                      searchText = ''; // Clear search text when closing search
                    }
                  });
                },
                icon: isSearched ? Icon(Icons.close) : Icon(Icons.search))
          ],
        ),
        //REGISTERED USERS
        body: Column(children: [
          //SEARCH USER FIELD

          isSearched
              ? Container(
                  height: 48,
                  padding: EdgeInsets.all(5),
                  margin: EdgeInsets.symmetric(horizontal: 7),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {
                        searchText = value.trim(); // Update search text
                      });
                    },
                    onSubmitted: (value) {},
                    decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.black.withOpacity(0.4)),
                        hintText: 'Search name',
                        hintStyle:
                            TextStyle(color: Colors.black.withOpacity(0.4)),
                        contentPadding: EdgeInsets.all(5)),
                  ))
              : SizedBox(),
          Expanded(
            child: ListView.builder(
              itemCount: userslist.length,
              itemBuilder: (context, index) {
                UserModel theuser = userslist[index];
                // Apply search filter
                if (searchText.isNotEmpty &&
                    !theuser.name
                        .toLowerCase()
                        .contains(searchText.toLowerCase())) {
                  return SizedBox.shrink(); // Hide if not matched
                }
                return Card(
                  elevation: 0,
                  child: ListTile(
                    //PROFILE PIC
                    contentPadding: EdgeInsets.all(5),
                    leading: CircleAvatar(
                      radius: 25,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: theuser.profilePhotoUrl,
                          placeholder: (context, url) =>
                              Image.asset('images/profileplaceholder.jpg'),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.error),
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    //  USER NAME
                    title: Text(
                      theuser.name,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/individualchats',
                          arguments: theuser);
                    },
                    subtitle: Text(
                      theuser.about,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),
                );
              },
            ),
          ),
        ]));
  }
}
