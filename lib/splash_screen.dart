import 'package:flutter/material.dart';
import 'package:max_baza/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ураїна передала Канаді : ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.blue,
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(color: Colors.blue, width: 2),
                ),

                child: ClipOval(
                  child: Image.asset(
                    'assets/img/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('🇺🇦', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 15),
                    Text('🤝', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 15),
                    Text('🇨🇦', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 15),
                  ],
                ),
              ),
              Text(
                "Договорнячок когда????",
                style: TextStyle(color: Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
