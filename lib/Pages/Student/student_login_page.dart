import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/welcome_page.dart';

class StudentLoginPage extends StatefulWidget {
  const StudentLoginPage({super.key});
  @override
  _StudentLoginPageState createState() => _StudentLoginPageState();
}

class _StudentLoginPageState extends State<StudentLoginPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_siswa_email') ?? '';
    final savedRememberMe = prefs.getBool('siswa_remember_me') ?? false;

    setState(() {
      emailController.text = savedEmail;
      rememberMe = savedRememberMe;
    });
  }

  Future<void> _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('saved_siswa_email', emailController.text.trim());
      await prefs.setBool('siswa_remember_me', true);
    } else {
      await prefs.remove('saved_siswa_email');
      await prefs.setBool('siswa_remember_me', false);
    }
  }

  Future<void> loginSiswa() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      _showErrorDialog("Silakan isi alamat email terlebih dahulu.");
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/siswa/login_siswa.php',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      dynamic responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        _showErrorDialog(
          "Gagal mengurai respon dari server:\n${response.body}",
        );
        return;
      }
      if (response.statusCode == 200 &&
          responseData['message'] == 'Login berhasil') {
        // Save email if remember me is checked
        await _saveEmail();

        _showSuccessToast('Login berhasil!');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('siswa_email', email);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => WelcomePage(
                  userType: 'Siswa',
                  namaLengkap: responseData['data']['nama_lengkap'],
                  userEmail: email,
                ),
          ),
        );
      } else {
        _showErrorDialog(responseData['message'] ?? 'Email tidak terdaftar.');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey,
      fontSize: 16.0,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Login Gagal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tutup'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 80),
              SvgPicture.asset('asset/svg/login.svg', height: 150),
              const SizedBox(height: 20),
              const Text(
                'Masukkan Email Yang Terdaftar',
                style: TextStyle(
                  fontFamily: 'TitilliumWeb',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: 'Alamat E-Mail Terdaftar',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) {
                      setState(() {
                        rememberMe = value ?? false;
                      });
                    },
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                  ),
                  const Text('Ingat email saya'),
                ],
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: 250,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('Masuk'),
                      onPressed: loginSiswa,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
