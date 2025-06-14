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
    guruEmail = prefs.getString('guru_email');
    mataPelajaran = prefs.getString('mata_pelajaran');

    if (guruEmail != null) {
      await fetchPresensiData();
      await fetchSelectedClasses();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchPresensiData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_presensi_guru.php?guru_email=$guruEmail',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          presensiList = data['data'];
        } else {
          presensiList = [];
          _showErrorDialog('Tidak ada data presensi ditemukan.');
        }
      } else {
        _showErrorDialog('Gagal mengambil data presensi dari server.');
      }
    } catch (e) {
      debugPrint('Error fetching presensi: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted)
        setState(() {
          isLoading = false;
        });
    }
  }

  Future<void> fetchSelectedClasses() async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_selected_classes.php',
        ),
        body: {'guru_email': guruEmail!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'success') {
          selectedClasses = List<String>.from(data['kelas']);
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
          (_) => SimpleDialog(
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
    if (kelas.isEmpty || guruEmail == null || mataPelajaran == null) {
      _showErrorDialog('Data guru atau kelas tidak lengkap');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddAttendancePage(kelasList: [kelas], guruEmail: guruEmail!),
      ),
    );
    await fetchPresensiData();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _toggleDetection(
    String idPresensi,
    bool currentlyActive,
    Function(bool) onUpdated,
  ) async {
    final url =
        currentlyActive
            ? 'http://192.168.242.205/aplikasi-checkin/api/stop_detection.php'
            : 'http://192.168.242.205/aplikasi-checkin/api/start_detection.php';

    try {
      final resp = await http.post(
        Uri.parse(url),
        body: {'id_presensi_kelas': idPresensi, 'guru_email': guruEmail!},
      );
      final data = json.decode(resp.body);
      if (data['status'] == true) {
        onUpdated(!currentlyActive);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyActive ? 'Presensi dihentikan' : 'Presensi diaktifkan',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal ubah status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Koneksi gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : presensiList.isEmpty
                ? const Center(
                  child: Text(
                    'Belum ada data presensi.',
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                )
                : ListView.builder(
                  itemCount: presensiList.length,
                  itemBuilder: (context, i) {
                    var p = presensiList[i];
                    bool aktif = p['status'] == 'aktif';
                    bool selesai = p['status'] == 'selesai';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 5,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AttendanceDetailPageTeacher(
                                    kelas: p['kelas'],
                                    mataPelajaran: p['mata_pelajaran'],
                                    idPresensiKelas:
                                        int.tryParse(p['id'].toString()) ?? 0,
                                  ),
                            ),
                          );
                        },
                        title: Text(
                          'Kelas: ${p['kelas']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mata Pelajaran: ${p['mata_pelajaran']}'),
                            const SizedBox(height: 4),
                            Text(
                              'Tanggal: ${p['tanggal'] ?? 'Belum presensi'}',
                            ),
                          ],
                        ),
                        trailing: SizedBox(
                          width: 95,
                          height: 28,
                          child: ElevatedButton(
                            onPressed:
                                selesai
                                    ? null
                                    : () {
                                      _toggleDetection(
                                        p['id'].toString(),
                                        aktif,
                                        (newState) {
                                          setState(() {
                                            presensiList[i]['status'] =
                                                newState ? 'aktif' : 'selesai';
                                          });
                                        },
                                      );
                                    },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  selesai
                                      ? Colors.green
                                      : aktif
                                      ? Colors.red
                                      : Colors.lightBlueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              selesai
                                  ? 'SELESAI'
                                  : aktif
                                  ? 'HENTIKAN'
                                  : 'PRESENSI',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: selectedClasses.isEmpty ? null : showClassSelectionDialog,
        backgroundColor: selectedClasses.isEmpty ? Colors.grey : Colors.blue,
        tooltip: 'Buat Presensi Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}
