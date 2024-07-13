import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/pages/homepage.dart';
import 'package:first_chat_app/pages/individualchat.dart';
import 'package:first_chat_app/pages/loginpage.dart';
import 'package:first_chat_app/pages/profilepage.dart';
import 'package:first_chat_app/pages/profileupdate.dart';
import 'package:first_chat_app/pages/registerpage.dart';
import 'package:first_chat_app/pages/splashpage.dart';
import 'package:first_chat_app/pages/welcomepage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "",
        appId: '1:140503716465:android:0f114e56d1f63b1d7a81d0',
        messagingSenderId: '140503716465',
        projectId: 'chattingapp-e2f20',
        storageBucket: "gs://chattingapp-e2f20.appspot.com"),
  );
  // Initialize Firebase App Check

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //TRANSITION FOR ALL PAGES
  PageRouteBuilder<dynamic> customPageRouteBuilder(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Start from right
        const end = Offset.zero; // End at original position
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = ProfilePage(
              user: FirebaseAuth.instance.currentUser!,
            );
            break;
          case '/login':
            page = LoginPage();
            break;
          case '/home':
            final user =
                settings.arguments as User; // If you need to pass arguments
            page = HomePage(user: user);
            break;
          case '/individualchats':
            final chats = settings.arguments as UserModel;
            page = IndividualChat(
              user: chats,
            );
            break;
          case '/updateprofilepage':
            page = ProfileUpdatePage();
            break;
          default:
            final user = settings.arguments as User;
            page = HomePage(user: user); // Default to ProfilePage
        }

        return customPageRouteBuilder(page);
      },
      theme: ThemeData(
        textTheme: GoogleFonts.aBeeZeeTextTheme(),
        appBarTheme: AppBarTheme(
            backgroundColor: Colors.indigo[900],
            titleTextStyle: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500),
            iconTheme: IconThemeData(color: Colors.white)),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo[900],
            shape: RoundedRectangleBorder(),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashPage(); // Show a loading screen while checking auth state
          } else if (snapshot.hasData && snapshot.data != null) {
            return HomePage(
                user: snapshot.data!); // User is authenticated, show home
          } else {
            return WelcomePage(); // User is not authenticated, show welcome/login page
          }
        },
      ),
    );
  }
}
