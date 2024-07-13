import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_chat_app/models/usermodel.dart';
import 'package:first_chat_app/pages/allchatspage.dart';

import 'package:first_chat_app/pages/individualchat.dart';
import 'package:first_chat_app/pages/communitypage.dart';
import 'package:first_chat_app/pages/loginpage.dart';
import 'package:first_chat_app/pages/profilepage.dart';
import 'package:first_chat_app/services/firebaseauth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.user});
  final User user;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selecteditem = 0;
  late List<Widget> pages;
  @override
  void initState() {
    super.initState();
    pages = [
      AllChatsPage(user: widget.user),
      CommunityPage(
        user: widget.user,
      ),
      ProfilePage(
        user: widget.user,
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selecteditem],
      //BOTTOMNAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: selecteditem,
          onTap: (int tappeditem) {
            setState(() {
              selecteditem = tappeditem;
            });
          },
          selectedItemColor: Colors.indigo[500],
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.group), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'profile'),
          ]),
    );
  }
}
