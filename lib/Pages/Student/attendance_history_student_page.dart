import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/Student/attendance_detail_student_page.dart';

class AttendanceHistoryStudentPage extends StatefulWidget {
  const AttendanceHistoryStudentPage({super.key});

  @override
  State<AttendanceHistoryStudentPage> createState() =>
      _AttendanceHistoryStudentPageState();
}

class _AttendanceHistoryStudentPageState
    extends State<AttendanceHistoryStudentPage> {
  List<dynamic> presensiList = [];
  bool isLoading = true;
  String? siswaEmail;

  @override
  void initState() {
    super.initState();
    loadSiswaDataAndFetchPresensi();
  }

  Future<void> loadSiswaDataAndFetchPresensi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      siswaEmail = prefs.getString('siswa_email');
    });

    debugPrint('Email siswa yang dikirim: $siswaEmail');

    if (siswaEmail != null) {
      await fetchPresensiData();
    } else {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Email siswa tidak ditemukan. Silakan login ulang.');
    }
  }

  Future<void> fetchPresensiData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/siswa/get_presensi_siswa.php?siswa_email=$siswaEmail',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          setState(() {
            presensiList = data['data'];
          });
        } else {
          setState(() {
            presensiList = [];
          });
          _showErrorDialog('Tidak ada data presensi ditemukan.');
        }
      } else {
        _showErrorDialog('Gagal mengambil data presensi dari server.');
      }
    } catch (e) {
      debugPrint('Error fetching presensi: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Center(
                child: Text(
                  'Riwayat Presensi',
                  style: TextStyle(
                    fontFamily: 'TitilliumWeb',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : presensiList.isEmpty
                  ? const Center(
                    child: Text(
                      'Belum ada data presensi.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: presensiList.length,
                    itemBuilder: (context, index) {
                      final presensi = presensiList[index];
                      final mataPelajaran = presensi['mata_pelajaran'] ?? '';
                      final namaGuru = presensi['nama_lengkap_guru'] ?? '';
                      final tanggal = presensi['tanggal_presensi'];
                      final status = presensi['status'] ?? '';
                      final tanggalTampil =
                          status == 'belum'
                              ? 'Belum presensi'
                              : (tanggal ?? '');

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AttendanceDetailStudentPage(
                                    presensi: presensi,
                                  ),
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
                              'Mata Pelajaran: $mataPelajaran',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Guru: $namaGuru'),
                                const SizedBox(height: 4),
                                Text('Tanggal: $tanggalTampil'),
                              ],
                            ),
                            trailing: Icon(
                              status == 'hadir'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  status == 'hadir' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
