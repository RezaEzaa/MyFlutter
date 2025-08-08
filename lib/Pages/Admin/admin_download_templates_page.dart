import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:checkin/Pages/settings_page.dart';

class DownloadTemplatePage extends StatelessWidget {
  const DownloadTemplatePage({super.key});
  Future<int> _androidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> downloadFile(BuildContext context, String fileName) async {
    try {
      if (Platform.isAndroid && (await _androidVersion() <= 29)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw Exception("Izin penyimpanan ditolak");
      }
      final dio = Dio();
      final url =
          "http://10.167.91.233/aplikasi-checkin/pages/admin/download_templates.php?file=$fileName";
      final directory = await getTemporaryDirectory();
      final tempPath = "${directory.path}/$fileName";
      await dio.download(url, tempPath);
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
      );
      final savedPath = await FlutterFileDialog.saveFile(params: params);
      if (savedPath != null) {
        Fluttertoast.showToast(
          msg: 'File berhasil disimpan: $fileName',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey,
        );
      } else {
        _showErrorDialog(context, 'Penyimpanan dibatalkan');
      }
    } catch (e) {
      _showErrorDialog(context, 'Gagal mengunduh $fileName: $e');
    }
  }

  Future<void> downloadAllTemplates(BuildContext context) async {
    await downloadFile(context, 'Data_Sekolah.xlsx');
    await downloadFile(context, 'Data_Guru.xlsx');
    await downloadFile(context, 'Data_Siswa.xlsx');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Terjadi Kesalahan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildDownloadButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: color ?? Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_download_outlined,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Unduh Template Data Excel",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'TitilliumWeb',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Gunakan file template ini untuk menginput data sekolah, guru, dan siswa",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildDownloadButton(
                  label: "Unduh Template Data Sekolah",
                  icon: Icons.school,
                  onPressed: () => downloadFile(context, 'Data_Sekolah.xlsx'),
                  color: Colors.teal,
                ),
                _buildDownloadButton(
                  label: "Unduh Template Data Guru",
                  icon: Icons.person,
                  onPressed: () => downloadFile(context, 'Data_Guru.xlsx'),
                  color: Colors.indigo,
                ),
                _buildDownloadButton(
                  label: "Unduh Template Data Siswa",
                  icon: Icons.group,
                  onPressed: () => downloadFile(context, 'Data_Siswa.xlsx'),
                  color: Colors.deepPurple,
                ),
                const Divider(height: 40),
                _buildDownloadButton(
                  label: "Unduh Semua Template",
                  icon: Icons.download_for_offline_rounded,
                  onPressed: () => downloadAllTemplates(context),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
