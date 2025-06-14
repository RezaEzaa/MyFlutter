import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/Teacher/student_list_by_class_page.dart';
import 'package:checkin/Pages/Teacher/class_list_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  List<String> selectedClasses = [];
  String? guruEmail;
  bool isLoading = false; // ✅ Tambahkan variabel isLoading

  @override
  void initState() {
    super.initState();
    loadGuruEmailAndData();
  }

  Future<void> loadGuruEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    guruEmail = prefs.getString('guru_email');
    if (guruEmail != null && guruEmail!.isNotEmpty) {
      await getSelectedClassesFromServer();
    }
  }

  Future<void> getSelectedClassesFromServer() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_selected_classes.php',
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addClass(String kelas) {
    if (!selectedClasses.contains(kelas)) {
      setState(() => selectedClasses.add(kelas));
      saveSelectedClassToServer(kelas);
    }
  }

  Future<void> saveSelectedClassToServer(String kelas) async {
    if (guruEmail == null || guruEmail!.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/add_selected_class.php',
        ),
        body: {'guru_email': guruEmail!, 'kelas': kelas},
      );

      final data = json.decode(response.body);
      if (data['status'] != true) {
        _showErrorDialog(data['message'] ?? 'Gagal menyimpan kelas');
      } else {
        _showSuccessToast('Kelas berhasil ditambahkan');
      }
    } catch (_) {
      _showErrorDialog("Terjadi kesalahan koneksi ke server");
    }
  }

  Future<void> deleteSelectedClass(String kelas) async {
    if (guruEmail == null || guruEmail!.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Konfirmasi'),
            content: Text('Hapus kelas "$kelas"?'),
            actions: [
              TextButton(
                child: const Text('Batal'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Hapus'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/delete_selected_class.php',
        ),
        body: {'guru_email': guruEmail!, 'kelas': kelas},
      );

      final data = json.decode(response.body);
      if (data['status']) {
        setState(() {
          selectedClasses.remove(kelas);
        });
        _showSuccessToast(data['message']);
      } else {
        _showErrorDialog(data['message']);
      }
    } catch (_) {
      _showErrorDialog("Gagal menghapus kelas");
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Center(
                child: Text(
                  'Daftar Kelas',
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedClasses.isEmpty
                  ? const Center(
                    child: Text(
                      'Belum ada daftar kelas yang terpilih.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedClasses.length,
                    itemBuilder: (context, index) {
                      final kelas = selectedClasses[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => StudentListByClassPage(kelas: kelas),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 5,
                          ),
                          child: ListTile(
                            title: Text(
                              kelas,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
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
                            // onTap dihapus dari ListTile
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openClassListPage,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Kelas',
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
      ),
    );
  }
}
