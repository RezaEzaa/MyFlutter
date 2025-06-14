import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/welcome_page.dart';

class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  _TeacherLoginPageState createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> loginGuru() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/login_guru.php',
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "kata_sandi": passwordController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      // Tangani jika respons bukan JSON
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
        _showSuccessToast('Login berhasil!');

        String userEmail = emailController.text;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guru_email', userEmail);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => WelcomePage(
                  userType: 'Guru',
                  namaLengkap: responseData['data']['nama_lengkap'],
                  jenisKelamin: responseData['data']['jenis_kelamin'],
                  userEmail: userEmail,
                ),
          ),
        );
      } else {
        _showErrorDialog(responseData['message']);
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
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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
                'Silakan Isi Kolom Di Bawah',
                style: TextStyle(
                  fontFamily: 'TitilliumWeb',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress, // <-- ini penting
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Alamat E-Mail Yang Terdaftar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                textCapitalization:
                    TextCapitalization.none, // <-- ini juga penting
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: loginGuru,
                      child: const Text('Masuk'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
