import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:checkin/Pages/settings_page.dart';

class ProfileTeacherEditorPage extends StatefulWidget {
  final String id;
  final String fullName;
  final String gender;
  final String email;
  final String subject;
  final String school;
  final String photoUrl;

  const ProfileTeacherEditorPage({
    super.key,
    required this.id,
    required this.fullName,
    required this.gender,
    required this.email,
    required this.subject,
    required this.school,
    required this.photoUrl,
  });

  @override
  _ProfileTeacherEditorPageState createState() =>
      _ProfileTeacherEditorPageState();
}

class _ProfileTeacherEditorPageState extends State<ProfileTeacherEditorPage> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _genderController;
  late TextEditingController _subjectController;
  late TextEditingController _schoolController;

  File? _newProfileImage;
  late String _photoUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController(text: widget.fullName);
    _genderController = TextEditingController(text: widget.gender);
    _subjectController = TextEditingController(text: widget.subject);
    _schoolController = TextEditingController(text: widget.school);
    _photoUrl = widget.photoUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _saveProfile() async {
    // Validasi
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _genderController.text.trim().isEmpty ||
        _subjectController.text.trim().isEmpty ||
        _schoolController.text.trim().isEmpty) {
      return "Semua kolom wajib diisi";
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.218.89/aplikasi-checkin/edit_profile_guru.php'),
    );

    request.fields['id'] = widget.id;
    request.fields['nama_lengkap'] = _nameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['jenis_kelamin'] = _genderController.text.trim();
    request.fields['mata_pelajaran'] = _subjectController.text.trim();
    request.fields['nama_sekolah'] = _schoolController.text.trim();

    if (_newProfileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _newProfileImage!.path),
      );
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Server response: $responseBody');

      final decoded = jsonDecode(responseBody);
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        return "success";
      } else {
        return decoded['message'] ?? "Gagal memperbarui profil";
      }
    } catch (e) {
      debugPrint('Error: $e');
      return "Terjadi kesalahan: $e";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Identitas Guru'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Silahkan Edit Identitas Anda',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : (_photoUrl.isNotEmpty
                                ? NetworkImage(_photoUrl)
                                : null)
                            as ImageProvider?,
                child:
                    _newProfileImage == null && _photoUrl.isEmpty
                        ? const Icon(Icons.camera_alt, size: 40)
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            _buildTextField(_emailController, 'Alamat E-Mail'),
            _buildTextField(_nameController, 'Nama Lengkap'),
            _buildGenderDropdown(),
            _buildTextField(_subjectController, 'Mata Pelajaran'),
            _buildTextField(_schoolController, 'Nama Sekolah'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String result = await _saveProfile();
                if (!mounted) return;
                if (result == "success") {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result)));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value:
            _genderController.text.isNotEmpty ? _genderController.text : null,
        items:
            const [
              DropdownMenuItem(value: 'L', child: Text('Laki-Laki')),
              DropdownMenuItem(value: 'P', child: Text('Perempuan')),
            ].toList(),
        onChanged: (value) {
          setState(() {
            _genderController.text = value!;
          });
        },
        decoration: const InputDecoration(
          labelText: 'Jenis Kelamin',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
