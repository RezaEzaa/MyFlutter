import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import 'package:checkin/Pages/settings_page.dart';

class PasswordTeacherEditorPage extends StatefulWidget {
  final String email;

  const PasswordTeacherEditorPage({super.key, required this.email});

  @override
  State<PasswordTeacherEditorPage> createState() =>
      _PasswordTeacherEditorPageState();
}

class _PasswordTeacherEditorPageState extends State<PasswordTeacherEditorPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  Future<void> _savePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Semua field harus diisi.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorDialog('Password baru dan konfirmasi tidak sama.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/update_password_guru.php',
        ),
        body: {
          'email': widget.email,
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        try {
          final result = json.decode(response.body);
          if (result['status'] == 'success') {
            _showSuccessToast('Password berhasil diperbarui.');
            Navigator.pop(context);
          } else {
            _showErrorDialog(
              result['message'] ?? 'Gagal memperbarui password.',
            );
          }
        } catch (e) {
          _showErrorDialog('Respons bukan JSON yang valid: ${response.body}');
        }
      } else {
        _showErrorDialog(
          'Terjadi kesalahan pada server: ${response.statusCode}',
        );
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
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
          title: const Text('Terjadi Kesalahan'),
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
        title: const Text('Edit Password Guru'),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SvgPicture.asset('asset/svg/login.svg', height: 150),
                const Text(
                  'Silakan Ganti Password Anda',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildTextField(_oldPasswordController, 'Password Lama', true),
                _buildTextField(_newPasswordController, 'Password Baru', true),
                _buildTextField(
                  _confirmPasswordController,
                  'Konfirmasi Password Baru',
                  true,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: _savePassword,
                        child: const Text('Simpan'),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool obscure,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        textCapitalization: TextCapitalization.none, // <-- tambahkan ini
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
