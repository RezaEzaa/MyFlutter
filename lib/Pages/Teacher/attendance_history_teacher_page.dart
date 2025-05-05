import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/Teacher/attendance_detail_page_teacher.dart';
import 'package:checkin/Pages/Teacher/add_attendance_page.dart';

class AttendanceHistoryTeacherPage extends StatefulWidget {
  const AttendanceHistoryTeacherPage({super.key});

  @override
  _AttendanceHistoryTeacherPageState createState() =>
      _AttendanceHistoryTeacherPageState();
}

class _AttendanceHistoryTeacherPageState
    extends State<AttendanceHistoryTeacherPage> {
  List<dynamic> presensiList = [];
  List<String> selectedClasses = [];
  bool isLoading = true;
  String? guruEmail;
  String? mataPelajaran;

  @override
  void initState() {
    super.initState();
    loadGuruDataAndFetchPresensi();
  }

  Future<void> loadGuruDataAndFetchPresensi() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guruEmail = prefs.getString('guru_email');
      mataPelajaran = prefs.getString('mata_pelajaran');
    });

    if (guruEmail != null) {
      await fetchPresensiData();
      await fetchSelectedClasses();
    }
  }

  Future<void> fetchPresensiData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/get_presensi_guru.php?guru_email=$guruEmail',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            presensiList = data['data'];
          });
        } else {
          presensiList = [];
        }
      }
    } catch (e) {
      debugPrint('Error fetching presensi: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchSelectedClasses() async {
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

  void showClassSelectionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text("Pilih Kelas untuk Tambah Presensi"),
            children:
                selectedClasses.map((kelas) {
                  return SimpleDialogOption(
                    child: Text(kelas),
                    onPressed: () {
                      Navigator.pop(context);
                      navigateToAddAttendance(kelas);
                    },
                  );
                }).toList(),
          ),
    );
  }

  Future<void> navigateToAddAttendance(String kelas) async {
    if (kelas.isEmpty ||
        guruEmail == null ||
        guruEmail!.isEmpty ||
        mataPelajaran == null ||
        mataPelajaran!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data guru atau kelas tidak lengkap')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddAttendancePage(
              kelas: kelas,
              guruEmail: guruEmail!,
              mataPelajaran: mataPelajaran!,
            ),
      ),
    ).then((_) => fetchPresensiData());
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AttendanceDetailPageTeacher(
                                    kelas: presensi['kelas'],
                                    mataPelajaran: presensi['mata_pelajaran'],
                                    idPresensiKelas:
                                        int.tryParse(
                                          presensi['id_presensi_kelas']
                                              .toString(),
                                        ) ??
                                        0,
                                  ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          margin: const EdgeInsets.only(bottom: 10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kelas: ${presensi['kelas']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Mata Pelajaran: ${presensi['mata_pelajaran']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Tanggal: ${presensi['tanggal'] ?? 'Belum presensi'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16.0, bottom: 12.0),
        child: FloatingActionButton(
          onPressed: selectedClasses.isEmpty ? null : showClassSelectionDialog,
          child: const Icon(Icons.add),
          tooltip: 'Buat Presensi Baru',
          shape: const CircleBorder(),
          backgroundColor: selectedClasses.isEmpty ? Colors.grey : Colors.blue,
        ),
      ),
    );
  }
}
