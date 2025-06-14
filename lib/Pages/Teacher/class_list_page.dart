import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class ClassListPage extends StatefulWidget {
  final List<String> selectedClasses;

  const ClassListPage({super.key, required this.selectedClasses});

  @override
  State<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends State<ClassListPage> {
  List<Map<String, dynamic>> allClasses = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.242.233/aplikasi-checkin/pages/guru/get_class_with_students.php',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == true || data['status'] == 'success') {
        setState(() {
          allClasses = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        setState(() {
          allClasses = [];
        });
        _showErrorDialog("Gagal memuat daftar kelas.");
      }
    } else {
      _showErrorDialog("Terjadi kesalahan koneksi ke server.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Kelas")),
      body:
          allClasses.isEmpty
              ? FutureBuilder(
                future: Future.delayed(const Duration(milliseconds: 500)),
                builder: (context, snapshot) {
                  // Tampilkan loading sebentar, lalu cek apakah data sudah di-fetch
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(
                    child: Text(
                      "Belum ada kelas yang tersedia.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              )
              : ListView.builder(
                shrinkWrap: true,
                itemCount: allClasses.length,
                itemBuilder: (context, index) {
                  final classItem = allClasses[index];
                  final isSelected = widget.selectedClasses.contains(
                    classItem['kelas'],
                  );

                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        Navigator.pop(context, classItem['kelas']);
                      } else {
                        _showSuccessToast("Kelas sudah ditambahkan");
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: ListTile(
                        title: Text("Kelas ${classItem['kelas']}"),
                        subtitle: Text("Jumlah Siswa: ${classItem['jumlah']}"),
                        trailing: Icon(
                          isSelected ? Icons.check_circle : Icons.add_circle,
                          color: isSelected ? Colors.green : Colors.blue,
                        ),
                        // onTap dihapus dari ListTile
                      ),
                    ),
                  );
                },
              ),
    );
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
}
