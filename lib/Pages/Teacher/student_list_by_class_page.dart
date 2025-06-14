import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/Teacher/hidden_student_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
    guruEmail = prefs.getString('guru_email');

    if (guruEmail != null) {
      await fetchStudentsByClass(widget.kelas);
    } else {
      _showErrorDialog("Guru email tidak ditemukan");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchStudentsByClass(String kelas) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_students_by_class.php?kelas=${Uri.encodeComponent(widget.kelas)}&guru_email=${Uri.encodeComponent(guruEmail!)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          students =
              (data['status'] == true || data['status'] == 'success')
                  ? List<Map<String, dynamic>>.from(data['data'])
                  : [];
        });
        _showSuccessToast("Data siswa berhasil dimuat.");
      } else {
        setState(() {
          students = [];
        });
        _showErrorDialog("Gagal memuat data siswa");
      }
    } catch (e) {
      _showErrorDialog("Gagal memuat data siswa");
      setState(() {
        students = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> hideStudent(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: const Text("Sembunyikan siswa ini dari daftar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final response = await http.post(
      Uri.parse(
        'http://192.168.242.233/aplikasi-checkin/pages/guru/hide_student_for_teacher.php',
      ),
      body: {'guru_email': guruEmail!, 'siswa_id': id.toString()},
    );

    final data = json.decode(response.body);
    if (data['status'] == true || data['status'] == 'success') {
      setState(() {
        students.removeWhere((student) => student["id"] == id);
      });
      _showSuccessToast("Siswa disembunyikan");
    } else {
      _showErrorDialog(data['message'] ?? 'Gagal menyembunyikan siswa');
    }
  }

  Future<void> navigateToHiddenStudents() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HiddenStudentPage()),
    );

    if (result == true) {
      await fetchStudentsByClass(widget.kelas); // refresh setelah kembali
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
          IconButton(
            icon: const Icon(Icons.visibility_off),
            onPressed: navigateToHiddenStudents,
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
                        title: const Text(
                          'Daftar Siswa Kelas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        subtitle: Text(
                          widget.kelas,
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
                              (student['foto'] != null &&
                                      student['foto'].isNotEmpty)
                                  ? student['foto']
                                  : 'http://192.168.242.233/aplikasi-checkin/uploads/siswa/default.png';

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
                                style: const TextStyle(
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
