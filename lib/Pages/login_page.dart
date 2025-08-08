import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:checkin/Pages/Teacher/teacher_login_page.dart';
import 'package:checkin/Pages/Student/student_login_page.dart';
import 'package:checkin/Pages/Admin/admin_login_page.dart';
import 'package:checkin/Pages/settings_page.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Login Pengguna',
          style: TextStyle(
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.bold,
          ),
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 80),
                SvgPicture.asset('asset/svg/login.svg', height: 160),
                const SizedBox(height: 30),
                const Text(
                  'Masuk Ke Akun',
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildLoginButton(
                  context,
                  icon: Icons.admin_panel_settings,
                  label: 'Admin',
                  color: Colors.deepPurple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildLoginButton(
                  context,
                  icon: Icons.person,
                  label: 'Guru',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherLoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildLoginButton(
                  context,
                  icon: Icons.group,
                  label: 'Siswa',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StudentLoginPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoginButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontFamily: 'TitilliumWeb'),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: Colors.black45,
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
