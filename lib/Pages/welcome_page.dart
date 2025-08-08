import 'package:flutter/material.dart';
import 'package:checkin/Pages/Student/student_home_page.dart';
import 'package:checkin/Pages/Teacher/teacher_home_page.dart';
import 'package:checkin/Pages/Admin/admin_home_page.dart';
class WelcomePage extends StatefulWidget {
  final String userType;
  final String namaLengkap;
  final String? jenisKelamin;
  final String userEmail;
  const WelcomePage({
    super.key,
    required this.userType,
    required this.namaLengkap,
    this.jenisKelamin,
    required this.userEmail,
  });
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}
class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (widget.userType == 'Guru') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherHomePage(email: widget.userEmail),
          ),
        );
      } else if (widget.userType == 'Siswa') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentHomePage(email: widget.userEmail),
          ),
        );
      } else if (widget.userType == 'Admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminHomePage(email: widget.userEmail),
          ),
        );
      }
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  String _generateGreeting() {
    if (widget.userType == 'Guru' || widget.userType == 'Admin') {
      if (widget.jenisKelamin == 'L') {
        return 'Bapak ${widget.namaLengkap}';
      } else if (widget.jenisKelamin == 'P') {
        return 'Ibu ${widget.namaLengkap}';
      }
    }
    return widget.namaLengkap;
  }
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final greeting = _generateGreeting();
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            isDarkMode
                ? 'asset/background/dashboard_gelap.jpg'
                : 'asset/background/dashboard_terang.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_emotions,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Selamat Datang, $greeting!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'LilitaOne',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
