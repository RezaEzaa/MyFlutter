import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/Student/student_login_page.dart';

class StudentSignupPage extends StatefulWidget {
  const StudentSignupPage({super.key});

  @override
  _StudentSignupPageState createState() => _StudentSignupPageState();
}

class _StudentSignupPageState extends State<StudentSignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController namaSekolahController = TextEditingController();
  final TextEditingController kataSandiController = TextEditingController();
  final TextEditingController konfirmasiKataSandiController =
      TextEditingController();

  String? selectedGender;
  File? selectedImage;
  final picker = ImagePicker();

  bool isLoading = false;

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
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

  Future<void> registerSiswa() async {
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
      Image.file(selectedImage!, height: 100);
      _showErrorDialog('Registrasi Gagal', 'Upload foto dulu');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Upload ke server PHP
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/siswa/register_siswa.php',
        ),
      );

      request.fields['nama_lengkap'] = namaController.text;
      request.fields['email'] = emailController.text;
      request.fields['jenis_kelamin'] = selectedGender!;
      request.fields['kelas'] = kelasController.text;
      request.fields['nama_sekolah'] = namaSekolahController.text;
      request.fields['kata_sandi'] = kataSandiController.text;

      request.files.add(
        await http.MultipartFile.fromPath('foto', selectedImage!.path),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 &&
          responseData['message'] == 'Registrasi siswa berhasil') {
        // 2. Ambil ID siswa berdasarkan email
        var getIdResponse = await http.post(
          Uri.parse(
            'http://192.168.242.233/aplikasi-checkin/pages/siswa/get_siswa_by_email.php',
          ),
          body: {'email': emailController.text},
        );

        var getIdData = jsonDecode(getIdResponse.body);
        if (getIdResponse.statusCode == 200 &&
            getIdData['status'] == 'success') {
          String siswaId = getIdData['data']['id'];

          // 3. Kirim ke FaceNet
          var facenetRequest = http.MultipartRequest(
            'POST',
            Uri.parse('http://192.168.242.233:5000/api/upload_dataset'),
          );

          facenetRequest.fields['id'] = siswaId;
          facenetRequest.fields['nama_lengkap'] = namaController.text;
          facenetRequest.fields['kelas'] = kelasController.text;
          facenetRequest.files.add(
            await http.MultipartFile.fromPath('foto', selectedImage!.path),
          );

          var facenetResponse = await facenetRequest.send();
          var facenetResponseBody =
              await facenetResponse.stream.bytesToString();
          var faceNetResponseData = jsonDecode(facenetResponseBody);

          if (facenetResponse.statusCode == 200 &&
              faceNetResponseData['status'] == 'success') {
            _showSuccessToast('Registrasi berhasil! Silakan login');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('siswa_email', emailController.text);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StudentLoginPage()),
            );
          } else {
            _showErrorDialog(
              'Gagal Kirim ke FaceNet',
              faceNetResponseData['message'] ?? 'Gagal tidak diketahui',
            );
          }
        } else {
          _showErrorDialog(
            'Gagal Ambil ID',
            getIdData['message'] ?? 'Email tidak ditemukan',
          );
        }
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
        padding: const EdgeInsets.all(16),
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
              decoration: const InputDecoration(
                labelText: 'Alamat E-Mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: namaController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedGender,
              items: const [
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
            TextField(
              controller: kelasController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Kelas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: namaSekolahController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
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
                    onPressed: registerSiswa,
                    child: const Text('Registrasi'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
