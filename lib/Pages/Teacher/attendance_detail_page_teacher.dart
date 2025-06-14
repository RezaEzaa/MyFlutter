import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import 'package:checkin/Pages/settings_page.dart';

class AttendanceDetailPageTeacher extends StatefulWidget {
  final String kelas;
  final String mataPelajaran;
  final int idPresensiKelas;

  const AttendanceDetailPageTeacher({
    Key? key,
    required this.kelas,
    required this.mataPelajaran,
    required this.idPresensiKelas,
  }) : super(key: key);

  @override
  _AttendanceDetailPageTeacherState createState() =>
      _AttendanceDetailPageTeacherState();
}

class _AttendanceDetailPageTeacherState
    extends State<AttendanceDetailPageTeacher> {
  bool isLoading = true;
  List<Map<String, dynamic>> siswaList = [];
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/get_detail_presensi_guru.php?id_presensi_kelas=${widget.idPresensiKelas}',
        ),
      );

      print(
        'http://192.168.242.233/aplikasi-checkin/pages/guru/get_detail_presensi_guru.php?id_presensi_kelas=${widget.idPresensiKelas}',
      );
      print('ID presensi dari widget: ${widget.idPresensiKelas}');
      print('Dikirim ke API: id_presensi_kelas=${widget.idPresensiKelas}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          siswaList =
              data['status']
                  ? List<Map<String, dynamic>>.from(data['data'])
                  : [];
          isLoading = false;
        });
        _showSuccessToast('Data presensi berhasil dimuat.');
      } else {
        setState(() {
          siswaList = [];
          isLoading = false;
        });
        _showErrorDialog('Gagal mengambil data presensi dari server.');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error saat mengambil data: $e');
      _showErrorDialog('Terjadi kesalahan saat mengambil data!');
    }
  }

  Future<void> updateAttendanceStatus({
    required int idPresensiDetail,
    required String status,
    String? keterangan,
  }) async {
    setState(() => isUpdating = true);
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/guru/edit_presensi_siswa.php',
        ),
        body: {
          'id': idPresensiDetail.toString(),
          'status': status,
          if (keterangan != null) 'keterangan': keterangan,
        },
      );

      print(
        'Mengupdate id: $idPresensiDetail dengan status: $status dan keterangan: $keterangan',
      );

      final data = json.decode(response.body);
      if (data['status'] == true) {
        _showSuccessToast('Status berhasil diperbarui');
        await fetchAttendanceData();
      } else {
        _showErrorDialog('Gagal memperbarui status');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan saat memperbarui data!');
    }
    setState(() => isUpdating = false);
  }

  void _editStatusDialog(Map<String, dynamic> siswa) async {
    String selectedStatus =
        (siswa['status'] ?? '').toString().isNotEmpty
            ? siswa['status']
            : 'Hadir';

    String selectedKeterangan =
        (siswa['keterangan'] ?? '').toString().isNotEmpty
            ? siswa['keterangan']
            : 'Tanpa Keterangan';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Status Kehadiran'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedStatus,
                    items:
                        ['Hadir', 'Tidak Hadir']
                            .map(
                              (val) => DropdownMenuItem(
                                value: val,
                                child: Text(val),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                        if (value == 'Hadir') selectedKeterangan = '';
                      });
                    },
                  ),
                  if (selectedStatus == 'Tidak Hadir')
                    DropdownButton<String>(
                      value: selectedKeterangan,
                      items:
                          ['Sakit', 'Izin', 'Tanpa Keterangan']
                              .map(
                                (val) => DropdownMenuItem(
                                  value: val,
                                  child: Text(val),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedKeterangan = value!;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'status': selectedStatus,
                      'keterangan':
                          selectedStatus == 'Tidak Hadir'
                              ? selectedKeterangan
                              : '',
                    });
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null &&
        (result['status'] != siswa['status'] ||
            result['keterangan'] != siswa['keterangan'])) {
      await updateAttendanceStatus(
        idPresensiDetail: siswa['id'],
        status: result['status']!,
        keterangan:
            result['status'] == 'Tidak Hadir' ? result['keterangan'] : null,
      );
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

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('isLoading: $isLoading, jumlah siswa: ${siswaList.length}');
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
              Image.asset('asset/images/logo.png', width: 120, height: 30),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : siswaList.isEmpty
              ? const Center(child: Text('Belum ada data presensi siswa.'))
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: ListTile(
                        title: Text(
                          'Daftar Presensi Siswa Kelas',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        subtitle: Text(
                          '${widget.kelas}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: siswaList.length,
                        itemBuilder: (context, index) {
                          final siswa = siswaList[index];
                          final fotoUrl =
                              (siswa['foto']?.toString().isNotEmpty ?? false)
                                  ? siswa['foto']
                                  : 'http://192.168.242.233/aplikasi-checkin/uploads/siswa/default.png';

                          final jenisKelaminIcon =
                              siswa['jenis_kelamin'] == 'L'
                                  ? Icons.male
                                  : Icons.female;
                          final jenisKelaminColor =
                              siswa['jenis_kelamin'] == 'L'
                                  ? Colors.blue
                                  : Colors.pink;

                          final statusText =
                              (siswa['status']?.toString().isNotEmpty ?? false)
                                  ? siswa['status']
                                  : '';
                          final keteranganText =
                              (siswa['status'] == 'Tidak Hadir' &&
                                      (siswa['keterangan']
                                              ?.toString()
                                              .isNotEmpty ??
                                          false))
                                  ? ' (${siswa['keterangan']})'
                                  : '';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(fotoUrl),
                              ),
                              title: Text(
                                siswa['nama_lengkap'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $statusText$keteranganText',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    jenisKelaminIcon,
                                    color: jenisKelaminColor,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _editStatusDialog(siswa),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
