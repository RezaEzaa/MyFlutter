import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AttendanceRecapPage extends StatefulWidget {
  const AttendanceRecapPage({super.key});

  @override
  State<AttendanceRecapPage> createState() => _AttendanceRecapPageState();
}

class _AttendanceRecapPageState extends State<AttendanceRecapPage> {
  bool isLoading = false;

  Future<void> _downloadAttendanceRecap() async {
    setState(() => isLoading = true);

    try {
      // Meminta izin penyimpanan untuk Android versi 29 atau lebih rendah
      if (Platform.isAndroid && (await _androidVersion() <= 29)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showErrorDialog('Izin penyimpanan ditolak');
          setState(() => isLoading = false);
          return;
        }
      }

      // Mengambil email guru dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';
      final url =
          'http://192.168.242.233/aplikasi-checkin/pages/rekap/export_attendance_excel.php';

      // Mengambil file Excel dari server
      final response = await http.post(
        Uri.parse(url),
        body: {'guru_email': guruEmail},
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh file Excel');
      }

      // Mendapatkan direktori sementara perangkat
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/rekap_presensi.xlsx';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);

      // Tampilkan dialog untuk memilih lokasi simpan
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: 'rekap_presensi.xlsx',
      );
      final savedPath = await FlutterFileDialog.saveFile(params: params);

      if (savedPath != null) {
        _showSuccessToast(
          'File berhasil disimpan.\nSilakan cek File Manager pada folder yang Anda pilih.',
        );
        await OpenFile.open(savedPath);
      } else {
        _showErrorDialog('Penyimpanan dibatalkan');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Mendapatkan versi Android untuk mengatur izin penyimpanan
  Future<int> _androidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            isLoading
                ? const CircularProgressIndicator()
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Rekap Presensi',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _downloadAttendanceRecap,
                      child: const Text('Buat Rekap Presensi'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        minimumSize: const Size(200, 48),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
