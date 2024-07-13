import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/pages/homepage.dart';
import 'package:first_chat_app/pages/loginpage.dart';
import 'package:first_chat_app/services/firebaseauth.dart';
import 'package:first_chat_app/services/firebasestorage.dart';
import 'package:first_chat_app/services/firestoreservices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required User user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final formkey = GlobalKey<FormState>();

  bool isEdit = false;
  bool loadsave = false;

  // RETRIEVING/FETCHING/GET DATA FROM FIRESTORE

  bool isLoading = true;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  UserModel? userModel;
  File? selectedImage;
  String? fileName;

  TextEditingController nameController = TextEditingController();
  TextEditingController aboutController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    try {
      User? user = firebaseAuth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await FireStoreServices().getUserData(user.uid);

        setState(() {
          userModel = UserModel.fromDocumentSnapshot(
              userDoc); // Make sure you have a UserModel.fromDocumentSnapshot method

          userModel = UserModel.fromDocumentSnapshot(userDoc);
          isLoading = false;
          nameController.text = userModel!.name;
          aboutController.text = userModel!.about;
          emailController.text = userModel!.email;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }

      // Print the email value to check if it's correctly fetched
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  // UPLOADING PROFILE IMAGE
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
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if userModel is null and handle accordingly
    if (userModel == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'User data not found.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(user: user),
                ),
                (route) => false,
              );
            }
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        actions: [
          // LOGOUT BUTTON
          // LOGOUT BUTTON
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'Logout') {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('Confirm Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Center(
                                    child: CircularProgressIndicator(
                                  backgroundColor: Colors.white,
                                  color: Colors.indigo[900],
                                ));
                              },
                            );
                            setState(() {
                              isLoading =
                                  true; // Show circular progress indicator
                            });

                            // Show the circular progress indicator for 10 seconds
                            await Future.delayed(Duration(seconds: 5));

                            // Logout after the delay
                            try {
                              await Authservices().logout();
                              // Ensure to push the LoginPage after the logout
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                                (route) => false,
                              );
                              DelightToastBar(
                                snackbarDuration: Duration(seconds: 2),
                                autoDismiss: true,
                                position: DelightSnackbarPosition.top,
                                builder: (context) {
                                  return ToastCard(
                                    title: Text(
                                      'Successfully Logged out!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    leading: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                    ),
                                    color: Colors.indigo[500],
                                  );
                                },
                              ).show(context);
                            } catch (e) {
                              print('Logout error: $e');
                              setState(() {
                                isLoading = false;
                              });
                              // Show an error message
                              DelightToastBar(
                                snackbarDuration: Duration(seconds: 2),
                                autoDismiss: true,
                                position: DelightSnackbarPosition.top,
                                builder: (context) {
                                  return ToastCard(
                                    title: Text(
                                      'Failed to log out!',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    leading: Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                    color: Colors.red[500],
                                  );
                                },
                              ).show(context);
                            }
                          },
                          child: Text('Logout',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Center(
                  child: Text(
                    'Logout',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                value: 'Logout',
              ),
            ],
          )
        ],
      ),

      // BODY OF PROFILE PAGE
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Form(
              key: formkey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PROFILE PHOTO
                  isEdit
                      ? InkWell(
                          onTap: uploadProfileImage,
                          child: Container(
                            height: 135,
                            width: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.purple[100],
                            ),
                            child: Container(
                              height: 120,
                              width: 120,
                              child: selectedImage == null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: userModel!.profilePhotoUrl,
                                        placeholder: (context, url) =>
                                            Image.asset(
                                                'images/profileplaceholder.jpg'),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        fit: BoxFit.cover,
                                        width: 127,
                                        height: 127,
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.file(
                                        File(selectedImage!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          radius: 67,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: userModel!.profilePhotoUrl,
                              placeholder: (context, url) =>
                                  Image.asset('images/profileplaceholder.jpg'),
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                              fit: BoxFit.cover,
                              width: 127,
                              height: 127,
                            ),
                          ),
                        ),
                  SizedBox(height: 20),

                  // TEXTFIELDS OF PROFILE PAGE

                  // NAME TEXTFIELD
                  TextFormField(
                    controller: nameController,
                    validator: (name) {
                      if (name == '') {
                        return 'please enter your name';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person, color: Colors.purple[300]),
                      border: InputBorder.none,
                      enabled: isEdit,
                      filled: isEdit,
                      fillColor: Colors.white,
                      counterText: '',
                    ),
                    readOnly: !isEdit,
                    maxLength: 18,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                  SizedBox(height: 10),

                  // ABOUT TEXTFIELD
                  TextFormField(
                    controller: aboutController,
                    validator: (aboutdetails) {
                      if (aboutdetails == '') {
                        return 'field required* ';
                      } else if (aboutdetails!.length < 60) {
                        return 'Must be at least 60 characters';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'About',
                      prefixIcon: Icon(Icons.info, color: Colors.purple[300]),
                      border: InputBorder.none,
                      enabled: isEdit,
                      filled: isEdit,
                      fillColor: Colors.white,
                    ),
                    readOnly: !isEdit,
                    maxLength: 150,
                  ),
                  SizedBox(height: 10),

                  // EMAIL TEXTFIELD
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: Colors.purple[300],
                      ),
                      border: InputBorder.none,
                      enabled: false,
                      filled: isEdit,
                      fillColor: Colors.white,
                    ),
                    readOnly: !isEdit,
                  ),
                  SizedBox(height: 10),

                  // SAVE/EDIT BUTTON
                  Container(
                    margin: EdgeInsets.only(top: 30),
                    padding: EdgeInsets.all(8),
                    width: MediaQuery.of(context).size.width / 2,
                    decoration: BoxDecoration(
                      color: Colors.indigo[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isEdit
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              //LOADING SAVING IN PROFILEPAGE TO AVIOID MUCH CLICKING

                              loadsave
                                  ? Row(
                                      children: [
                                        SizedBox(
                                          height: 40,
                                          child: CircularProgressIndicator(
                                              backgroundColor: Colors.white),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'saving...',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        )
                                      ],
                                    )
                                  : TextButton.icon(
                                      onPressed: () async {
                                        setState(() {
                                          loadsave = true;
                                        });
                                        if (formkey.currentState!.validate() ==
                                            false) {
                                          setState(() {
                                            loadsave = false;
                                          });
                                          return null;
                                        }

                                        // CALL UPDATE PROFILE METHOD WHEN SAVING
                                        String? profileImageUrl =
                                            userModel!.profilePhotoUrl;

                                        //UPLOAD NEW PROFILE IMAGE IF SELECTED
                                        if (selectedImage != null) {
                                          profileImageUrl =
                                              await FirebaseServices()
                                                  .uploadPhoto(File(
                                            selectedImage!.path,
                                          ));
                                        }
                                        if (profileImageUrl != null) {
                                          await FireStoreServices()
                                              .updateUserProfile(
                                            profileImageUrl,
                                            nameController.text,
                                            aboutController.text,
                                            userModel!.userId,
                                          );

                                          // Retrieve updated data
                                          getUserData();

                                          setState(() {
                                            isEdit = false;
                                            loadsave = false;
                                          });

                                          // Show a success message

                                          DelightToastBar(
                                            snackbarDuration:
                                                Duration(seconds: 2),
                                            autoDismiss: true,
                                            position:
                                                DelightSnackbarPosition.top,
                                            builder: (context) {
                                              return ToastCard(
                                                title: Text(
                                                  'Profile updated successfully!',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                leading: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                ),
                                                color: Colors.indigo[500],
                                              );
                                            },
                                          ).show(context);
                                        } else {
                                          // Show an error message
                                          DelightToastBar(
                                            snackbarDuration:
                                                Duration(seconds: 2),
                                            autoDismiss: true,
                                            position:
                                                DelightSnackbarPosition.top,
                                            builder: (context) {
                                              return ToastCard(
                                                title: Text(
                                                  'Failed to update profile image!',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                leading: Icon(
                                                  Icons.error,
                                                  color: Colors.white,
                                                ),
                                                color: Colors.red[500],
                                              );
                                            },
                                          ).show(context);
                                        }
                                      },
                                      icon: Icon(
                                        Icons.save_as,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    isEdit = !isEdit;
                                  });
                                },
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
