import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/Student/student_signup_page.dart';
import 'package:checkin/Pages/Teacher/teacher_signup_page.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

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
                  'Silakan Buat Akun',
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherSignupPage(),
                        ),
                      );
                    },
                    child: const Text('Guru'),
                  ),
                ),
                const SizedBox(height: 0),
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StudentSignupPage(),
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
