import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/Admin/admin_profile_editor_page.dart';
import 'package:checkin/Pages/Admin/admin_password_editor_page.dart';
import 'package:checkin/Pages/shared/school_info_page.dart';

class ProfileAdminPage extends StatefulWidget {
  final String email;
  final VoidCallback onProfileUpdated;
  const ProfileAdminPage({
    super.key,
    required this.email,
    required this.onProfileUpdated,
  });
  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  late String id = '';
  late String fullName = '';
  late String gender = '';
  late String school = '';
  late String position = '';
  late String photoUrl = '';
  bool isLoading = true;
  bool hasSchoolData = false;
  @override
  void initState() {
    super.initState();
    fetchProfile();
    checkSchoolData();
  }

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/get_profile_admin.php',
      ),
      body: {'email': widget.email},
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final data = responseData['data'];
        setState(() {
          id = data['id'].toString();
          fullName = data['nama_lengkap'];
          gender = data['jenis_kelamin'];
          school = data['nama_sekolah'];
          position = data['jabatan'] ?? '';
          photoUrl = data['foto'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print('Gagal memuat data: ${responseData['message']}');
      }
    } else {
      setState(() => isLoading = false);
      print('Request gagal dengan kode: ${response.statusCode}');
    }
  }

  Future<void> checkSchoolData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/admin/get_sekolah_info.php',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hasSchoolData = data['has_data'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking school data: $e');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: const Text('Apakah kamu yakin ingin menghapus akun ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    final response = await http.post(
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/delete_account_admin.php',
      ),
      body: {'email': widget.email},
    );
    final result = json.decode(response.body);
    if (result['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _showSuccessToast('Akun berhasil dihapus');
      Navigator.pushReplacementNamed(context, '/homepage');
    } else {
      _showErrorDialog('Gagal menghapus akun: ${result['message']}');
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
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    IconData icon;
    Color color;
    if (title == 'Jenis Kelamin') {
      if (gender == 'L') {
        icon = Icons.male;
        color = Colors.blue;
      } else if (gender == 'P') {
        icon = Icons.female;
        color = Colors.pink;
      } else {
        icon = Icons.person;
        color = Colors.grey;
      }
    } else if (title == 'Jabatan') {
      icon = Icons.badge;
      color = Colors.teal;
    } else if (title == 'Sekolah') {
      icon = Icons.school;
      color = Colors.green;
    } else if (title == 'Email') {
      icon = Icons.email;
      color = Colors.deepOrange;
    } else {
      icon = Icons.info;
      color = Colors.grey;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          Hero(
                            tag: 'admin-avatar',
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.blue.shade100,
                              backgroundImage:
                                  photoUrl.isNotEmpty
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child:
                                  photoUrl.isEmpty
                                      ? AnimatedScale(
                                        scale: 1,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Text(
                                          fullName.isNotEmpty
                                              ? fullName[0].toUpperCase()
                                              : '',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Card(
                            elevation: 5,
                            shadowColor: Colors.blueGrey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildProfileInfo('Email', widget.email),
                                  const Divider(),
                                  _buildProfileInfo(
                                    'Jenis Kelamin',
                                    gender == 'L' ? 'Laki-Laki' : 'Perempuan',
                                  ),
                                  const Divider(),
                                  _buildProfileInfo('Jabatan', position),
                                  const Divider(),
                                  _buildProfileInfo('Sekolah', school),
                                  if (hasSchoolData) ...[
                                    const Divider(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => const SchoolInfoPage(
                                                    userRole: 'admin',
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.blue
                                                    .withOpacity(0.2),
                                                child: const Icon(
                                                  Icons.info_outline,
                                                  size: 18,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Informasi Sekolah',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Lihat detail informasi sekolah',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: Colors.blue,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.edit,
                                label: 'Edit',
                                color: Colors.green,
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ProfileAdminEditorPage(
                                            id: id,
                                            fullName: fullName,
                                            gender: gender,
                                            email: widget.email,
                                            position: position,
                                            school: school,
                                            photoUrl: photoUrl,
                                          ),
                                    ),
                                  );
                                  fetchProfile();
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.key,
                                label: 'Kata Sandi',
                                color: Colors.orange,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => PasswordAdminEditorPage(
                                            email: widget.email,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.delete_forever,
                                label: 'Hapus',
                                color: Colors.red,
                                onPressed: _deleteAccount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
