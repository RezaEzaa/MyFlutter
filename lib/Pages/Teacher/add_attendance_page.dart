import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class AddAttendancePage extends StatefulWidget {
  final List<String> kelasList;
  final String guruEmail;

  const AddAttendancePage({
    required this.kelasList,
    required this.guruEmail,
    Key? key,
  }) : super(key: key);

  @override
  State<AddAttendancePage> createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  bool isLoading = false;
  List<String> mataPelajaranList = [];
  String? selectedMataPelajaran;

  @override
  void initState() {
    super.initState();
    fetchMataPelajaran();
  }

  Future<void> fetchMataPelajaran() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_profile_guru.php',
        ),
        body: {'email': widget.guruEmail},
      );
      print('Response body: ${response.body}');
      final data = json.decode(response.body);
      if ((data['status'] == true || data['status'] == 'success') &&
          data['data'] != null) {
        // Pecah string mata pelajaran menjadi list
        final mpString = data['data']['mata_pelajaran'] ?? '';
        setState(() {
          mataPelajaranList =
              mpString
                  .split(',')
                  .map((e) => e.toString().trim())
                  .where((e) => e is String && e.isNotEmpty)
                  .toList()
                  .cast<String>();
          if (mataPelajaranList.isNotEmpty) {
            selectedMataPelajaran = mataPelajaranList.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil mata pelajaran: $e');
    }
  }

  Future<void> addAttendance() async {
    if (selectedMataPelajaran == null || selectedMataPelajaran!.isEmpty) {
      _showErrorDialog('Pilih mata pelajaran terlebih dahulu');
      return;
    }
    setState(() {
      isLoading = true;
    });

    bool allSuccess = true;
    for (String kelas in widget.kelasList) {
      try {
        final response = await http.post(
          Uri.parse(
            'http://192.168.242.233/aplikasi-checkin/pages/guru/add_presensi_kelas.php',
          ),
          body: {
            'guru_email': widget.guruEmail,
            'kelas': kelas,
            'mata_pelajaran': selectedMataPelajaran!,
          },
        );
        final data = json.decode(response.body);
        if (data['status'] != true && data['status'] != 'success') {
          allSuccess = false;
          _showErrorDialog(
            data['message'] ?? 'Gagal menambahkan presensi untuk kelas $kelas!',
          );
        }
      } catch (e) {
        allSuccess = false;
        _showErrorDialog('Terjadi kesalahan jaringan pada kelas $kelas!');
      }
    }

    setState(() {
      isLoading = false;
    });

    if (allSuccess) {
      _showSuccessToast('Presensi berhasil ditambahkan');
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Tambah Presensi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            mataPelajaranList.isEmpty
                ? isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(child: Text('Gagal memuat mata pelajaran.'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kelas:', style: TextStyle(fontSize: 18)),
                    ...widget.kelasList.map(
                      (kelas) => ListTile(title: Text(kelas)),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedMataPelajaran,
                      items:
                          mataPelajaranList
                              .map(
                                (mp) => DropdownMenuItem(
                                  value: mp,
                                  child: Text(mp),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedMataPelajaran = val;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Pilih Mata Pelajaran',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: addAttendance,
                          child: const Text('Tambahkan Presensi'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                  ],
                ),
      ),
    );
  }
}
