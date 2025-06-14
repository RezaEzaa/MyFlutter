import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceSystemPage extends StatefulWidget {
  const AttendanceSystemPage({super.key});

  @override
  _AttendanceSystemPageState createState() => _AttendanceSystemPageState();
}

class _AttendanceSystemPageState extends State<AttendanceSystemPage> {
  bool _isFaceDetectionActive = false;
  int? _idPresensiKelas;
  bool _loading = true;
  String? _guruEmail;

  final String baseUrl =
      'http://192.168.242.233'; // Ganti dengan URL server kamu

  @override
  void initState() {
    super.initState();
    _loadGuruEmail();
  }

  Future<void> _loadGuruEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('guru_email');

    if (email != null) {
      _guruEmail = email; // Simpan dulu tanpa setState
      await _fetchActivePresensi(); // Tunggu fetch selesai
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email guru tidak ditemukan di SharedPreferences'),
        ),
      );
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchActivePresensi() async {
    print("Memuat presensi untuk guru_email = $_guruEmail");
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/aplikasi-checkin/api/get_active_presensi.php?guru_email=$_guruEmail',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          setState(() {
            _idPresensiKelas = data['data']['id'];
            final currentStatus = data['data']['status'];
            _isFaceDetectionActive = currentStatus == 'aktif';
          });
          print("DATA: ${data['data']}");
          print("STATUS: ${data['data']['status']}");
        } else {
          setState(() {
            _idPresensiKelas = null;
            _isFaceDetectionActive = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching active presensi: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFaceDetection() async {
    if (_idPresensiKelas == null || _guruEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presensi aktif tidak ditemukan')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      String url =
          _isFaceDetectionActive
              ? 'http://192.168.242.205/aplikasi-checkin/api/stop_detection.php'
              : 'http://192.168.242.205/aplikasi-checkin/api/start_detection.php';

      final response = await http.post(
        Uri.parse(url),
        body: {
          'id_presensi_kelas': _idPresensiKelas.toString(),
          'guru_email': _guruEmail!,
        },
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        setState(() {
          _isFaceDetectionActive = !_isFaceDetectionActive;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFaceDetectionActive
                  ? 'Sistem presensi diaktifkan'
                  : 'Sistem presensi dinonaktifkan',
            ),
          ),
        );

        if (!_isFaceDetectionActive) {
          await _fetchActivePresensi();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Gagal ubah status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Koneksi gagal: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sistem Presensi',
                        style: TextStyle(
                          fontFamily: 'TitilliumWeb',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      GestureDetector(
                        onTap: _loading ? null : _toggleFaceDetection,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _isFaceDetectionActive
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          child: Center(
                            child: Icon(
                              _isFaceDetectionActive
                                  ? Icons.sensors
                                  : Icons.sensors_off,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isFaceDetectionActive
                            ? 'Sistem Presensi Aktif'
                            : _idPresensiKelas != null
                            ? 'Sistem Presensi Siap Dimulai'
                            : 'Sistem Presensi Nonaktif',
                        style: const TextStyle(
                          fontFamily: 'TitilliumWeb',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_idPresensiKelas == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            'Tidak ada presensi aktif.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
