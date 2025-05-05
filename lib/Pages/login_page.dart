import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:checkin/Pages/Teacher/teacher_login_page.dart';
import 'package:checkin/Pages/Student/student_login_page.dart';
import 'package:checkin/Pages/settings_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 120),
                SvgPicture.asset('asset/svg/login.svg', height: 150),
                const SizedBox(height: 20),
                const Text(
                  'Masuk Ke Akun',
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 250, // Lebar tombol
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigasi ke halaman untuk guru
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherLoginPage(),
                        ),
                      );
                    },
                    child: const Text('Guru'),
                  ),
                ),
                const SizedBox(height: 0),
                SizedBox(
                  width: 250, // Lebar tombol
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigasi ke halaman untuk siswa
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentLoginPage(),
                        ),
                      );
                    },
                    child: const Text('Siswa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
