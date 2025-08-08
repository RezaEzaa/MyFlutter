import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:fluttertoast/fluttertoast.dart';

class StudentListByClassPage extends StatefulWidget {
  final String kelas;
  final String prodi;
  const StudentListByClassPage({
    super.key,
    required this.kelas,
    required this.prodi,
  });
  @override
  State<StudentListByClassPage> createState() => _StudentListByClassPageState();
}

class _StudentListByClassPageState extends State<StudentListByClassPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  String? guruEmail;
  @override
  void initState() {
    super.initState();
    loadGuruEmailAndFetchStudents();
  }

  Future<void> loadGuruEmailAndFetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    guruEmail = prefs.getString('guru_email');
    if (guruEmail != null) {
      await fetchStudents();
    } else {
      _showErrorDialog("Guru email tidak ditemukan");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);
    try {
      final uri = Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/guru/get_students_by_class.php?kelas=${Uri.encodeComponent(widget.kelas)}&prodi=${Uri.encodeComponent(widget.prodi)}&guru_email=${Uri.encodeComponent(guruEmail!)}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(
            () => students = List<Map<String, dynamic>>.from(data['data']),
          );
          _showSuccessToast("Data siswa berhasil dimuat.");
        } else {
          _showErrorDialog(data['message'] ?? "Gagal memuat data siswa.");
        }
      } else {
        _showErrorDialog("Gagal koneksi. Status ${response.statusCode}.");
      }
    } catch (e) {
      _showErrorDialog("Kesalahan: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessToast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[700],
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(msg),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.prodi.isNotEmpty
            ? '${widget.kelas} (${widget.prodi})'
            : widget.kelas;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('asset/images/logo.png', width: 120, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
              ? const Center(child: Text("Belum ada siswa di kelas ini"))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.class_rounded,
                      color: Colors.green,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftar Siswa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$title • ${students.length} siswa",
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchStudents,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final isLaki = student['jenis_kelamin'] == 'L';
                            final iconJK = isLaki ? Icons.male : Icons.female;
                            final colorJK = isLaki ? Colors.blue : Colors.pink;
                            final fotoUrl =
                                student['foto'] ??
                                'http://10.167.91.233/aplikasi-checkin/uploads/siswa/default.png';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 5,
                                horizontal: 0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 15,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${student['no_absen'] ?? '-'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: NetworkImage(fotoUrl),
                                        onBackgroundImageError: (_, __) {},
                                      ),
                                    ],
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          student['nama_lengkap'] ??
                                              'Nama Siswa',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(iconJK, color: colorJK, size: 16),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        student['email'] ?? 'Tidak ada email',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
