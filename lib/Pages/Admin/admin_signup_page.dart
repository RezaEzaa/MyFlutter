import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:checkin/Pages/Admin/admin_login_page.dart';
import 'package:checkin/Pages/settings_page.dart';

class AdminSignupPage extends StatefulWidget {
  const AdminSignupPage({super.key});
  @override
  _AdminSignupPageState createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends State<AdminSignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController kataSandiController = TextEditingController();
  final TextEditingController konfirmasiKataSandiController =
      TextEditingController();
  final TextEditingController namaSekolahController = TextEditingController();
  final TextEditingController jabatanController = TextEditingController();
  String? selectedGender;
  File? selectedImage;
  final picker = ImagePicker();
  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> registerAdmin() async {
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
    if (jabatanController.text.trim().isEmpty) {
      _showErrorDialog('Registrasi Gagal', 'Jabatan tidak boleh kosong');
      return;
    }
    if (selectedImage == null) {
      _showErrorDialog('Registrasi Gagal', 'Upload foto terlebih dahulu');
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/admin/register_admin.php',
        ),
      );
      request.fields['nama_lengkap'] = namaController.text;
      request.fields['email'] = emailController.text;
      request.fields['jenis_kelamin'] = selectedGender!;
      request.fields['jabatan'] = jabatanController.text;
      request.fields['nama_sekolah'] = namaSekolahController.text;
      request.fields['kata_sandi'] = kataSandiController.text;
      request.files.add(
        await http.MultipartFile.fromPath('foto', selectedImage!.path),
      );
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var responseData = jsonDecode(responseBody);
      if (response.statusCode == 200 &&
          responseData['message'] == 'Registrasi admin berhasil') {
        _showSuccessToast('Registrasi berhasil! Silakan login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminLoginPage()),
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
        title: const Text('Login Admin'),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SvgPicture.asset('asset/svg/login.svg', height: 70),
            const SizedBox(height: 20),
            const Text(
              'Registrasi Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'TitilliumWeb',
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              emailController,
              'Alamat E-Mail',
              Icons.email,
              TextInputType.emailAddress,
              TextCapitalization.none,
            ),
            _buildTextField(
              namaController,
              'Nama Lengkap',
              Icons.person,
              TextInputType.name,
              TextCapitalization.words,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedGender,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    hint: const Text("Pilih Jenis Kelamin"),
                    items: const [
                      DropdownMenuItem(
                        value: 'L',
                        child: Row(
                          children: [
                            Icon(Icons.male, color: Colors.blue),
                            SizedBox(width: 10),
                            Text('Laki-Laki'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'P',
                        child: Row(
                          children: [
                            Icon(Icons.female, color: Colors.pink),
                            SizedBox(width: 10),
                            Text('Perempuan'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            _buildTextField(
              jabatanController,
              'Jabatan',
              Icons.badge,
              TextInputType.text,
              TextCapitalization.words,
            ),
            _buildTextField(
              namaSekolahController,
              'Nama Sekolah',
              Icons.school,
              TextInputType.text,
              TextCapitalization.characters,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo),
              onPressed: pickImage,
              label: const Text('Pilih Foto'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CircleAvatar(
                  backgroundImage: FileImage(selectedImage!),
                  radius: 30,
                ),
              ),
            const SizedBox(height: 10),
            _buildPasswordField(
              kataSandiController,
              'Kata Sandi',
              isPasswordVisible,
              () {
                setState(() => isPasswordVisible = !isPasswordVisible);
              },
            ),
            _buildPasswordField(
              konfirmasiKataSandiController,
              'Konfirmasi Kata Sandi',
              isConfirmPasswordVisible,
              () {
                setState(
                  () => isConfirmPasswordVisible = !isConfirmPasswordVisible,
                );
              },
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: 260,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.app_registration),
                    label: const Text('Registrasi'),
                    onPressed: registerAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    TextInputType keyboardType,
    TextCapitalization capitalization,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool isVisible,
    VoidCallback toggleVisibility,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }
}
