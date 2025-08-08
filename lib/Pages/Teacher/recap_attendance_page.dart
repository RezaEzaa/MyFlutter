import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceRecapPage extends StatefulWidget {
  const AttendanceRecapPage({super.key});
  @override
  State<AttendanceRecapPage> createState() => _AttendanceRecapPageState();
}

class _AttendanceRecapPageState extends State<AttendanceRecapPage> {
  bool isLoadingDownload = false;
  bool isLoadingUpload = false;
  bool isLoadingUpdate = false;
  bool isLoadingTemplate = false;
  bool hasUploadedData = false;
  bool isCheckingUploadStatus = true;
  String importMode = 'replace_all'; // Add import mode variable
  @override
  void initState() {
    super.initState();
    _checkUploadStatus();
  }

  Future<void> _checkUploadStatus() async {
    setState(() => isCheckingUploadStatus = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';
      debugPrint("🔍 Checking upload status for email: $guruEmail");
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/check_upload_status.php',
        ),
        body: {'guru_email': guruEmail},
      );
      debugPrint("📥 Upload status response: ${response.statusCode}");
      debugPrint("📥 Upload status body: ${response.body}");
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        setState(() {
          hasUploadedData = jsonResponse['has_data'] ?? false;
        });
        debugPrint("📊 Has uploaded data: $hasUploadedData");
      }
    } catch (e) {
      debugPrint('❌ Error checking upload status: $e');
    } finally {
      setState(() => isCheckingUploadStatus = false);
    }
  }

  Future<void> _showImportModeDialog(VoidCallback onProceed) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '📥 Pilih Mode Import',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih bagaimana Anda ingin mengimpor mata pelajaran:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('🔄 Ganti Semua'),
                    subtitle: const Text(
                      'Hapus mata pelajaran lama, ganti dengan yang baru',
                    ),
                    value: 'replace_all',
                    groupValue: importMode,
                    onChanged: (String? value) {
                      setState(() {
                        importMode = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('➕ Tambah Baru'),
                    subtitle: const Text(
                      'Pertahankan mata pelajaran lama, tambah yang baru',
                    ),
                    value: 'add_new',
                    groupValue: importMode,
                    onChanged: (String? value) {
                      setState(() {
                        importMode = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          importMode == 'replace_all'
                              ? '🔄 Mode: Ganti Semua'
                              : '➕ Mode: Tambah Baru',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          importMode == 'replace_all'
                              ? 'Semua mata pelajaran yang sudah ada akan dihapus dan diganti dengan mata pelajaran baru.'
                              : 'Mata pelajaran yang sudah ada akan dipertahankan. Mata pelajaran baru akan ditambahkan.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Lanjutkan'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onProceed();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _downloadAttendanceRecap() async {
    setState(() => isLoadingDownload = true);
    try {
      if (Platform.isAndroid && (await _androidVersion() <= 29)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          _showErrorDialog('Izin penyimpanan ditolak');
          setState(() => isLoadingDownload = false);
          return;
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';

      if (guruEmail.isEmpty) {
        _showErrorDialog('Email guru tidak ditemukan. Silakan login ulang.');
        setState(() => isLoadingDownload = false);
        return;
      }

      final url =
          'http://10.167.91.233/aplikasi-checkin/pages/rekap/export_attendance_excel.php';
      debugPrint("📤 Downloading attendance recap for email: $guruEmail");

      final response = await http
          .post(Uri.parse(url), body: {'guru_email': guruEmail})
          .timeout(
            const Duration(minutes: 3),
            onTimeout: () {
              throw Exception(
                'Timeout: Proses download memakan waktu terlalu lama',
              );
            },
          );

      debugPrint("📥 Download response status: ${response.statusCode}");
      debugPrint(
        "📥 Response content-type: ${response.headers['content-type']}",
      );

      if (response.statusCode == 400) {
        throw Exception('Email guru tidak valid atau tidak diberikan');
      } else if (response.statusCode == 500) {
        throw Exception('Kesalahan server database');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengunduh file Excel (Status: ${response.statusCode})',
        );
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('spreadsheet') &&
          !contentType.contains('excel')) {
        final responseText = utf8.decode(response.bodyBytes);
        if (responseText.contains('Tidak ada data') ||
            responseText.contains('data presensi')) {
          throw Exception(
            'Tidak ada data presensi yang ditemukan untuk guru ini',
          );
        }
        throw Exception('Response bukan file Excel yang valid');
      }
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/rekap_presensi.xlsx';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: 'rekap_presensi.xlsx',
      );
      final savedPath = await FlutterFileDialog.saveFile(params: params);
      if (savedPath != null) {
        _showSuccessToast('File rekap presensi berhasil disimpan dan dibuka.');
        await OpenFile.open(savedPath);
      } else {
        _showErrorDialog('Penyimpanan dibatalkan oleh pengguna');
      }
    } catch (e) {
      debugPrint("❌ Error downloading attendance recap: $e");
      String errorMessage = 'Gagal mengunduh rekap presensi';

      if (e.toString().contains('Timeout')) {
        errorMessage =
            'Proses download memakan waktu terlalu lama. Silakan coba lagi.';
      } else if (e.toString().contains('Email guru tidak valid')) {
        errorMessage = 'Email guru tidak valid. Silakan login ulang.';
      } else if (e.toString().contains('Kesalahan server database')) {
        errorMessage =
            'Terjadi kesalahan pada server database. Silakan coba lagi nanti.';
      } else if (e.toString().contains('Tidak ada data presensi')) {
        errorMessage =
            'Tidak ada data presensi yang ditemukan untuk akun Anda.';
      } else if (e.toString().contains('Response bukan file Excel')) {
        errorMessage =
            'Terjadi kesalahan dalam pemrosesan data. Silakan hubungi administrator.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      setState(() => isLoadingDownload = false);
    }
  }

  Future<void> _downloadTemplateMataPelajaran() async {
    setState(() => isLoadingTemplate = true);
    try {
      if (Platform.isAndroid && (await _androidVersion() <= 29)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw Exception("Izin penyimpanan ditolak");
      }
      final dio = Dio();
      const fileName = "Data_Mata_Pelajaran.xlsx";
      const url =
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
        _showSuccessToast('Template berhasil disimpan.');
      } else {
        _showErrorDialog('Penyimpanan dibatalkan');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() => isLoadingTemplate = false);
    }
  }

  Future<void> _uploadFileMataPelajaran() async {
    // Only for first upload when no data exists - no import mode needed
    await _processUploadMataPelajaran();
  }

  Future<void> _processUploadMataPelajaran() async {
    setState(() => isLoadingUpload = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) {
        setState(() => isLoadingUpload = false);
        return;
      }
      File file = File(result.files.single.path!);
      final fileSizeInBytes = await file.length();
      if (fileSizeInBytes > 10 * 1024 * 1024) {
        _showErrorDialog('Ukuran file terlalu besar. Maksimal 10MB.');
        setState(() => isLoadingUpload = false);
        return;
      }

      const url =
          'http://10.167.91.233/aplikasi-checkin/pages/guru/import_mata_pelajaran.php';
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';

      debugPrint("📤 Uploading new file: ${file.path}");
      debugPrint("📤 Target URL: $url");
      debugPrint("📤 Guru Email: $guruEmail");
      debugPrint(
        "📤 File size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB",
      );

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['guru_email'] = guruEmail;

      var response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception(
            'Timeout: Proses upload memakan waktu terlalu lama. Silakan coba lagi.',
          );
        },
      );

      final responseBody = await response.stream.bytesToString();
      debugPrint("📥 Response Status: ${response.statusCode}");
      debugPrint("📥 Raw Response: $responseBody");

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse['log'] != null && jsonResponse['log'] is List) {
            debugPrint("📄 Detailed Log from Backend:");
            for (int i = 0; i < jsonResponse['log'].length; i++) {
              debugPrint("  ${i + 1}. ${jsonResponse['log'][i]}");
            }
          }
          if (jsonResponse['status'] == 'success') {
            _showSuccessToast('File berhasil diunggah dan diproses!');
            await _checkUploadStatus();
          } else {
            String errorMessage =
                jsonResponse['message'] ?? 'Terjadi kesalahan tidak diketahui';
            if (jsonResponse['log'] != null && jsonResponse['log'] is List) {
              final logs = (jsonResponse['log'] as List).join('\n');
              errorMessage += '\n\nDetail Log:\n$logs';
            }
            _showErrorDialog(errorMessage);
          }
        } catch (e) {
          debugPrint("❌ Error parsing JSON response: $e");
          _showErrorDialog(
            'Error parsing response: $e\n\nRaw Response:\n$responseBody',
          );
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      debugPrint("❌ Exception in upload: $e");
      _showErrorDialog('Upload gagal:\n${e.toString()}');
    } finally {
      setState(() => isLoadingUpload = false);
    }
  }

  Future<void> _updateFileMataPelajaran() async {
    // Show import mode dialog first
    await _showImportModeDialog(() => _processUpdateFileMataPelajaran());
  }

  Future<void> _processUpdateFileMataPelajaran() async {
    bool? confirm = await _showUpdateConfirmationDialog();
    if (confirm != true) return;

    setState(() => isLoadingUpdate = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) {
        setState(() => isLoadingUpload = false);
        return;
      }
      File file = File(result.files.single.path!);
      final fileSizeInBytes = await file.length();
      if (fileSizeInBytes > 10 * 1024 * 1024) {
        _showErrorDialog('Ukuran file terlalu besar. Maksimal 10MB.');
        setState(() => isLoadingUpdate = false);
        return;
      }

      const url =
          'http://10.167.91.233/aplikasi-checkin/pages/guru/update_mata_pelajaran.php';
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';

      debugPrint("📤 Updating file: ${file.path}");
      debugPrint("📤 Target URL: $url");
      debugPrint("📤 Guru Email: $guruEmail");
      debugPrint(
        "📤 File size: ${(fileSizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB",
      );

      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['guru_email'] = guruEmail;
      request.fields['import_mode'] = importMode; // Add import mode parameter

      var response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception(
            'Timeout: Proses update memakan waktu terlalu lama. Silakan coba lagi.',
          );
        },
      );

      final responseBody = await response.stream.bytesToString();
      debugPrint("📥 Response Status: ${response.statusCode}");
      debugPrint("📥 Raw Response: $responseBody");

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse['log'] != null && jsonResponse['log'] is List) {
            debugPrint("📄 Detailed Log from Backend:");
            for (int i = 0; i < jsonResponse['log'].length; i++) {
              debugPrint("  ${i + 1}. ${jsonResponse['log'][i]}");
            }
          }
          if (jsonResponse['status'] == 'success') {
            _showSuccessToast('Data mata pelajaran berhasil diperbarui!');
            await _checkUploadStatus();
          } else {
            String errorMessage =
                jsonResponse['message'] ?? 'Terjadi kesalahan tidak diketahui';
            if (jsonResponse['log'] != null && jsonResponse['log'] is List) {
              final logs = (jsonResponse['log'] as List).join('\n');
              errorMessage += '\n\nDetail Log:\n$logs';
            }
            _showErrorDialog(errorMessage);
          }
        } catch (e) {
          debugPrint("❌ Error parsing JSON response: $e");
          _showErrorDialog(
            'Error parsing response: $e\n\nRaw Response:\n$responseBody',
          );
        }
      } else {
        throw Exception('HTTP Error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      debugPrint("❌ Exception in update: $e");
      _showErrorDialog('Update gagal:\n${e.toString()}');
    } finally {
      setState(() => isLoadingUpdate = false);
    }
  }

  Future<bool?> _showUpdateConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                importMode == 'replace_all'
                    ? Icons.warning_amber
                    : Icons.info_outline,
                color:
                    importMode == 'replace_all' ? Colors.orange : Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  importMode == 'replace_all'
                      ? 'Konfirmasi Update Data'
                      : 'Konfirmasi Tambah Data',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  importMode == 'replace_all'
                      ? 'Anda sudah memiliki data mata pelajaran. Mode "Ganti Semua" akan:'
                      : 'Anda sudah memiliki data mata pelajaran. Mode "Tambah Baru" akan:',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                if (importMode == 'replace_all') ...[
                  const Text('• Menghapus semua data presensi siswa yang ada'),
                  const Text('• Menghapus semua jadwal presensi kelas'),
                  const Text('• Menghapus data mata pelajaran lama'),
                  const Text('• Menghapus file Excel lama'),
                  const Text('• Mengimpor data baru dari file yang dipilih'),
                  const SizedBox(height: 16),
                  const Text(
                    '⚠️ PERINGATAN: Proses ini tidak dapat dibatalkan!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pastikan Anda telah membackup data jika diperlukan.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ] else ...[
                  const Text('• Mempertahankan semua data yang sudah ada'),
                  const Text('• Menambahkan mata pelajaran baru dari file'),
                  const Text('• Membuat jadwal presensi tambahan'),
                  const Text('• Data lama tidak akan terhapus'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mode ini aman dan tidak akan menghapus data yang sudah ada.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    importMode == 'replace_all' ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                importMode == 'replace_all'
                    ? 'Ya, Lanjutkan Update'
                    : 'Ya, Tambah Data',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

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
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Terjadi Kesalahan'),
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

  Widget buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
    double? iconSize,
  }) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: iconSize ?? 28,
                  color: iconColor ?? Colors.blueAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
    Color? color,
    bool isDisabled = false,
    String? loadingText,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon:
            isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon),
        label: Text(isLoading && loadingText != null ? loadingText : label),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDisabled ? Colors.grey : (color ?? Colors.blueAccent),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16),
        ),
        onPressed: (isLoading || isDisabled) ? null : onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment,
                    size: 60,
                    color: Colors.lightGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rekap Presensi & Input Data Mata Pelajaran',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildCard(
              title: "Unduh Rekap Presensi",
              icon: Icons.receipt,
              iconColor: Colors.green,
              iconSize: 30,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'File Excel akan berisi data lengkap presensi dengan kolom: Tanggal, Jam, Pertemuan, Email Guru, Kelas, Mata Pelajaran, Semester, Status Presensi Kelas, Nama Lengkap Siswa, Jenis Kelamin, Status Kehadiran, dan Keterangan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                buildActionButton(
                  icon: Icons.download_for_offline,
                  label: "Unduh Rekap Presensi",
                  onPressed: _downloadAttendanceRecap,
                  isLoading: isLoadingDownload,
                  loadingText: "Memproses rekap presensi...",
                ),
              ],
            ),
            buildCard(
              title: "Input Data Mata Pelajaran",
              icon: Icons.school,
              iconColor: Colors.green,
              iconSize: 30,
              children: [
                buildActionButton(
                  icon: Icons.file_download,
                  label: "Unduh Template Excel",
                  onPressed: _downloadTemplateMataPelajaran,
                  isLoading: isLoadingTemplate,
                  color: Colors.teal,
                ),
                const SizedBox(height: 12),
                // Tombol upload hanya tampil jika belum ada data
                if (!hasUploadedData && !isCheckingUploadStatus) ...[
                  buildActionButton(
                    icon: Icons.upload_file,
                    label: "Unggah Excel Mata Pelajaran",
                    onPressed: _uploadFileMataPelajaran,
                    isLoading: isLoadingUpload,
                    color: Colors.blueAccent,
                  ),
                ],
                // Info dan tombol tambahan hanya tampil jika sudah ada data
                if (hasUploadedData && !isCheckingUploadStatus) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data mata pelajaran sudah tersedia. Gunakan tombol "Update Data Mata Pelajaran" untuk menambah mata pelajaran baru atau mengganti semua data lama (Anda akan diminta memilih mode).',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildActionButton(
                    icon: Icons.download,
                    label: "Download File Excel Mata Pelajaran",
                    onPressed: _downloadUploadedExcel,
                    isLoading: isLoadingDownload,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  buildActionButton(
                    icon: Icons.update,
                    label: "Update/Tambah Data Mata Pelajaran",
                    onPressed: _updateFileMataPelajaran,
                    isLoading: isLoadingUpdate,
                    color: Colors.orange,
                  ),
                ],
                // Info untuk user yang belum upload
                if (!hasUploadedData && !isCheckingUploadStatus) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Belum ada data mata pelajaran. Silakan unduh template Excel terlebih dahulu, lalu isi data dan unggah kembali.',
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
                ],
                // Loading state
                if (isCheckingUploadStatus) ...[
                  const SizedBox(height: 12),
                  const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Memeriksa status data...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadUploadedExcel() async {
    setState(() => isLoadingDownload = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final guruEmail = prefs.getString('guru_email') ?? '';
      final url =
          'http://10.167.91.233/aplikasi-checkin/pages/guru/download_file_excel.php?email_guru=$guruEmail';
      debugPrint("📤 Downloading uploaded Excel for email: $guruEmail");
      final response = await http.get(Uri.parse(url));
      debugPrint("📥 Download response status: ${response.statusCode}");
      if (response.statusCode != 200) {
        throw Exception('Gagal mengunduh file Excel');
      }
      String fileName = 'mata_pelajaran.xlsx';
      final contentDisposition = response.headers['content-disposition'];
      if (contentDisposition != null) {
        final regex = RegExp(r'filename="(.+)"');
        final match = regex.firstMatch(contentDisposition);
        if (match != null) {
          fileName = match.group(1)!;
        }
      }
      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(response.bodyBytes);
      final params = SaveFileDialogParams(
        sourceFilePath: tempPath,
        fileName: fileName,
      );
      final savedPath = await FlutterFileDialog.saveFile(params: params);
      if (savedPath != null) {
        _showSuccessToast('File berhasil disimpan.');
        await OpenFile.open(savedPath);
      } else {
        _showErrorDialog('Penyimpanan dibatalkan');
      }
    } catch (e) {
      debugPrint("❌ Error downloading uploaded Excel: $e");
      _showErrorDialog('Error: ${e.toString()}');
    } finally {
      setState(() => isLoadingDownload = false);
    }
  }
}
