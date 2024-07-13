import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:first_chat_app/pages/homepage.dart';
import 'package:first_chat_app/pages/loginpage.dart';
import 'package:first_chat_app/pages/splashpage.dart';
import 'package:first_chat_app/services/firebaseauth.dart';
import 'package:first_chat_app/services/firebasestorage.dart';
import 'package:first_chat_app/services/firestoreservices.dart';
import 'package:first_chat_app/services/firestoreservices.dart';
import 'package:first_chat_app/services/firestoreservices.dart';
import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Formkey = GlobalKey<FormState>();
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();

  bool hidepassword = true;
  bool hidepassword2 = true;
  bool loading = false;

  File? selectedimage;
  String? filename;

//UPLOADING PROFILE IMAGE
  Future uploadprofileimage() async {
    final picker = ImagePicker();
    final XFile? pickedimage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedimage != null) {
      setState(() {
        filename = pickedimage.name;
        selectedimage = File(pickedimage.path);
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Form(
            key: Formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let\'s get going!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'Register an account using the form below',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                SizedBox(
                  height: 10,
                ),

                //PROFILE PHOTO
                Center(
                  child: InkWell(
                    onTap: () {
                      uploadprofileimage();
                    },
                    child: CircleAvatar(
                        radius: 50,
                        backgroundImage: selectedimage != null
                            ? FileImage(selectedimage!)
                            : const NetworkImage(
                                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTW3l55YyVkg7l1vDB9qkE5QjVRmLEbA_YOHJ_SAFN5WQ&s')
                                as ImageProvider),
                  ),
                ),
                SizedBox(
                  height: 17,
                ),

                //NAMEFIELD
                TextFormField(
                  controller: namecontroller,
                  validator: (name) {
                    if (name == '') {
                      return 'please enter your name';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Full Name',
                    counterText: '',
                  ),
                  maxLength: 18,
                ),

                //EMAILFIELD
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  child: TextFormField(
                    controller: emailcontroller,
                    validator: (email) {
                      if (email == '') {
                        return 'Please enter your Email';
                      } else if (!EmailValidator.validate(email!)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(), hintText: 'Email'),
                  ),
                ),

                // PASSWORDFIELD
                TextFormField(
                  controller: passwordcontroller,
                  obscureText: hidepassword,
                  validator: (password) {
                    if (password == '') {
                      return 'Enter a password ';
                    } else if (password!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidepassword = !hidepassword;
                        });
                      },
                      icon: Icon(hidepassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                SizedBox(height: 25),

                //CONFIRM PASSSWORD FIELD
                TextFormField(
                  controller: confirmpasswordcontroller,
                  validator: (password) {
                    if (password == '') {
                      return 'Confirm password ';
                    } else if (password!.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                  obscureText: hidepassword2,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Confirm Password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidepassword2 = !hidepassword2;
                        });
                      },
                      icon: Icon(hidepassword2
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                SizedBox(height: 25),

                //REGISTER BUTTON
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });

                      if (Formkey.currentState!.validate() == false &&
                          selectedimage == null) {
                        setState(() {
                          loading = false;
                        });
                        return null;
                      } else if (selectedimage == null) {
                        setState(() {
                          loading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            'please add a profile photo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.red,
                        ));
                      } else if (passwordcontroller.text !=
                          confirmpasswordcontroller.text) {
                        setState(() {
                          loading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text(
                            'Pasword do not match',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.red,
                        ));
                      } else {
                        final email = emailcontroller.text.trim();
                        final password = passwordcontroller.text.trim();

                        // FIREBASE REGISTER AUTHENTICATION

                        User? result = await Authservices()
                            .register(email, password, context);
                        if (result != null) {
                          // UPLOAD IMAGE TO FIRESTORAGE
                          String imageurl = await FirebaseStorage.instanceFor(
                                  bucket: 'gs://chattingapp-e2f20.appspot.com')
                              .ref(filename)
                              .putFile(selectedimage!)
                              .then((result) {
                            return result.ref.getDownloadURL();
                          });
                          print(imageurl);

                          //ADD(UPLOAD) DATA TO FIRESTORE()
                          String profilephotourl = imageurl;
                          String name = namecontroller.text;

                          String email = emailcontroller.text;

                          String userId = result.uid;

                          await FireStoreServices().addUserData(
                              profilephotourl, name, email, userId);

                          Future.delayed(Duration(seconds: 0), () async {
                            setState(() {
                              loading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Registration Complete',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.indigo[900],
                            ));

                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SplashPage(),
                                ),
                                (route) => false);
                          });
                        }
                      }
                      Future.delayed(Duration(seconds: 3), () {
                        setState(() {
                          loading = false;
                        });
                      });
                    },
                    child: loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                backgroundColor: Colors.white,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'please wait...',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          )
                        : Text(
                            'Register',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                            (route) => false);
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      )),
    );
  }
}
