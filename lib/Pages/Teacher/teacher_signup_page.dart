import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/Teacher/teacher_login_page.dart';

class TeacherSignupPage extends StatefulWidget {
  const TeacherSignupPage({super.key});

  @override
  _TeacherSignupPageState createState() => _TeacherSignupPageState();
}

class _TeacherSignupPageState extends State<TeacherSignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController kataSandiController = TextEditingController();
  final TextEditingController konfirmasiKataSandiController =
      TextEditingController();
  final TextEditingController namaSekolahController = TextEditingController();

  String? selectedGender;
  File? selectedImage;
  final picker = ImagePicker();

  bool isLoading = false;

  List<TextEditingController> mataPelajaranControllers = [
    TextEditingController(),
  ];

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  void _addMataPelajaranField() {
    setState(() {
      mataPelajaranControllers.add(TextEditingController());
    });
  }

  void _removeMataPelajaranField(int index) {
    setState(() {
      if (mataPelajaranControllers.length > 1) {
        mataPelajaranControllers.removeAt(index);
      }
    });
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

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
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

  Future<void> registerGuru() async {
    if (kataSandiController.text != konfirmasiKataSandiController.text) {
      _showErrorDialog(
        'Registrasi Gagal',
        'Kata sandi dan konfirmasi tidak cocok',
      );
      return;
    }

    if (selectedGender == null) {
      _showErrorDialog('Registrasi Gagal', 'Pilih jenis kelamin');
      return;
    }

    if (selectedImage == null) {
      _showErrorDialog('Registrasi Gagal', 'Upload foto dulu');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/register_guru.php',
        ),
      );

      request.fields['nama_lengkap'] = namaController.text;
      request.fields['email'] = emailController.text;
      request.fields['jenis_kelamin'] = selectedGender!;
      request.fields['nama_sekolah'] = namaSekolahController.text;
      request.fields['kata_sandi'] = kataSandiController.text;
      request.files.add(
        await http.MultipartFile.fromPath('foto', selectedImage!.path),
      );

      for (int i = 0; i < mataPelajaranControllers.length; i++) {
        request.fields['mata_pelajaran'] = mataPelajaranControllers
            .map((c) => c.text)
            .join(',');
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          responseData['message'] == 'Registrasi guru berhasil') {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('guru_email', emailController.text);
        prefs.setString(
          'mata_pelajaran',
          mataPelajaranControllers
              .map((controller) => controller.text)
              .join(','),
        );

        _showSuccessToast('Registrasi berhasil! Silakan login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherLoginPage()),
        );
      } else {
        _showErrorDialog('Registrasi Gagal', responseData['message']);
      }
    } catch (e) {
      _showErrorDialog('Terjadi Kesalahan', '$e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
            children: <Widget>[
              SvgPicture.asset('asset/svg/login.svg', height: 50),
              const SizedBox(height: 20),
              const Text(
                'Silakan Isi Identitas Anda',
                style: TextStyle(
                  fontFamily: 'TitilliumWeb',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: 'Alamat E-Mail',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: namaController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: [
                  DropdownMenuItem(value: 'L', child: Text('Laki-Laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: [
                  ...mataPelajaranControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Mata Pelajaran ${idx + 1}',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          if (mataPelajaranControllers.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removeMataPelajaranField(idx),
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton(
                    onPressed: _addMataPelajaranField,
                    child: const Text('Tambahkan Kolom Mata Pelajaran'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: namaSekolahController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Nama Sekolah',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('Pilih Foto'),
              ),
              if (selectedImage != null) ...[
                const SizedBox(height: 10),
                Text('Nama Foto: ${selectedImage!.path.split('/').last}'),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: kataSandiController,
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: konfirmasiKataSandiController,
                obscureText: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: registerGuru,
                      child: const Text('Registrasi'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
