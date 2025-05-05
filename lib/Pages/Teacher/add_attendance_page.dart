import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddAttendancePage extends StatefulWidget {
  final String kelas;
  final String guruEmail;
  final String mataPelajaran;

  const AddAttendancePage({
    Key? key,
    required this.kelas,
    required this.guruEmail,
    required this.mataPelajaran,
  }) : super(key: key);

  @override
  State<AddAttendancePage> createState() => _AddAttendancePageState();
}

class _AddAttendancePageState extends State<AddAttendancePage> {
  bool isLoading = false;

  Future<void> addAttendance() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.218.89/aplikasi-checkin/add_presensi_kelas.php',
        ),
        body: {
          'kelas': widget.kelas,
          'mata_pelajaran': widget.mataPelajaran,
          'guru_email': widget.guruEmail,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == true) {
        int idPresensiKelas = data['id_presensi_kelas'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Presensi berhasil ditambahkan!')),
        );

        Navigator.pop(
          context,
          idPresensiKelas,
        ); // bisa kirim balik ID jika diperlukan
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal menambahkan presensi!'),
          ),
        );
      }
    } catch (e) {
      print('Error saat koneksi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan!')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Presensi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelas: ${widget.kelas}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Mata Pelajaran: ${widget.mataPelajaran}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: addAttendance,
                  child: const Text('Tambahkan Presensi'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
