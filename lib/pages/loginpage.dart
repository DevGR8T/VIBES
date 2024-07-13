import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_chat_app/pages/homepage.dart';
import 'package:first_chat_app/pages/registerpage.dart';
import 'package:first_chat_app/pages/splashpage.dart';
import 'package:first_chat_app/services/firebaseauth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_email_validator/email_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Formkey = GlobalKey<FormState>();
  TextEditingController namecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController confirmpasswordcontroller = TextEditingController();

  bool hidepassword = true;
  bool hidepassword2 = true;
  bool loading = false;
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
                  'Hi, Welcome Back',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  'Hello again, you\'ve been missed',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                SizedBox(
                  height: 50,
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
                SizedBox(height: 40),

                //LOGIN BUTTON

                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      if (Formkey.currentState!.validate() == false) {
                        setState(() {
                          loading = false;
                        });
                        return null;
                      } else {
                        String email = emailcontroller.text.trim();
                        String password = passwordcontroller.text.trim();

                        User? loginresult = await Authservices()
                            .login(email, password, context);

                        // AFTER LOGIN NAVIGATE TO SPLASHPAGE
                        if (loginresult != null) {
                          Future.delayed(Duration(seconds: 5), () {
                            setState(() {
                              loading = false;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                duration: Duration(seconds: 1),
                                content: Text(
                                  'Login Successful',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.indigo[900],
                              ));
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SplashPage()),
                                  (route) => false);
                            });
                          });
                        }
                      }
                      Future.delayed(Duration(seconds: 5), () {
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
                            'Log In',
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
                    Text('Don\'t have have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterPage(),
                            ),
                            (route) => false);
                      },
                      child: Text(
                        'Register',
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
