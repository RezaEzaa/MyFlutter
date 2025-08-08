import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class AdminDataViewPage extends StatefulWidget {
  const AdminDataViewPage({Key? key}) : super(key: key);
  @override
  State<AdminDataViewPage> createState() => _AdminDataViewPageState();
}

class _AdminDataViewPageState extends State<AdminDataViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  List<Map<String, dynamic>> teacherList = [];
  List<Map<String, dynamic>> studentList = [];
  Set<String> expandedProdiGuru = {};
  Set<String> expandedProdiSiswa = {};
  Set<String> expandedKelasSiswa = {};
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchTeachers();
    fetchStudents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchTeachers() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/admin/get_teachers.php',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              teacherList = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        } else {
          showToast('Gagal mengambil data guru: ${data['message']}');
        }
      } else {
        showToast('Gagal terhubung ke server');
      }
    } catch (e) {
      showToast('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> fetchStudents() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/admin/get_students.php',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              studentList = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        } else {
          showToast('Gagal mengambil data siswa: ${data['message']}');
        }
      } else {
        showToast('Gagal terhubung ke server');
      }
    } catch (e) {
      showToast('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey[700],
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.blue,
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text(
            'Manajemen Data Akun',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            labelColor:
                Theme.of(context).brightness == Brightness.light
                    ? Colors.indigo
                    : Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: const [
              Tab(text: "Guru", icon: Icon(Icons.school)),
              Tab(text: "Siswa", icon: Icon(Icons.people)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTeacherListView(),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStudentListView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherListView() {
    final Map<String, List<Map<String, dynamic>>> groupedByProdi = {};
    for (var guru in teacherList) {
      final prodi = guru['prodi'] ?? 'Unknown';
      groupedByProdi.putIfAbsent(prodi, () => []).add(guru);
    }
    if (groupedByProdi.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Tidak ada data guru yang sesuai dengan pencarian",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    List<String> sortedProdiKeys = groupedByProdi.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(8),
      children:
          sortedProdiKeys.map((prodi) {
            final guruList = groupedByProdi[prodi]!;
            final isExpanded = expandedProdiGuru.contains(prodi);
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedProdiGuru.remove(prodi);
                        } else {
                          expandedProdiGuru.add(prodi);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: const Icon(Icons.badge, color: Colors.indigo),
                      title: Text(
                        '$prodi',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
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
                        children:
                            guruList.map((guru) {
                              final photoUrl =
                                  guru['foto'] ??
                                  'http://10.167.91.233/aplikasi-checkin/uploads/guru/default.png';
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (_) => Dialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const SizedBox(height: 16),
                                                    Hero(
                                                      tag: 'guru-${guru['id']}',
                                                      child: CircleAvatar(
                                                        backgroundImage:
                                                            NetworkImage(
                                                              photoUrl,
                                                            ),
                                                        radius: 60,
                                                        onBackgroundImageError:
                                                            (_, __) {},
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      guru['nama_lengkap'] ??
                                                          'Tidak Ada Nama',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _buildDetailItem(
                                                      icon: Icons.email,
                                                      title: 'Email',
                                                      value:
                                                          guru['email'] ?? '-',
                                                      color: Colors.orange,
                                                    ),
                                                    const Divider(),
                                                    _buildDetailItem(
                                                      icon: Icons.badge,
                                                      title: 'Prodi',
                                                      value:
                                                          guru['prodi'] ?? '-',
                                                      color: Colors.indigo,
                                                    ),
                                                    const Divider(),
                                                    _buildDetailItem(
                                                      icon:
                                                          guru['jenis_kelamin'] ==
                                                                  'L'
                                                              ? Icons.male
                                                              : Icons.female,
                                                      title: 'Jenis Kelamin',
                                                      value:
                                                          guru['jenis_kelamin'] ==
                                                                  'L'
                                                              ? 'Laki-laki'
                                                              : 'Perempuan',
                                                      color:
                                                          guru['jenis_kelamin'] ==
                                                                  'L'
                                                              ? Colors.blue
                                                              : Colors.pink,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const SizedBox(height: 12),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(
                                                          Icons.edit,
                                                          color: Colors.white,
                                                        ),
                                                        label: const Text(
                                                          'Edit Data Guru',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          _showEditGuruDialog(
                                                            guru,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                            ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blueAccent,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          'Tutup',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            photoUrl,
                                          ),
                                          radius: 25,
                                          onBackgroundImageError: (_, __) {},
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      guru['nama_lengkap'] ??
                                                          'Tidak Ada Nama',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                    guru['jenis_kelamin'] == 'L'
                                                        ? Icons.male
                                                        : Icons.female,
                                                    color:
                                                        guru['jenis_kelamin'] ==
                                                                'L'
                                                            ? Colors.blue
                                                            : Colors.pink,
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                guru['email'] ??
                                                    'Tidak Ada Email',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                      ],
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
          }).toList(),
    );
  }

  Widget _buildStudentListView() {
    final Map<String, Map<String, List<Map<String, dynamic>>>>
    groupedByProdiKelas = {};
    for (var siswa in studentList) {
      final prodi = siswa['prodi'] ?? 'Unknown';
      final kelas = siswa['kelas'] ?? 'Unknown';
      groupedByProdiKelas.putIfAbsent(prodi, () => {});
      groupedByProdiKelas[prodi]!.putIfAbsent(kelas, () => []).add(siswa);
    }
    if (groupedByProdiKelas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Tidak ada data siswa yang sesuai dengan pencarian",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    List<String> sortedProdiKeys = groupedByProdiKelas.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(8),
      children:
          sortedProdiKeys.map((prodi) {
            final kelasMap = groupedByProdiKelas[prodi]!;
            final isExpandedProdi = expandedProdiSiswa.contains(prodi);
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpandedProdi) {
                          expandedProdiSiswa.remove(prodi);
                        } else {
                          expandedProdiSiswa.add(prodi);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: const Icon(Icons.school, color: Colors.cyan),
                      title: Text(
                        '$prodi',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(
                        isExpandedProdi ? Icons.expand_less : Icons.expand_more,
                      ),
                    ),
                  ),
                  if (isExpandedProdi)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Column(
                        children:
                            (kelasMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((
                              kelasEntry,
                            ) {
                              final kelas = kelasEntry.key;
                              final siswaList = kelasEntry.value;
                              final kelasKey = '$prodi:$kelas';
                              final isExpandedKelas = expandedKelasSiswa
                                  .contains(kelasKey);
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpandedKelas) {
                                            expandedKelasSiswa.remove(kelasKey);
                                          } else {
                                            expandedKelasSiswa.add(kelasKey);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.class_,
                                          color: Colors.teal,
                                        ),
                                        title: Text(
                                          'Kelas: $kelas',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        trailing: Icon(
                                          isExpandedKelas
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                        ),
                                      ),
                                    ),
                                    if (isExpandedKelas)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 5,
                                        ),
                                        child: Column(
                                          children:
                                              (siswaList..sort((a, b) {
                                                    final noAbsenA =
                                                        int.tryParse(
                                                          a['no_absen']
                                                                  ?.toString() ??
                                                              '0',
                                                        ) ??
                                                        0;
                                                    final noAbsenB =
                                                        int.tryParse(
                                                          b['no_absen']
                                                                  ?.toString() ??
                                                              '0',
                                                        ) ??
                                                        0;
                                                    return noAbsenA.compareTo(
                                                      noAbsenB,
                                                    );
                                                  }))
                                                  .map((siswa) {
                                                    final photoUrl =
                                                        siswa['foto'] ??
                                                        'http://10.167.91.233/aplikasi-checkin/uploads/siswa/default.png';
                                                    return Card(
                                                      elevation: 1,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      margin:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                          ),
                                                      child: InkWell(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (_) => Dialog(
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          16,
                                                                        ),
                                                                  ),
                                                                  child: SingleChildScrollView(
                                                                    child: Padding(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            16.0,
                                                                          ),
                                                                      child: Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          const SizedBox(
                                                                            height:
                                                                                16,
                                                                          ),
                                                                          Stack(
                                                                            alignment:
                                                                                Alignment.bottomRight,
                                                                            children: [
                                                                              Hero(
                                                                                tag:
                                                                                    'siswa-${siswa['id']}',
                                                                                child: CircleAvatar(
                                                                                  backgroundImage: NetworkImage(
                                                                                    photoUrl,
                                                                                  ),
                                                                                  radius:
                                                                                      60,
                                                                                  onBackgroundImageError:
                                                                                      (
                                                                                        _,
                                                                                        __,
                                                                                      ) {},
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                16,
                                                                          ),
                                                                          Text(
                                                                            siswa['nama_lengkap'] ??
                                                                                'Tidak Ada Nama',
                                                                            style: const TextStyle(
                                                                              fontSize:
                                                                                  20,
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                            ),
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                20,
                                                                          ),
                                                                          _buildDetailItem(
                                                                            icon:
                                                                                Icons.email,
                                                                            title:
                                                                                'Email',
                                                                            value:
                                                                                siswa['email'] ??
                                                                                '-',
                                                                            color:
                                                                                Colors.orange,
                                                                          ),
                                                                          const Divider(),
                                                                          _buildDetailItem(
                                                                            icon:
                                                                                Icons.format_list_numbered,
                                                                            title:
                                                                                'No Absen',
                                                                            value:
                                                                                siswa['no_absen']?.toString() ??
                                                                                '-',
                                                                            color:
                                                                                Colors.amber,
                                                                          ),
                                                                          const Divider(),
                                                                          _buildDetailItem(
                                                                            icon:
                                                                                Icons.class_,
                                                                            title:
                                                                                'Kelas',
                                                                            value:
                                                                                kelas,
                                                                            color:
                                                                                Colors.teal,
                                                                          ),
                                                                          const Divider(),
                                                                          _buildDetailItem(
                                                                            icon:
                                                                                Icons.school,
                                                                            title:
                                                                                'Prodi',
                                                                            value:
                                                                                prodi,
                                                                            color:
                                                                                Colors.indigo,
                                                                          ),
                                                                          const Divider(),
                                                                          _buildDetailItem(
                                                                            icon:
                                                                                siswa['jenis_kelamin'] ==
                                                                                        'L'
                                                                                    ? Icons.male
                                                                                    : Icons.female,
                                                                            title:
                                                                                'Jenis Kelamin',
                                                                            value:
                                                                                siswa['jenis_kelamin'] ==
                                                                                        'L'
                                                                                    ? 'Laki-laki'
                                                                                    : 'Perempuan',
                                                                            color:
                                                                                siswa['jenis_kelamin'] ==
                                                                                        'L'
                                                                                    ? Colors.blue
                                                                                    : Colors.pink,
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                16,
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                12,
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                double.infinity,
                                                                            child: ElevatedButton.icon(
                                                                              icon: const Icon(
                                                                                Icons.edit,
                                                                                color:
                                                                                    Colors.white,
                                                                              ),
                                                                              label: const Text(
                                                                                'Edit Data Siswa',
                                                                                style: TextStyle(
                                                                                  color:
                                                                                      Colors.white,
                                                                                ),
                                                                              ),
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor:
                                                                                    Colors.orange,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    8,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              onPressed: () {
                                                                                Navigator.pop(
                                                                                  context,
                                                                                );
                                                                                _showEditSiswaDialog(
                                                                                  siswa,
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                double.infinity,
                                                                            child: ElevatedButton(
                                                                              onPressed:
                                                                                  () => Navigator.pop(
                                                                                    context,
                                                                                  ),
                                                                              style: ElevatedButton.styleFrom(
                                                                                backgroundColor:
                                                                                    Colors.blueAccent,
                                                                                shape: RoundedRectangleBorder(
                                                                                  borderRadius: BorderRadius.circular(
                                                                                    8,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              child: const Text(
                                                                                'Tutup',
                                                                                style: TextStyle(
                                                                                  color:
                                                                                      Colors.white,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                          );
                                                        },
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                12,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Container(
                                                                    width: 15,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Text(
                                                                      '${siswa['no_absen'] ?? '-'}',
                                                                      style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            20,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  CircleAvatar(
                                                                    backgroundImage:
                                                                        NetworkImage(
                                                                          photoUrl,
                                                                        ),
                                                                    radius: 25,
                                                                    onBackgroundImageError:
                                                                        (
                                                                          _,
                                                                          __,
                                                                        ) {},
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                width: 12,
                                                              ),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Flexible(
                                                                          child: Text(
                                                                            siswa['nama_lengkap'] ??
                                                                                'Tidak Ada Nama',
                                                                            style: const TextStyle(
                                                                              fontWeight:
                                                                                  FontWeight.bold,
                                                                              fontSize:
                                                                                  16,
                                                                            ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          width:
                                                                              6,
                                                                        ),
                                                                        Icon(
                                                                          siswa['jenis_kelamin'] ==
                                                                                  'L'
                                                                              ? Icons.male
                                                                              : Icons.female,
                                                                          color:
                                                                              siswa['jenis_kelamin'] ==
                                                                                      'L'
                                                                                  ? Colors.blue
                                                                                  : Colors.pink,
                                                                          size:
                                                                              16,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height: 4,
                                                                    ),
                                                                    Text(
                                                                      siswa['email'] ??
                                                                          'Tidak Ada Email',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color:
                                                                            Colors.grey,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const Icon(
                                                                Icons
                                                                    .arrow_forward_ios,
                                                                size: 16,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditGuruDialog(Map<String, dynamic> guru) {
    final namaController = TextEditingController(
      text: guru['nama_lengkap'] ?? '',
    );
    final emailController = TextEditingController(text: guru['email'] ?? '');
    final prodiController = TextEditingController(text: guru['prodi'] ?? '');
    final gender = guru['jenis_kelamin'] ?? 'L';
    final fotoController = TextEditingController(
      text: _extractFileName(guru['foto'] ?? ''),
    );
    final originalEmail = guru['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        String selectedGender = gender;
        return AlertDialog(
          title: const Text('Edit Data Guru'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message about email changes
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perubahan email akan memperbarui semua data terkait (mata pelajaran, presensi, kelas) secara otomatis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: originalEmail,
                    helperText: 'Email saat ini: $originalEmail',
                  ),
                ),
                TextField(
                  controller: prodiController,
                  decoration: const InputDecoration(labelText: 'Prodi'),
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedGender = val;
                  },
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                ),
                TextField(
                  controller: fotoController,
                  decoration: const InputDecoration(
                    labelText: 'Nama File Foto',
                    hintText: 'contoh: foto_guru.jpg',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi input
                if (namaController.text.trim().isEmpty) {
                  showToast('Nama lengkap tidak boleh kosong');
                  return;
                }
                if (emailController.text.trim().isEmpty) {
                  showToast('Email tidak boleh kosong');
                  return;
                }
                if (!RegExp(
                  r'^[^@]+@[^@]+\.[^@]+',
                ).hasMatch(emailController.text.trim())) {
                  showToast('Format email tidak valid');
                  return;
                }
                if (prodiController.text.trim().isEmpty) {
                  showToast('Prodi tidak boleh kosong');
                  return;
                }

                await _editDataGuru(
                  id: guru['id'].toString(),
                  nama: namaController.text.trim(),
                  email: emailController.text.trim(),
                  prodi: prodiController.text.trim(),
                  gender: selectedGender,
                  foto: fotoController.text.trim(),
                );
                Navigator.pop(context);
                await fetchTeachers();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDataGuru({
    required String id,
    required String nama,
    required String email,
    required String prodi,
    required String gender,
    required String foto,
  }) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Menyimpan perubahan...'),
              ],
            ),
          ),
    );

    try {
      final response = await http
          .post(
            Uri.parse(
              'http://10.167.91.233/aplikasi-checkin/pages/admin/edit_data.php',
            ),
            body: {
              'type': 'guru',
              'id': id,
              'nama_lengkap': nama,
              'email': email,
              'prodi': prodi,
              'jenis_kelamin': gender,
              'foto': foto,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: Proses edit memakan waktu terlalu lama',
              );
            },
          );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          showToast(
            'Data guru berhasil diperbarui. Semua data terkait email lama telah diupdate.',
          );
        } else {
          _showErrorDialog(
            'Gagal mengedit data guru',
            data['message'] ?? 'Terjadi kesalahan tidak diketahui',
          );
        }
      } else {
        _showErrorDialog(
          'Kesalahan Server',
          'HTTP Error ${response.statusCode}',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      String errorMessage = 'Terjadi kesalahan saat mengedit data guru';
      if (e.toString().contains('Timeout')) {
        errorMessage =
            'Proses edit memakan waktu terlalu lama. Silakan coba lagi.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }

      _showErrorDialog('Error', errorMessage);
    }
  }

  void _showEditSiswaDialog(Map<String, dynamic> siswa) {
    final namaController = TextEditingController(
      text: siswa['nama_lengkap'] ?? '',
    );
    final emailController = TextEditingController(text: siswa['email'] ?? '');
    final prodiController = TextEditingController(text: siswa['prodi'] ?? '');
    final kelasController = TextEditingController(text: siswa['kelas'] ?? '');
    final noAbsenController = TextEditingController(
      text: siswa['no_absen']?.toString() ?? '',
    );
    final gender = siswa['jenis_kelamin'] ?? 'L';
    final fotoController = TextEditingController(
      text: _extractFileName(siswa['foto'] ?? ''),
    );
    final originalEmail = siswa['email'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        String selectedGender = gender;
        return AlertDialog(
          title: const Text('Edit Data Siswa'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message about data updates
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Perubahan data akan memperbarui semua record presensi siswa yang terkait.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: originalEmail,
                    helperText: 'Email saat ini: $originalEmail',
                  ),
                ),
                TextField(
                  controller: prodiController,
                  decoration: const InputDecoration(labelText: 'Prodi'),
                ),
                TextField(
                  controller: kelasController,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                ),
                TextField(
                  controller: noAbsenController,
                  decoration: const InputDecoration(labelText: 'No Absen'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedGender = val;
                  },
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                ),
                TextField(
                  controller: fotoController,
                  decoration: const InputDecoration(
                    labelText: 'Nama File Foto',
                    hintText: 'contoh: foto_siswa.jpg',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasi input
                if (namaController.text.trim().isEmpty) {
                  showToast('Nama lengkap tidak boleh kosong');
                  return;
                }
                if (emailController.text.trim().isEmpty) {
                  showToast('Email tidak boleh kosong');
                  return;
                }
                if (!RegExp(
                  r'^[^@]+@[^@]+\.[^@]+',
                ).hasMatch(emailController.text.trim())) {
                  showToast('Format email tidak valid');
                  return;
                }
                if (prodiController.text.trim().isEmpty) {
                  showToast('Prodi tidak boleh kosong');
                  return;
                }
                if (kelasController.text.trim().isEmpty) {
                  showToast('Kelas tidak boleh kosong');
                  return;
                }
                if (noAbsenController.text.trim().isEmpty) {
                  showToast('No absen tidak boleh kosong');
                  return;
                }

                // Validasi no absen harus berupa angka
                final noAbsen = int.tryParse(noAbsenController.text.trim());
                if (noAbsen == null || noAbsen <= 0) {
                  showToast('No absen harus berupa angka positif');
                  return;
                }

                await _editDataSiswa(
                  id: siswa['id'].toString(),
                  nama: namaController.text.trim(),
                  email: emailController.text.trim(),
                  prodi: prodiController.text.trim(),
                  kelas: kelasController.text.trim(),
                  noAbsen: noAbsenController.text.trim(),
                  gender: selectedGender,
                  foto: fotoController.text.trim(),
                );
                Navigator.pop(context);
                await fetchStudents();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editDataSiswa({
    required String id,
    required String nama,
    required String email,
    required String prodi,
    required String kelas,
    required String noAbsen,
    required String gender,
    required String foto,
  }) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Menyimpan perubahan...'),
              ],
            ),
          ),
    );

    try {
      final response = await http
          .post(
            Uri.parse(
              'http://10.167.91.233/aplikasi-checkin/pages/admin/edit_data.php',
            ),
            body: {
              'type': 'siswa',
              'id': id,
              'nama_lengkap': nama,
              'email': email,
              'prodi': prodi,
              'kelas': kelas,
              'no_absen': noAbsen,
              'jenis_kelamin': gender,
              'foto': foto,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Timeout: Proses edit memakan waktu terlalu lama',
              );
            },
          );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          showToast(
            'Data siswa berhasil diperbarui. Semua data presensi terkait telah diupdate.',
          );
        } else {
          _showErrorDialog(
            'Gagal mengedit data siswa',
            data['message'] ?? 'Terjadi kesalahan tidak diketahui',
          );
        }
      } else {
        _showErrorDialog(
          'Kesalahan Server',
          'HTTP Error ${response.statusCode}',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      String errorMessage = 'Terjadi kesalahan saat mengedit data siswa';
      if (e.toString().contains('Timeout')) {
        errorMessage =
            'Proses edit memakan waktu terlalu lama. Silakan coba lagi.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage =
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      }

      _showErrorDialog('Error', errorMessage);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                const Text(
                  'Jika masalah berlanjut, silakan hubungi administrator.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  String _extractFileName(String fotoPath) {
    if (fotoPath.isEmpty) return '';
    if (fotoPath.contains('/')) {
      return fotoPath.split('/').last;
    }
    return fotoPath;
  }
}
