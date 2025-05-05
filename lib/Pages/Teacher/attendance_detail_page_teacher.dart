import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/get_detail_presensi.php?id_presensi_kelas=${widget.idPresensiKelas}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          setState(() {
            siswaList = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorSnackBar(data['message']);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorSnackBar(
          'Gagal mengambil data, status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Terjadi kesalahan saat mengambil data!');
    }
  }

  Future<void> updateAttendanceStatus({
    required int idPresensiDetail,
    required String status,
    String? keterangan,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/edit_presensi_siswa.php',
        ),
        body: {
          'id': idPresensiDetail.toString(),
          'status': status,
          if (keterangan != null) 'keterangan': keterangan,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == true) {
        _showSuccessSnackBar('Status presensi berhasil diubah!');
        fetchAttendanceData();
      } else {
        _showErrorSnackBar('Gagal mengubah status presensi!');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan saat memperbarui data!');
    }
  }

  void _editStatusDialog(Map<String, dynamic> siswa) async {
    String selectedStatus =
        siswa['status']?.toString().isNotEmpty == true
            ? siswa['status']
            : 'Hadir';
    String selectedKeterangan =
        siswa['keterangan']?.toString().isNotEmpty == true
            ? siswa['keterangan']
            : 'Tanpa Keterangan';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      setState(() {
                        selectedStatus = value!;
                        if (value == 'Hadir') {
                          selectedKeterangan = '';
                        }
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
                        setState(() {
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
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop({
                        'status': selectedStatus,
                        'keterangan':
                            selectedStatus == 'Tidak Hadir'
                                ? selectedKeterangan
                                : '',
                      }),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.kelas} - ${widget.mataPelajaran}')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : siswaList.isEmpty
              ? const Center(child: Text('Belum ada data presensi siswa.'))
              : ListView.builder(
                itemCount: siswaList.length,
                itemBuilder: (context, index) {
                  final siswa = siswaList[index];
                  final fotoUrl =
                      (siswa['foto']?.toString().startsWith('http') == true)
                          ? siswa['foto']
                          : 'http://192.168.218.89/aplikasi-checkin/uploads/siswa/default.png';

                  final statusText =
                      siswa['status']?.toString().isNotEmpty == true
                          ? siswa['status']
                          : '-';
                  final showKeterangan =
                      siswa['status']?.toString() == 'Tidak Hadir' &&
                      siswa['keterangan']?.toString().isNotEmpty == true;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(fotoUrl),
                      ),
                      title: Text(
                        siswa['nama_lengkap'] ?? 'Nama tidak tersedia',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: $statusText'),
                          if (showKeterangan)
                            Text(
                              'Keterangan: ${siswa['keterangan']?.toString()}',
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () => _editStatusDialog(siswa),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
