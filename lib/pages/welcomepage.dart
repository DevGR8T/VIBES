import 'package:first_chat_app/pages/registerpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slide_to_act/slide_to_act.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _textAnimation; // Animation for text

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(systemNavigationBarColor: Colors.black));
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Icon(
              Icons.bubble_chart_sharp,
              color: Colors.white,
              size: 120,
            ),
            // Animated text 'VIBENEST'
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value,
                  child: Text(
                    'VIBENEST',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow[400],
                      fontSize: 38 * _textAnimation.value,
                    ),
                  ),
                );
              },
            ),
            // Animated image
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: Image.asset(
                      'images/startp.png',
                      height: 200, // Adjust the size as needed
                      width: 200, // Adjust the size as needed
                    ),
                  ),
                );
              },
            ),
            Text(
              'Welcome to VibeNest!',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[400],
                  fontSize: 28),
            ),
            Text(
              'Discover a whole new way to connect with friends and loved ones. At VibeNest, we believe in creating a cozy and vibrant space where conversations flourish and connections deepen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12),
            ),
            const SizedBox(
              height: 25,
            ),
            // SLIDE BAR
            SlideAction(
              onSubmit: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(),
                  ),
                  (route) => false,
                );
              },
              sliderButtonIcon: Icon(
                Icons.arrow_forward_ios,
                color: Colors.indigo[900],
                size: 15,
              ),
              text: 'slide to start now',
              borderRadius: 50,
              height: 55,
              sliderButtonIconSize: 5,
              textStyle: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
              innerColor: Colors.green[200],
              outerColor: Colors.red[500],
            )
          ],
        ),
      ),
    );
  }
}
