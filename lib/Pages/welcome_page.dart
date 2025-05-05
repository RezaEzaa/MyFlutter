import 'package:flutter/material.dart';
import 'package:checkin/Pages/Student/student_home_page.dart';
import 'package:checkin/Pages/Teacher/teacher_home_page.dart';

class WelcomePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Membuat greeting terlebih dahulu
    String greeting;
    if (userType == 'Guru') {
      if (jenisKelamin == 'L') {
        greeting = 'Bapak $namaLengkap';
      } else if (jenisKelamin == 'P') {
        greeting = 'Ibu $namaLengkap';
      } else {
        greeting = namaLengkap;
      }
    } else {
      greeting = namaLengkap;
    }

    // Penundaan login untuk navigasi ke halaman berikutnya
    Future.delayed(const Duration(seconds: 2), () {
      if (userType == 'Guru') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    TeacherHomePage(email: userEmail), // Menyertakan email
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    StudentHomePage(email: userEmail), // Menyertakan email
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              isDarkMode
                  ? 'asset/background/dashboard_gelap.jpg'
                  : 'asset/background/dashboard_terang.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Text(
            'Selamat Datang, $greeting!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'LilitaOne',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
