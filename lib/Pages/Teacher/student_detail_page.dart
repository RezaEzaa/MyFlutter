import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:checkin/Pages/Teacher/student_list_by_class_page.dart';
import 'package:checkin/Pages/Teacher/class_list_page.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  List<String> selectedClasses = [];
  String? guruEmail;

  @override
  void initState() {
    super.initState();
    loadGuruEmailAndData();
  }

  Future<void> loadGuruEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guruEmail = prefs.getString('guru_email');
    });

    if (guruEmail != null && guruEmail!.isNotEmpty) {
      await getSelectedClassesFromServer();
    }
  }

  Future<void> getSelectedClassesFromServer() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/get_selected_classes.php',
        ),
        body: {'guru_email': guruEmail!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          setState(() {
            selectedClasses = List<String>.from(data['kelas']);
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil kelas: $e');
    }
  }

  void addClass(String kelas) {
    if (!selectedClasses.contains(kelas)) {
      setState(() {
        selectedClasses.add(kelas);
      });
      saveSelectedClassToServer(kelas);
    }
  }

  Future<void> saveSelectedClassToServer(String kelas) async {
    if (guruEmail == null || guruEmail!.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/add_selected_class.php',
        ),
        body: {'guru_email': guruEmail!, 'kelas': kelas},
      );

      final data = json.decode(response.body);
      if (data['status'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal menyimpan kelas')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan koneksi ke server")),
      );
    }
  }

  Future<void> deleteSelectedClass(String kelas) async {
    if (guruEmail == null || guruEmail!.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/delete_selected_class.php',
        ),
        body: {'guru_email': guruEmail!, 'kelas': kelas},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          setState(() {
            selectedClasses.remove(kelas);
          });
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal menghapus kelas")));
    }
    Navigator.pop(context, 'refresh');
  }

  void openClassListPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ClassListPage(
              selectedClasses: List<String>.from(selectedClasses),
            ),
      ),
    );

    if (result != null) {
      if (result == 'refresh') {
        await getSelectedClassesFromServer();
      } else if (result is String) {
        addClass(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          selectedClasses.isEmpty
              ? const Center(child: Text("Belum ada kelas yang ditambahkan"))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Daftar Kelas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: selectedClasses.length,
                        itemBuilder: (context, index) {
                          final kelas = selectedClasses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 5,
                            ),
                            child: ListTile(
                              title: Text(
                                "Kelas:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text("$kelas"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => deleteSelectedClass(kelas),
                                  ),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => StudentListByClassPage(
                                          kelas: kelas,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
        child: FloatingActionButton(
          onPressed: openClassListPage,
          child: const Icon(Icons.add),
          tooltip: 'Tambah Kelas',
          shape: const CircleBorder(),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
}
