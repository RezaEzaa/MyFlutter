import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkin/Pages/settings_page.dart';

class StudentListByClassPage extends StatefulWidget {
  final String kelas;

  const StudentListByClassPage({super.key, required this.kelas});

  @override
  State<StudentListByClassPage> createState() => _StudentListByClassPageState();
}

class _StudentListByClassPageState extends State<StudentListByClassPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  String? guruEmail;

  @override
  void initState() {
    super.initState();
    loadGuruEmailAndFetchStudents();
  }

  Future<void> loadGuruEmailAndFetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guruEmail = prefs.getString('guru_email');
    });
    if (guruEmail != null) {
      await fetchStudentsByClass(widget.kelas);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guru email tidak ditemukan")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchStudentsByClass(String kelas) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/get_students_by_class.php?kelas=${Uri.encodeComponent(kelas)}&guru_email=${Uri.encodeComponent(guruEmail!)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students =
              data['status']
                  ? List<Map<String, dynamic>>.from(data['data'])
                  : [];
          isLoading = false;
        });
      } else {
        setState(() {
          students = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        students = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal memuat data siswa")));
    }
  }

  Future<void> hideStudent(int id) async {
    final response = await http.post(
      Uri.parse(
        'http://192.168.218.89/aplikasi-checkin/hide_student_for_teacher.php',
      ),
      body: {'guru_email': guruEmail!, 'siswa_id': id.toString()},
    );

    final data = json.decode(response.body);
    if (data['status']) {
      setState(() {
        students.removeWhere((student) => student["id"] == id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Siswa disembunyikan")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Gagal menyembunyikan siswa'),
        ),
      );
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
              SizedBox(height: 25, child: Container()),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
              ? const Center(child: Text("Belum ada siswa di kelas ini"))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: ListTile(
                        title: Text(
                          'Daftar Siswa Kelas',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        subtitle: Text(
                          '${widget.kelas}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final jenisKelaminIcon =
                              student['jenis_kelamin'] == 'L'
                                  ? Icons.male
                                  : Icons.female;
                          final jenisKelaminColor =
                              student['jenis_kelamin'] == 'L'
                                  ? Colors.blue
                                  : Colors.pink;
                          final fotoUrl =
                              student['foto'] != null &&
                                      student['foto'].isNotEmpty
                                  ? student['foto']
                                  : 'http://192.168.218.89/aplikasi-checkin/uploads/siswa/default.png';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 5.0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(fotoUrl),
                              ),
                              title: Text(
                                student['nama_lengkap'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 19,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      jenisKelaminIcon,
                                      color: jenisKelaminColor,
                                    ),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility_off,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => hideStudent(student['id']),
                                  ),
                                ],
                              ),
                              onTap: () {},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
