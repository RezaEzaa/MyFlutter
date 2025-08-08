import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:checkin/Pages/Teacher/attendance_detail_page_teacher.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> showActiveNotification(String kelas) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'presensi_channel',
          'Presensi Aktif',
          channelDescription: 'Notifikasi untuk presensi aktif',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Presensi Aktif',
      'Presensi untuk kelas $kelas telah diaktifkan.',
      platformDetails,
    );
  }

  Future<void> showCompletedNotification(String kelas) async {
    await _flutterLocalNotificationsPlugin.cancel(0);
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'presensi_channel',
          'Presensi Selesai',
          channelDescription: 'Notifikasi untuk presensi selesai',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Presensi Selesai',
      'Presensi untuk kelas $kelas telah selesai.',
      platformDetails,
    );
  }
}

class AttendanceHistoryTeacherPage extends StatefulWidget {
  const AttendanceHistoryTeacherPage({super.key});
  @override
  State<AttendanceHistoryTeacherPage> createState() =>
      _AttendanceHistoryTeacherPageState();
}

class _AttendanceHistoryTeacherPageState
    extends State<AttendanceHistoryTeacherPage> {
  String? guruEmail;
  bool isLoading = true;
  NotificationService notificationService = NotificationService();
  List<Map<String, dynamic>> pelajaranData = [];
  bool isUpdating = false;
  @override
  void initState() {
    super.initState();
    notificationService.init();
    loadGuruEmailAndFetchData();
  }

  Future<void> loadGuruEmailAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    guruEmail = prefs.getString('guru_email');
    if (guruEmail != null) {
      await fetchMataPelajaran();
    } else {
      _showErrorDialog("Email guru tidak ditemukan.");
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchMataPelajaran() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/get_presensi_guru.php?guru_email=$guruEmail',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            pelajaranData = List<Map<String, dynamic>>.from(data['data']);
          });
        } else {
          _showErrorDialog("Data mata pelajaran kosong atau gagal dimuat.");
        }
      } else {
        _showErrorDialog("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorDialog("Kesalahan koneksi: $e");
    }
  }

  Future<bool> updatePresensiStatus(
    int idPresensiKelas,
    String newStatus,
    int pertemuan,
    String tanggal,
    String jam,
  ) async {
    try {
      debugPrint('📤 Mengirim request update status presensi:');
      debugPrint('  - id_presensi_kelas: $idPresensiKelas');
      debugPrint('  - status: $newStatus');
      debugPrint('  - guru_email: $guruEmail');
      debugPrint('  - pertemuan: $pertemuan');
      debugPrint('  - tanggal: $tanggal');
      debugPrint('  - jam: $jam');
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/api/update_sistem_presensi.php',
        ),
        body: {
          'id_presensi_kelas': idPresensiKelas.toString(),
          'status': newStatus,
          'guru_email': guruEmail ?? '',
          'pertemuan': pertemuan.toString(),
          'tanggal': tanggal,
          'jam': jam,
        },
      );
      debugPrint('📥 Response status: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');
      final data = json.decode(response.body);
      if (data['log'] != null && data['log'] is List) {
        debugPrint('📄 Log dari backend:');
        for (int i = 0; i < data['log'].length; i++) {
          debugPrint('  ${i + 1}. ${data['log'][i]}');
        }
      }
      if (data['status'] == true) {
        if (data['data'] != null) {
          debugPrint('✅ Data hasil update: ${data['data']}');
        }
        return true;
      } else {
        debugPrint('❌ Error dari backend: ${data['message']}');
        _showToast(data['message'] ?? 'Gagal mengubah status presensi.');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Exception saat update status: $e');
      _showToast("Gagal koneksi saat mengubah status presensi: $e");
      return false;
    }
  }

  void _showToast(String message) {
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
      builder:
          (_) => AlertDialog(
            title: const Text('Kesalahan'),
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

  Set<String> expandedMapel = {};
  Set<String> expandedSemester = {};
  Set<String> expandedProdi = {};
  Set<String> expandedKelas = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.history_edu_rounded, color: Colors.blue, size: 40),
          const SizedBox(height: 10),
          const Text(
            'Riwayat Presensi',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: fetchMataPelajaran,
                      child:
                          pelajaranData.isEmpty
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
                                          "Tidak ada data mata pelajaran.",
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
                              : ListView(
                                padding: const EdgeInsets.only(top: 8.0),
                                children: _buildProdiCards(),
                              ),
                    ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProdiCards() {
    final groupedByProdi = <String, List<Map<String, dynamic>>>{};
    for (final item in pelajaranData) {
      final prodi = item['prodi'] ?? 'Umum';
      groupedByProdi.putIfAbsent(prodi, () => []).add(item);
    }
    List<String> sortedProdiKeys = groupedByProdi.keys.toList()..sort();
    List<Widget> widgets = [];
    for (final prodi in sortedProdiKeys) {
      final isExpanded = expandedProdi.contains(prodi);
      final items = groupedByProdi[prodi]!;
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              InkWell(
                onTap:
                    () => setState(() {
                      if (isExpanded) {
                        expandedProdi.remove(prodi);
                      } else {
                        expandedProdi.add(prodi);
                      }
                    }),
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  leading: const Icon(Icons.school, color: Colors.cyan),
                  title: Text(
                    '$prodi',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.lightGreenAccent,
                        ),
                        tooltip: 'Edit Prodi',
                        onPressed: () {
                          final firstItem = items.first;
                          _showEditProdiDialog(
                            prodiLama: prodi,
                            kelas: firstItem['kelas'],
                            mataPelajaran: firstItem['mata_pelajaran'],
                          );
                        },
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: Column(children: _buildKelasCards(items, prodi)),
                ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildKelasCards(
    List<Map<String, dynamic>> prodiItems,
    String prodi,
  ) {
    final groupedByKelas = <String, List<Map<String, dynamic>>>{};
    for (final item in prodiItems) {
      final kelas = item['kelas']?.toString() ?? 'Unknown';
      groupedByKelas.putIfAbsent(kelas, () => []).add(item);
    }
    List<Widget> widgets = [];
    for (final kelas in groupedByKelas.keys) {
      final key = 'kelas_${prodi}_$kelas';
      final isExpanded = expandedKelas.contains(key);
      final items = groupedByKelas[kelas]!;
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              InkWell(
                onTap:
                    () => setState(() {
                      if (isExpanded) {
                        expandedKelas.remove(key);
                      } else {
                        expandedKelas.add(key);
                      }
                    }),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.class_, color: Colors.teal),
                  title: Text(
                    'Kelas: $kelas',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.lightGreenAccent,
                        ),
                        tooltip: 'Edit Kelas',
                        onPressed: () {
                          final firstItem = items.first;
                          _showEditKelasDialog(
                            kelasLama: kelas,
                            prodi: prodi,
                            mataPelajaran: firstItem['mata_pelajaran'],
                          );
                        },
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: Column(
                    children: _buildSemesterCards(items, prodi, kelas),
                  ),
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
    String prodi,
    String kelas,
  ) {
    final groupedBySemester = <String, List<Map<String, dynamic>>>{};
    for (final item in kelasItems) {
      final semester = item['semester']?.toString() ?? 'Unknown';
      groupedBySemester.putIfAbsent(semester, () => []).add(item);
    }
    List<Widget> widgets = [];
    for (final semester in groupedBySemester.keys) {
      final key = 'semester_${prodi}_${kelas}_$semester';
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
                onTap:
                    () => setState(() {
                      if (isExpanded) {
                        expandedSemester.remove(key);
                      } else {
                        expandedSemester.add(key);
                      }
                    }),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    getSemesterIcon(semester),
                    color: Color.fromARGB(255, 157, 0, 118),
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
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: Column(
                    children: _buildMapelCards(items, prodi, kelas, semester),
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
    String prodi,
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
      final key = 'mapel_${prodi}_${kelas}_${semester}_$mapel';
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
                onTap:
                    () => setState(() {
                      if (isExpanded) {
                        expandedMapel.remove(key);
                      } else {
                        expandedMapel.add(key);
                      }
                    }),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(
                    Icons.menu_book,
                    color: Color.fromARGB(255, 115, 89, 151),
                  ),
                  title: Text(
                    mapel,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          color: Colors.lightGreenAccent,
                        ),
                        tooltip: 'Edit Mata Pelajaran',
                        onPressed: () {
                          final firstItem = items.first;
                          _showEditMapelDialog(
                            mapelLama: mapel,
                            kelas: firstItem['kelas'],
                            prodi: firstItem['prodi'],
                          );
                        },
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
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
      final times = jam.split('-');
      final startTime = times.isNotEmpty ? times[0].trim() : '';
      final endTime = times.length > 1 ? times[1].trim() : '';
      final now = DateTime.now();
      final today = now.toIso8601String().split('T')[0];
      final isToday = tanggal == today;
      final currentTime = TimeOfDay.now();
      final start = _parseTimeOfDay(startTime);
      final end = _parseTimeOfDay(endTime);
      final inRange = isToday && _isInTimeRange(currentTime, start, end);
      final currentStatus = item['status'] ?? 'belum';
      IconData buttonIcon;
      Color buttonColor;
      String buttonTooltip;
      bool isButtonEnabled;
      if (currentStatus == 'selesai') {
        buttonIcon = Icons.check_circle;
        buttonColor = Colors.green;
        buttonTooltip = 'Presensi Selesai';
        isButtonEnabled = false;
      } else if (currentStatus == 'aktif') {
        buttonIcon = Icons.stop;
        buttonColor = Colors.red;
        buttonTooltip = 'Stop Presensi';
        isButtonEnabled = true;
      } else {
        if (inRange) {
          buttonIcon = Icons.play_arrow;
          buttonColor = Colors.green;
          buttonTooltip = 'Mulai Presensi';
          isButtonEnabled = true;
        } else {
          buttonIcon = Icons.play_arrow;
          buttonColor = Colors.grey;
          buttonTooltip = 'Belum Waktunya';
          isButtonEnabled = false;
        }
      }
      widgets.add(
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
          child: InkWell(
            onTap: () {
              final idPresensiKelas = int.tryParse(item['id'].toString()) ?? 0;
              final kelas = item['kelas'];
              final mataPelajaran = item['mata_pelajaran'];
              final semester = item['semester']?.toString() ?? '';
              final prodi = item['prodi']?.toString() ?? '';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AttendanceDetailPageTeacher(
                        idPresensiKelas: idPresensiKelas,
                        kelas: kelas,
                        mataPelajaran: mataPelajaran,
                        pertemuanKe: pertemuanKe,
                        tanggal: tanggal,
                        jam: jam,
                        semester: semester,
                        prodi: prodi,
                      ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue[50],
                child: Text(
                  '$pertemuanKe',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              title: Text(
                '$startTime - $endTime',
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
                    'Status: $currentStatus',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          currentStatus == 'aktif'
                              ? Colors.green
                              : currentStatus == 'selesai'
                              ? Colors.blue
                              : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(buttonIcon, color: buttonColor),
                    tooltip: buttonTooltip,
                    onPressed:
                        isButtonEnabled
                            ? () async {
                              final idPresensiKelas =
                                  int.tryParse(item['id'].toString()) ?? 0;
                              final kelas = item['kelas'];
                              String newStatus;
                              String successMessage;
                              if (currentStatus == 'belum') {
                                newStatus = 'aktif';
                                successMessage =
                                    'Presensi dimulai untuk pertemuan $pertemuanKe';
                              } else {
                                newStatus = 'selesai';
                                successMessage =
                                    'Presensi dihentikan untuk pertemuan $pertemuanKe';
                              }
                              setState(() => isUpdating = true);
                              final berhasil = await updatePresensiStatus(
                                idPresensiKelas,
                                newStatus,
                                pertemuanKe,
                                tanggal,
                                jam,
                              );
                              if (berhasil) {
                                if (newStatus == 'aktif') {
                                  notificationService.showActiveNotification(
                                    kelas,
                                  );
                                } else if (newStatus == 'selesai') {
                                  notificationService.showCompletedNotification(
                                    kelas,
                                  );
                                }
                                _showToast(successMessage);
                                await fetchMataPelajaran();
                              }
                              setState(() => isUpdating = false);
                            }
                            : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar, color: Colors.orange),
                    tooltip: 'Edit Jadwal Pertemuan',
                    onPressed: () {
                      _showEditPertemuanDialog(item);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  void _showEditPertemuanDialog(Map<String, dynamic> item) {
    final tanggal = item['tanggal'] ?? '';
    final jam = item['jam'] ?? '';
    final pertemuan = item['pertemuan']?.toString() ?? '';
    final times = jam.split('-');
    final jamMulai = times.isNotEmpty ? times[0].trim() : '';
    final jamSelesai = times.length > 1 ? times[1].trim() : '';
    final tanggalController = TextEditingController(text: tanggal);
    final jamMulaiController = TextEditingController(text: jamMulai);
    final jamSelesaiController = TextEditingController(text: jamSelesai);
    final pertemuanController = TextEditingController(text: pertemuan);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 16,
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple[800]!,
                              Colors.deepPurple[600]!,
                              Colors.purple[500]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_calendar_outlined,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Edit Jadwal Pertemuan',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${item['mata_pelajaran']}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        color: Colors.white.withOpacity(0.9),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Informasi Kelas',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 20,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoItem(
                                        'Kelas',
                                        '${item['kelas']}',
                                      ),
                                      _buildInfoItem(
                                        'Program Studi',
                                        '${item['prodi']}',
                                      ),
                                      _buildInfoItem(
                                        'Semester',
                                        '${item['semester']}',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernField(
                                label: 'Nomor Pertemuan',
                                icon: Icons.format_list_numbered_rounded,
                                controller: pertemuanController,
                                hint: 'Masukkan nomor pertemuan',
                                color: Colors.deepPurple,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: _buildModernDateField(
                                tanggalController,
                                setState,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildModernTimeField(
                                    'Jam Mulai',
                                    jamMulaiController,
                                    Colors.green,
                                    Icons.play_arrow_rounded,
                                    setState,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildModernTimeField(
                                    'Jam Selesai',
                                    jamSelesaiController,
                                    Colors.red,
                                    Icons.stop_rounded,
                                    setState,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: OutlinedButton(
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey[400]!,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.close,
                                            size: 22,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Batal',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.deepPurple[600]!,
                                            Colors.purple[500]!,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            () => _saveEditPertemuan(
                                              item,
                                              pertemuanController.text.trim(),
                                              tanggalController.text.trim(),
                                              jamMulaiController.text.trim(),
                                              jamSelesaiController.text.trim(),
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.save_rounded,
                                              size: 22,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Simpan Perubahan',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildModernField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    required MaterialColor color,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color[200]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color[700], size: 20),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDateField(
    TextEditingController controller,
    StateSetter setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Pertemuan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate:
                  controller.text.isNotEmpty
                      ? DateTime.parse(controller.text)
                      : DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue[600]!,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.grey[800]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                controller.text =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? 'Pilih Tanggal Pertemuan'
                        : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          controller.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.grey[800],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.blue[400],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTimeField(
    String label,
    TextEditingController controller,
    MaterialColor color,
    IconData icon,
    StateSetter setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime:
                  controller.text.isNotEmpty
                      ? TimeOfDay(
                        hour: int.parse(controller.text.split(':')[0]),
                        minute: int.parse(controller.text.split(':')[1]),
                      )
                      : TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: Colors.white,
                      hourMinuteShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dayPeriodShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    colorScheme: ColorScheme.light(
                      primary: color[600]!,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.grey[800]!,
                    ),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(alwaysUse24HourFormat: true),
                    child: child!,
                  ),
                );
              },
            );
            if (picked != null) {
              setState(() {
                controller.text =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color[200]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color[700], size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Pilih' : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          controller.text.isEmpty
                              ? Colors.grey[400]
                              : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: color[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveEditPertemuan(
    Map<String, dynamic> item,
    String newPertemuan,
    String newTanggal,
    String newJamMulai,
    String newJamSelesai,
  ) async {
    if (newTanggal.isEmpty ||
        newJamMulai.isEmpty ||
        newJamSelesai.isEmpty ||
        newPertemuan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final pertemuanNum = int.tryParse(newPertemuan);
    if (pertemuanNum == null || pertemuanNum <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor pertemuan harus berupa angka positif'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      DateTime.parse(newTanggal);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Format tanggal tidak valid: $newTanggal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      final start = TimeOfDay(
        hour: int.parse(newJamMulai.split(':')[0]),
        minute: int.parse(newJamMulai.split(':')[1]),
      );
      final end = TimeOfDay(
        hour: int.parse(newJamSelesai.split(':')[0]),
        minute: int.parse(newJamSelesai.split(':')[1]),
      );
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      if (startMinutes >= endMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jam mulai harus lebih kecil dari jam selesai'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format jam tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => isUpdating = true);
    try {
      final newJam = "$newJamMulai-$newJamSelesai";
      final updateData = {
        'id': item['id'].toString(),
        'id_mapel': item['id_mapel'].toString(),
        'pertemuan': newPertemuan,
        'tanggal': newTanggal,
        'jam': newJam,
        'kelas': item['kelas'],
        'prodi': item['prodi'] ?? '',
        'mata_pelajaran': item['mata_pelajaran'],
        'semester': item['semester'],
        'guru_email': guruEmail ?? '',
      };
      debugPrint('📤 Mengirim request edit jadwal pertemuan:');
      updateData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/edit_jadwal_presensi.php',
        ),
        body: updateData,
      );
      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');
      final responseData = json.decode(response.body);
      if (responseData['status'] == true) {
        debugPrint('✅ SUKSES: ${responseData['message']}');
        if (responseData['updated'] != null) {
          debugPrint('📊 Data hasil update:');
          responseData['updated'].forEach((key, value) {
            debugPrint('  $key: $value');
          });
        }
        _showToast('Jadwal pertemuan berhasil diperbarui');
        Navigator.of(context).pop();
        await fetchMataPelajaran();
      } else {
        debugPrint('❌ ERROR: ${responseData['message']}');
        _showErrorDialog(responseData['message'] ?? 'Gagal memperbarui jadwal');
      }
    } catch (e) {
      debugPrint('❌ EXCEPTION: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void _showEditProdiDialog({
    required String prodiLama,
    required String kelas,
    required String mataPelajaran,
  }) {
    final prodiController = TextEditingController(text: prodiLama);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Program Studi'),
          content: TextField(
            controller: prodiController,
            decoration: const InputDecoration(labelText: 'Nama Prodi Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final prodiBaru = prodiController.text.trim();
                if (prodiBaru.isEmpty) return;
                await _editPresensiKelas(
                  prodiLama: prodiLama,
                  kelasLama: kelas,
                  mapelLama: mataPelajaran,
                  prodiBaru: prodiBaru,
                  kelasBaru: kelas,
                  mapelBaru: mataPelajaran,
                );
                Navigator.of(context).pop();
                await fetchMataPelajaran();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditKelasDialog({
    required String kelasLama,
    required String prodi,
    required String mataPelajaran,
  }) {
    final kelasController = TextEditingController(text: kelasLama);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Kelas'),
          content: TextField(
            controller: kelasController,
            decoration: const InputDecoration(labelText: 'Nama Kelas Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final kelasBaru = kelasController.text.trim();
                if (kelasBaru.isEmpty) return;
                await _editPresensiKelas(
                  prodiLama: prodi,
                  kelasLama: kelasLama,
                  mapelLama: mataPelajaran,
                  prodiBaru: prodi,
                  kelasBaru: kelasBaru,
                  mapelBaru: mataPelajaran,
                );
                Navigator.of(context).pop();
                await fetchMataPelajaran();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMapelDialog({
    required String mapelLama,
    required String kelas,
    required String prodi,
  }) {
    final mapelController = TextEditingController(text: mapelLama);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Mata Pelajaran'),
          content: TextField(
            controller: mapelController,
            decoration: const InputDecoration(labelText: 'Nama Mapel Baru'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mapelBaru = mapelController.text.trim();
                if (mapelBaru.isEmpty) return;
                await _editPresensiKelas(
                  prodiLama: prodi,
                  kelasLama: kelas,
                  mapelLama: mapelLama,
                  prodiBaru: prodi,
                  kelasBaru: kelas,
                  mapelBaru: mapelBaru,
                );
                Navigator.of(context).pop();
                await fetchMataPelajaran();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPresensiKelas({
    required String prodiLama,
    required String kelasLama,
    required String mapelLama,
    required String prodiBaru,
    required String kelasBaru,
    required String mapelBaru,
  }) async {
    final response = await http.post(
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/guru/edit_presensi_kelas.php',
      ),
      body: {
        'prodi_lama': prodiLama,
        'kelas_lama': kelasLama,
        'mata_pelajaran_lama': mapelLama,
        'prodi_baru': prodiBaru,
        'kelas_baru': kelasBaru,
        'mata_pelajaran_baru': mapelBaru,
      },
    );
    final data = json.decode(response.body);
    if (data['status'] == true) {
      _showToast('Berhasil mengedit data');
    } else {
      _showErrorDialog(data['message'] ?? 'Gagal mengedit data');
    }
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  bool _isInTimeRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
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
