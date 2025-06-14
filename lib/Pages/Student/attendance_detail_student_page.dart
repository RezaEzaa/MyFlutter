import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceDetailStudentPage extends StatefulWidget {
  final Map presensi;

  const AttendanceDetailStudentPage({Key? key, required this.presensi})
    : super(key: key);

  @override
  State<AttendanceDetailStudentPage> createState() =>
      _AttendanceDetailStudentPageState();
}

class _AttendanceDetailStudentPageState
    extends State<AttendanceDetailStudentPage> {
  bool isLoading = true;
  Map<String, dynamic>? detailData;

  @override
  void initState() {
    super.initState();
    fetchDetailData();
  }

  Future<void> fetchDetailData() async {
    setState(() => isLoading = true);
    try {
      final idPresensiSiswa = widget.presensi['id'] ?? '';
      final response = await http.get(
        Uri.parse(
          'http://192.168.242.233/aplikasi-checkin/pages/siswa/get_detail_presensi_siswa.php?id_presensi_siswa=$idPresensiSiswa',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            detailData = data['data'];
          });
          _showSuccessToast('Data presensi berhasil dimuat.');
        } else {
          setState(() {
            detailData = null;
          });
          _showErrorDialog('Data presensi tidak ditemukan.');
        }
      } else {
        setState(() {
          detailData = null;
        });
        _showErrorDialog('Gagal mengambil data presensi dari server.');
      }
    } catch (e) {
      setState(() {
        detailData = null;
      });
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelas = detailData?['kelas'] ?? widget.presensi['kelas'] ?? '';
    final mataPelajaran =
        detailData?['mata_pelajaran'] ??
        widget.presensi['mata_pelajaran'] ??
        '';
    final namaLengkap = detailData?['nama_lengkap'] ?? '';
    final jenisKelamin = detailData?['jenis_kelamin'] ?? '';
    final foto =
        detailData?['foto'] ??
        'http://192.168.242.233/aplikasi-checkin/uploads/siswa/default.png';
    final status = (detailData?['status'] ?? '').toString();
    final keterangan = detailData?['keterangan'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text('$mataPelajaran')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : detailData == null
              ? const Center(child: Text('Data presensi tidak ditemukan.'))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Detail Presensi',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(foto),
                                radius: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  namaLengkap,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                              Icon(
                                jenisKelamin.toLowerCase() == 'l'
                                    ? Icons.male
                                    : Icons.female,
                                color:
                                    jenisKelamin.toLowerCase() == 'l'
                                        ? Colors.blue
                                        : Colors.pink,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.class_, color: Colors.orange),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Kelas: $kelas',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.book, color: Colors.green),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Mata Pelajaran: $mataPelajaran',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Tanggal: ${widget.presensi['tanggal_presensi'] ?? ''}',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                status.toLowerCase() == 'hadir'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color:
                                    status.toLowerCase() == 'hadir'
                                        ? Colors.green
                                        : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        status.toLowerCase() == 'hadir'
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ),
                            ],
                          ),
                          if (status.toLowerCase() == 'tidak hadir')
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Keterangan: $keterangan',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.redAccent,
                                      ),
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
}
