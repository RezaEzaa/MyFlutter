import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:checkin/Pages/settings_page.dart';

class ProfileAdminEditorPage extends StatefulWidget {
  final String id;
  final String fullName;
  final String gender;
  final String email;
  final String school;
  final String position;
  final String photoUrl;
  const ProfileAdminEditorPage({
    super.key,
    required this.id,
    required this.fullName,
    required this.gender,
    required this.email,
    required this.school,
    required this.position,
    required this.photoUrl,
  });
  @override
  State<ProfileAdminEditorPage> createState() => _ProfileAdminEditorPageState();
}

class _ProfileAdminEditorPageState extends State<ProfileAdminEditorPage> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _schoolController;
  late TextEditingController _positionController;
  String? _gender;
  File? _newProfileImage;
  late String _photoUrl;
  final ImagePicker _picker = ImagePicker();
  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _nameController = TextEditingController(text: widget.fullName);
    _schoolController = TextEditingController(text: widget.school);
    _positionController = TextEditingController(text: widget.position);
    _gender = widget.gender;
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

  Future<Map<String, dynamic>> _saveProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _gender == null ||
        _schoolController.text.trim().isEmpty ||
        _positionController.text.trim().isEmpty) {
      return {"status": "error", "message": "Semua kolom wajib diisi"};
    }
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/edit_profile_admin.php',
      ),
    );
    request.fields['id'] = widget.id;
    request.fields['nama_lengkap'] = _nameController.text.trim();
    request.fields['email'] = _emailController.text.trim();
    request.fields['jenis_kelamin'] = _gender!;
    request.fields['nama_sekolah'] = _schoolController.text.trim();
    request.fields['jabatan'] = _positionController.text.trim();
    if (_newProfileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('foto', _newProfileImage!.path),
      );
    }
    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);
      print("Update Profile Response: $decoded"); // Debug log

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        return {
          "status": "success",
          "message": decoded['message'] ?? "Profil berhasil diperbarui",
          "file_updates": decoded['file_updates'],
          "warnings": decoded['warnings'],
        };
      } else {
        return {
          "status": "error",
          "message": decoded['message'] ?? "Gagal memperbarui profil",
        };
      }
    } catch (e) {
      return {"status": "error", "message": "Terjadi kesalahan: $e"};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
              Image.asset('asset/images/logo.png', width: 120, height: 30),
            ],
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Silakan Edit Profil Anda',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'TitilliumWeb',
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 45,
                backgroundImage:
                    _newProfileImage != null
                        ? FileImage(_newProfileImage!)
                        : (_photoUrl.isNotEmpty
                                ? NetworkImage(_photoUrl)
                                : null)
                            as ImageProvider?,
                child:
                    _newProfileImage == null && _photoUrl.isEmpty
                        ? const Icon(Icons.camera_alt, size: 36)
                        : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _emailController,
              'Alamat E-Mail',
              Icons.email,
              TextInputType.emailAddress,
              TextCapitalization.none,
            ),
            _buildTextField(
              _nameController,
              'Nama Lengkap',
              Icons.person,
              TextInputType.name,
              TextCapitalization.words,
            ),
            _buildGenderDropdown(),
            _buildTextField(
              _positionController,
              'Jabatan',
              Icons.badge,
              TextInputType.text,
              TextCapitalization.words,
            ),
            _buildTextField(
              _schoolController,
              'Nama Sekolah',
              Icons.school,
              TextInputType.text,
              TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 260,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
                onPressed: () async {
                  Map<String, dynamic> result = await _saveProfile();
                  if (!mounted) return;
                  if (result['status'] == "success") {
                    // Show success message with details
                    _showSuccessDialog(result);
                  } else {
                    _showErrorDialog(result['message']);
                  }
                },
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
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Jenis Kelamin',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.wc),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _gender,
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
                _gender = value!;
              });
            },
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Berhasil'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['message'] ?? 'Profil berhasil diperbarui',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (result['file_updates'] != null &&
                      result['file_updates'].isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '📁 Update File:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...((result['file_updates'] as List).map(
                      (update) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $update',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )),
                  ],
                  if (result['warnings'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result['warnings'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous page
                },
              ),
            ],
          ),
    );
  }
}
