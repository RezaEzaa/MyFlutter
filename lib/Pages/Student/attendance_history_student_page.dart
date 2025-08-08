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
  bool isRefreshing = false;
  String? siswaEmail;
  Set<String> expandedKelas = {};
  Set<String> expandedSemester = {};
  Set<String> expandedMapel = {};
  @override
  void initState() {
    super.initState();
    loadSiswaDataAndFetchPresensi();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations here if needed
    super.dispose();
  }

  Future<void> loadSiswaDataAndFetchPresensi() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      siswaEmail = prefs.getString('siswa_email');
    });
    if (siswaEmail != null) {
      await fetchPresensiData();
    } else {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Email siswa tidak ditemukan. Silakan login ulang.');
    }
  }

  Future<void> fetchPresensiData() async {
    if (isRefreshing) return;
    if (!mounted) return;

    setState(() {
      isRefreshing = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/siswa/get_presensi_siswa.php?siswa_email=$siswaEmail',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          if (!mounted) return;
          setState(() {
            presensiList = data['data'];
          });
        } else {
          if (!mounted) return;
          setState(() {
            presensiList = [];
          });
          _showErrorDialog(
            data['message'] ?? 'Tidak ada data presensi ditemukan.',
          );
        }
      } else {
        _showErrorDialog('Gagal mengambil data presensi dari server.');
      }
    } catch (e) {
      debugPrint('Error fetching presensi: $e');
      if (mounted) {
        _showErrorDialog('Terjadi kesalahan: $e');
      }
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

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
      body: Column(
        children: [
          const Icon(Icons.history_edu_rounded, color: Colors.blue, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Riwayat Presensi',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'TitilliumWeb',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: fetchPresensiData,
                      child:
                          presensiList.isEmpty
                              ? ListView.builder(
                                itemCount: 1,
                                itemBuilder: (context, index) {
                                  return Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.6,
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_late_outlined,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Belum ada data presensi.",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Tarik ke bawah untuk menyegarkan data",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )
                              : Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: ListView(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  children: _buildKelasCards(),
                                ),
                              ),
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildKelasCards() {
    final groupedByKelas = <String, List<Map<String, dynamic>>>{};
    for (final item in presensiList.cast<Map<String, dynamic>>()) {
      final kelas = item['kelas']?.toString() ?? 'Unknown';
      groupedByKelas.putIfAbsent(kelas, () => []).add(item);
    }
    List<String> sortedKelasKeys = groupedByKelas.keys.toList()..sort();
    List<Widget> widgets = [];
    for (final kelas in sortedKelasKeys) {
      final isExpanded = expandedKelas.contains(kelas);
      final items = groupedByKelas[kelas]!;
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    if (isExpanded) {
                      expandedKelas.remove(kelas);
                    } else {
                      expandedKelas.add(kelas);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  leading: const Icon(Icons.class_, color: Colors.teal),
                  title: Text(
                    'Kelas: $kelas',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(children: _buildSemesterCards(items, kelas)),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildSemesterCards(
    List<Map<String, dynamic>> kelasItems,
    String kelas,
  ) {
    final groupedBySemester = <String, List<Map<String, dynamic>>>{};
    for (final item in kelasItems) {
      final semester = item['semester']?.toString() ?? 'Unknown';
      groupedBySemester.putIfAbsent(semester, () => []).add(item);
    }
    List<Widget> widgets = [];
    for (final semester in groupedBySemester.keys) {
      final key = 'semester_${kelas}_$semester';
      final isExpanded = expandedSemester.contains(key);
      final items = groupedBySemester[semester]!;
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    if (isExpanded) {
                      expandedSemester.remove(key);
                    } else {
                      expandedSemester.add(key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    getSemesterIcon(semester),
                    color: const Color.fromARGB(255, 157, 0, 118),
                  ),
                  title: Text(
                    'Semester: $semester',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(
                    children: _buildMapelCards(items, kelas, semester),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildMapelCards(
    List<Map<String, dynamic>> semesterItems,
    String kelas,
    String semester,
  ) {
    final groupedByMapel = <String, List<Map<String, dynamic>>>{};
    for (final item in semesterItems) {
      final mapel = item['mata_pelajaran'] ?? 'Unknown';
      groupedByMapel.putIfAbsent(mapel, () => []).add(item);
    }
    List<Widget> widgets = [];
    for (final mapel in groupedByMapel.keys) {
      final key = 'mapel_${kelas}_${semester}_$mapel';
      final isExpanded = expandedMapel.contains(key);
      final items = groupedByMapel[mapel]!;
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if (!mounted) return;
                  setState(() {
                    if (isExpanded) {
                      expandedMapel.remove(key);
                    } else {
                      expandedMapel.add(key);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(
                    Icons.menu_book,
                    color: Color.fromARGB(255, 115, 89, 151),
                  ),
                  title: Text(
                    mapel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Guru: ${items.isNotEmpty ? items.first['nama_lengkap_guru'] ?? 'Unknown' : 'Unknown'}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Column(children: _buildPertemuanCards(items)),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildPertemuanCards(List<Map<String, dynamic>> mapelItems) {
    mapelItems.sort((a, b) {
      final pertemuanA = int.tryParse(a['pertemuan'].toString()) ?? 0;
      final pertemuanB = int.tryParse(b['pertemuan'].toString()) ?? 0;
      return pertemuanA.compareTo(pertemuanB);
    });
    List<Widget> widgets = [];
    for (final item in mapelItems) {
      final pertemuanKe = int.tryParse(item['pertemuan'].toString()) ?? 0;
      final tanggal = item['tanggal'] ?? '';
      final jam = item['jam'] ?? '';
      final status = item['status'] ?? '';
      final times = jam.split('-');
      final jamMulai = times.isNotEmpty ? times[0].trim() : '';
      final jamSelesai = times.length > 1 ? times[1].trim() : '';
      IconData statusIcon;
      Color statusColor;
      if (status == 'selesai') {
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
      } else if (status == 'aktif') {
        statusIcon = Icons.play_circle_fill;
        statusColor = Colors.blue;
      } else {
        statusIcon = Icons.schedule;
        statusColor = Colors.grey;
      }
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceDetailStudentPage(presensi: item),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withOpacity(0.2),
                    foregroundColor: statusColor,
                    child: Text(
                      pertemuanKe.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                '$jamMulai - $jamSelesai',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggal,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    'Status: $status',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          status == 'aktif'
                              ? Colors.green
                              : status == 'selesai'
                              ? Colors.blue
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  IconData getSemesterIcon(String semester) {
    int? semesterNum = int.tryParse(semester);
    if (semesterNum != null) {
      return semesterNum % 2 == 1 ? Icons.filter_1 : Icons.filter_2;
    } else {
      if (semester.toLowerCase().contains('ganjil')) {
        return Icons.filter_1;
      } else if (semester.toLowerCase().contains('genap')) {
        return Icons.filter_2;
      } else {
        return Icons.timelapse;
      }
    }
  }
}
