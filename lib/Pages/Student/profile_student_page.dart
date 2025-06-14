import 'package:flutter/material.dart';
import 'package:checkin/Pages/Student/profile_student_editor_page.dart';
import 'package:checkin/Pages/Student/password_student_editor_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ProfileStudentPage extends StatefulWidget {
  final String email;
  final VoidCallback onProfileUpdated;

  const ProfileStudentPage({
    super.key,
    required this.email,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileStudentPage> createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> {
  late String id = '';
  late String fullName = '';
  late String gender = '';
  late String email = '';
  late String className = '';
  late String school = '';
  late String photoUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await http.post(
      Uri.parse(
        'http://192.168.242.233/aplikasi-checkin/pages/siswa/get_profile_siswa.php',
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
          email = data['email'];
          className = data['kelas'];
          school = data['nama_sekolah'];
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
        'http://192.168.242.233/aplikasi-checkin/pages/siswa/delete_account_siswa.php',
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
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blueAccent,
                          backgroundImage:
                              photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child:
                              photoUrl.isEmpty
                                  ? Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : '',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildProfileInfo('E-mail', email),
                                _buildProfileInfo(
                                  'Jenis Kelamin',
                                  gender == 'L' ? 'Laki-Laki' : 'Perempuan',
                                ),
                                _buildProfileInfo('Kelas', className),
                                _buildProfileInfo('Sekolah', school),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Tooltip(
                              message: 'Edit Profil',
                              child: IconButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProfileStudentEditorPage(
                                            id: id,
                                            fullName: fullName,
                                            email: email,
                                            gender: gender,
                                            className: className,
                                            school: school,
                                            photoUrl: photoUrl,
                                          ),
                                    ),
                                  );
                                  fetchProfile();
                                },
                                icon: const Icon(Icons.edit),
                                color: Colors.green,
                                iconSize: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Tooltip(
                              message: 'Edit Password',
                              child: IconButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              PasswordStudentEditorPage(
                                                email: widget.email,
                                              ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.key),
                                color: Colors.orangeAccent,
                                iconSize: 30,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Tooltip(
                              message: 'Hapus Akun',
                              child: IconButton(
                                onPressed: _deleteAccount,
                                icon: const Icon(Icons.delete_forever),
                                color: Colors.red,
                                iconSize: 30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
