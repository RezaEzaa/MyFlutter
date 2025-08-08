import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/Teacher/student_list_by_class_page.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key});
  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  Map<String, List<String>> prodiKelasMap = {};
  Set<String> expandedProdi = {};
  String? guruEmail;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    loadGuruEmailAndData();
  }

  Future<void> loadGuruEmailAndData() async {
    final prefs = await SharedPreferences.getInstance();
    guruEmail = prefs.getString('guru_email');
    if (guruEmail != null && guruEmail!.isNotEmpty) {
      await fetchKelasProdi();
    }
  }

  Future<void> fetchKelasProdi() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/get_classes_detail.php',
        ),
        body: {'guru_email': guruEmail!},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status']) {
          final List kelasProdiList = data['data'];
          final Map<String, List<String>> map = {};
          for (var item in kelasProdiList) {
            final String prodi = item['prodi'] ?? '';
            final List<String> kelasList = List<String>.from(
              item['kelas_list'] ?? [],
            );
            map[prodi] = kelasList;
          }
          setState(() {
            prodiKelasMap = map;
          });
        } else {
          _showErrorDialog(data['message'] ?? 'Gagal memuat data');
        }
      } else {
        _showErrorDialog(
          'Gagal koneksi ke server (Status ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Gagal mengambil kelas & prodi: $e');
      _showErrorDialog("Terjadi kesalahan saat mengambil data");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _navigateToStudentList(String kelas, String prodi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentListByClassPage(kelas: kelas, prodi: prodi),
      ),
    );
  }

  void _toggleExpandProdi(String prodi) {
    setState(() {
      if (expandedProdi.contains(prodi)) {
        expandedProdi.remove(prodi);
      } else {
        expandedProdi.add(prodi);
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
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
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.green,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Data Siswa',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  prodiKelasMap.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'Belum ada data kelas dan prodi',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      : Expanded(
                        child: RefreshIndicator(
                          onRefresh: fetchKelasProdi,
                          child: ListView.builder(
                            itemCount: prodiKelasMap.length,
                            padding: const EdgeInsets.only(top: 10),
                            itemBuilder: (context, index) {
                              final entry = prodiKelasMap.entries.elementAt(
                                index,
                              );
                              final String prodi = entry.key;
                              final List<String> kelasList = entry.value;
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => _toggleExpandProdi(prodi),
                                      borderRadius: BorderRadius.circular(16),
                                      child: ListTile(
                                        leading: Icon(
                                          prodi.isNotEmpty
                                              ? Icons.school
                                              : Icons.group,
                                          color: Colors.green,
                                        ),
                                        title: Text(
                                          prodi.isNotEmpty ? prodi : 'Umum',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: Icon(
                                          expandedProdi.contains(prodi)
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                        ),
                                      ),
                                    ),
                                    if (expandedProdi.contains(prodi))
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          children:
                                              kelasList.map((kelas) {
                                                return Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  elevation: 2,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 4,
                                                      ),
                                                  child: InkWell(
                                                    onTap:
                                                        () =>
                                                            _navigateToStudentList(
                                                              kelas,
                                                              prodi,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: ListTile(
                                                      leading: const Icon(
                                                        Icons.class_rounded,
                                                        color: Colors.teal,
                                                      ),
                                                      title: Text(
                                                        'Kelas: $kelas',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      trailing: const Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                ],
              ),
    );
  }
}
