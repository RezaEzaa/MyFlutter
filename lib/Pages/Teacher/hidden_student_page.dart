import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HiddenStudentPage extends StatefulWidget {
  const HiddenStudentPage({super.key});

  @override
  State<HiddenStudentPage> createState() => _HiddenStudentPageState();
}

class _HiddenStudentPageState extends State<HiddenStudentPage> {
  List<Map<String, dynamic>> hiddenStudents = [];
  String? guruEmail;

  @override
  void initState() {
    super.initState();
    loadGuruEmailAndData();
  }

  Future<void> loadGuruEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    guruEmail = prefs.getString('guru_email');
    if (guruEmail != null && guruEmail!.isNotEmpty) {
      await getHiddenStudentsFromServer();
    }
  }

  Future<void> getHiddenStudentsFromServer() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_hidden_students.php',
        ),
        body: {'guru_email': guruEmail!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          setState(() {
            hiddenStudents = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil siswa yang disembunyikan: $e');
    }
  }

  Future<void> restoreStudent(String siswaId) async {
    if (guruEmail == null || guruEmail!.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/restore_hidden_student.php',
        ),
        body: {'guru_email': guruEmail!, 'siswa_id': siswaId},
      );

      final data = json.decode(response.body);
      if (data['status']) {
        // Hapus siswa dari list
        setState(() {
          hiddenStudents.removeWhere((student) => student['id'] == siswaId);
        });

        // Tampilkan notifikasi sukses
        _showSuccessToast(data['message']);

        // Kembalikan ke halaman sebelumnya dengan status sukses
        Navigator.pop(context, true);
      } else {
        _showErrorDialog(data['message']);
      }
    } catch (e) {
      _showErrorDialog("Gagal mengembalikan siswa");
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
      appBar: AppBar(title: const Text('Siswa yang Disembunyikan')),
      body:
          hiddenStudents.isEmpty
              ? const Center(child: Text("Tidak ada siswa yang disembunyikan"))
              : ListView.builder(
                itemCount: hiddenStudents.length,
                itemBuilder: (context, index) {
                  final student = hiddenStudents[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(student['foto']),
                      ),
                      title: Text(student['nama_lengkap']),
                      subtitle: Text(student['kelas']),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          color: Colors.green,
                          size: 30,
                        ),
                        onPressed: () {
                          restoreStudent(student['id'].toString());
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
