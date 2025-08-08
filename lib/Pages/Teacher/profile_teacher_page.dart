import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:checkin/Pages/shared/school_info_page.dart';
import 'package:checkin/Pages/shared/admin_creator_info_page.dart';

class ProfileTeacherPage extends StatefulWidget {
  final String email;
  final VoidCallback onProfileUpdated;
  const ProfileTeacherPage({
    super.key,
    required this.email,
    required this.onProfileUpdated,
  });
  @override
  State<ProfileTeacherPage> createState() => _ProfileTeacherPageState();
}

class _ProfileTeacherPageState extends State<ProfileTeacherPage> {
  late String id = '';
  late String fullName = '';
  late String gender = '';
  late String email = '';
  late String prodi = '';
  late String photoUrl = '';
  bool isLoading = true;
  bool hasSchoolData = false;
  bool hasAdminCreatorInfo = false;
  @override
  void initState() {
    super.initState();
    fetchProfile();
    checkSchoolData();
    checkAdminCreatorInfo();
  }

  Future<void> fetchProfile() async {
    setState(() => isLoading = true);
    final response = await http.post(
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/guru/get_profile_guru.php',
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
          prodi = data['prodi'] ?? '';
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
          'http://10.167.91.233/aplikasi-checkin/pages/guru/get_sekolah_info.php',
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

  Future<void> checkAdminCreatorInfo() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/get_admin_creator.php',
        ),
        body: {'email': widget.email},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hasAdminCreatorInfo = data['has_admin_info'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking admin creator info: $e');
    }
  }

  Widget _buildProfileInfo(String title, String value) {
    IconData icon;
    Color color;
    if (title == 'Jenis Kelamin') {
      icon = gender == 'L' ? Icons.male : Icons.female;
      color = gender == 'L' ? Colors.blue : Colors.pink;
    } else if (title == 'Program Studi') {
      icon = Icons.badge;
      color = Colors.teal;
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
                  value.isNotEmpty ? value : '-',
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
                            tag: 'teacher-avatar',
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
                                  _buildProfileInfo('Email', email),
                                  const Divider(),
                                  _buildProfileInfo(
                                    'Jenis Kelamin',
                                    gender == 'L' ? 'Laki-Laki' : 'Perempuan',
                                  ),
                                  const Divider(),
                                  _buildProfileInfo('Program Studi', prodi),
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
                                                    userRole: 'guru',
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
                                  if (hasAdminCreatorInfo) ...[
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
                                                  (_) => AdminCreatorInfoPage(
                                                    userEmail: widget.email,
                                                    userRole: 'guru',
                                                  ),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.indigo.withOpacity(
                                                0.3,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 16,
                                                backgroundColor: Colors.indigo
                                                    .withOpacity(0.2),
                                                child: const Icon(
                                                  Icons.admin_panel_settings,
                                                  size: 18,
                                                  color: Colors.indigo,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Admin Pembuat Akun',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.indigo,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Lihat informasi admin yang membuat akun Anda',
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
                                                color: Colors.indigo,
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
