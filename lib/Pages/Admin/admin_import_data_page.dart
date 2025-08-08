import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';

class AdminDataImportPage extends StatefulWidget {
  const AdminDataImportPage({super.key});
  @override
  State<AdminDataImportPage> createState() => _AdminDataImportPageState();
}

class _AdminDataImportPageState extends State<AdminDataImportPage> {
  File? sekolahFile, guruFile, siswaFile;
  String? sekolahFileName, guruFileName, siswaFileName;
  bool isUploadingAll = false;
  String? adminEmail;
  bool hasSekolahData = false;
  bool hasGuruData = false;
  bool hasSiswaData = false;
  bool isDownloadingSekolah = false;
  bool isDownloadingGuru = false;
  bool isDownloadingSiswa = false;

  // Import mode variables
  String importMode = 'replace_all'; // 'replace_all' or 'add_new'
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadAdminEmail();
    await checkExistingData();
  }

  Future<void> loadAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminEmail = prefs.getString('admin_email');
      hasSekolahData = prefs.getBool('has_sekolah_data') ?? false;
      hasGuruData = prefs.getBool('has_guru_data') ?? false;
      hasSiswaData = prefs.getBool('has_siswa_data') ?? false;
    });
    print("🔍 loadAdminEmail - adminEmail: '$adminEmail'");
    print(
      "🔍 loadAdminEmail - hasSekolahData: $hasSekolahData, hasGuruData: $hasGuruData, hasSiswaData: $hasSiswaData",
    );
  }

  Future<void> checkExistingData() async {
    print("🔍 checkExistingData called with adminEmail: '$adminEmail'");
    if (adminEmail == null) {
      print("❌ checkExistingData: adminEmail is null, skipping");
      return;
    }
    final dio = Dio();
    try {
      final formData = FormData.fromMap({
        'admin_email': adminEmail,
        'check_type': 'all',
      });
      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_upload_status.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      print("Check Status Response Code: ${resp.statusCode}");
      print("Check Status Response Data: ${resp.data}");
      if (resp.statusCode == 200) {
        final responseData = json.decode(resp.data);
        print("🔍 checkExistingData - Full Response: $responseData");
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          print("🔍 checkExistingData - Data section: $data");
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            hasSekolahData = data['sekolah']?['excel_exists'] ?? false;
            hasGuruData = data['guru']?['excel_exists'] ?? false;
            hasSiswaData = data['siswa']?['excel_exists'] ?? false;
          });
          await prefs.setBool('has_sekolah_data', hasSekolahData);
          await prefs.setBool('has_guru_data', hasGuruData);
          await prefs.setBool('has_siswa_data', hasSiswaData);
          print("✅ Status check berhasil:");
          print("   Sekolah: $hasSekolahData");
          print("   Guru: $hasGuruData");
          print("   Siswa: $hasSiswaData");
        }
      }
    } catch (e) {
      print('Error checking existing data: $e');
      await _checkIndividualData();
    }
  }

  Future<void> _checkIndividualData() async {
    final dio = Dio();
    try {
      final sekolahFormData = FormData.fromMap({'admin_email': adminEmail});
      final sekolahResp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_sekolah_status.php',
        data: sekolahFormData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (sekolahResp.statusCode == 200) {
        final sekolahData = json.decode(sekolahResp.data);
        print("🔍 Sekolah Status Response: $sekolahData");
        hasSekolahData = sekolahData['has_data'] ?? false;
        print("🔍 hasSekolahData: $hasSekolahData");
      }
      final guruFormData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': 'guru',
      });
      final guruResp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_guru_siswa_status.php',
        data: guruFormData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (guruResp.statusCode == 200) {
        final guruData = json.decode(guruResp.data);
        print("🔍 Guru Status Response: $guruData");
        hasGuruData = guruData['data']?['excel_exists'] ?? false;
        print("🔍 hasGuruData: $hasGuruData");
      }
      final siswaFormData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': 'siswa',
      });
      final siswaResp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_guru_siswa_status.php',
        data: siswaFormData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (siswaResp.statusCode == 200) {
        final siswaData = json.decode(siswaResp.data);
        print("🔍 Siswa Status Response: $siswaData");
        hasSiswaData = siswaData['data']?['excel_exists'] ?? false;
        print("🔍 hasSiswaData: $hasSiswaData");
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_sekolah_data', hasSekolahData);
      await prefs.setBool('has_guru_data', hasGuruData);
      await prefs.setBool('has_siswa_data', hasSiswaData);
      print("✅ _checkIndividualData completed:");
      print("   Sekolah: $hasSekolahData");
      print("   Guru: $hasGuruData");
      print("   Siswa: $hasSiswaData");
      setState(() {});
    } catch (e) {
      print('Error in individual data check: $e');
    }
  }

  Future<int> _androidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> _showImportModeDialog(VoidCallback onProceed) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Pilih Mode Import'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih mode import data:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  // Replace All option
                  RadioListTile<String>(
                    title: const Text('Ganti Semua Data'),
                    subtitle: const Text(
                      'Hapus data lama dan ganti dengan data baru (mode default)',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: 'replace_all',
                    groupValue: importMode,
                    onChanged: (String? value) {
                      setState(() {
                        importMode = value!;
                      });
                    },
                  ),

                  // Add New option
                  RadioListTile<String>(
                    title: const Text('Tambah Data Baru'),
                    subtitle: const Text(
                      'Tambahkan data baru tanpa menghapus data yang sudah ada',
                      style: TextStyle(fontSize: 12),
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            importMode == 'replace_all'
                                ? 'Data lama akan dihapus dan diganti dengan data baru'
                                : 'Data baru akan ditambahkan, data lama tetap ada',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onProceed();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Lanjutkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> pickFile(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        if (type == 'sekolah') sekolahFile = file;
        if (type == 'guru') guruFile = file;
        if (type == 'siswa') siswaFile = file;
      });
    }
  }

  Future<void> uploadAllFiles() async {
    if (adminEmail == null) {
      Fluttertoast.showToast(msg: "Email admin tidak ditemukan");
      return;
    }
    final fileMap = {
      'sekolah': sekolahFile,
      'guru': guruFile,
      'siswa': siswaFile,
    };
    bool hasFiles = fileMap.values.any((file) => file != null);
    if (!hasFiles) {
      Fluttertoast.showToast(msg: "Pilih minimal satu file untuk diproses");
      return;
    }

    // Show import mode dialog first
    await _showImportModeDialog(() => _processAllFiles(fileMap));
  }

  Future<void> _processAllFiles(Map<String, File?> fileMap) async {
    setState(() => isUploadingAll = true);
    final dio = Dio();
    for (var entry in fileMap.entries) {
      final type = entry.key;
      final file = entry.value;
      if (file == null) continue;
      String endpoint;
      FormData formData;
      if (type == 'sekolah') {
        endpoint =
            'http://10.167.91.233/aplikasi-checkin/pages/admin/update_data_sekolah.php';
        formData = FormData.fromMap({
          'admin_email': adminEmail,
          'import_mode': importMode, // Add import mode parameter
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      } else {
        endpoint =
            'http://10.167.91.233/aplikasi-checkin/pages/admin/update_data_guru_siswa.php';
        formData = FormData.fromMap({
          'admin_email': adminEmail,
          'type': type,
          'import_mode': importMode, // Add import mode parameter
          'file': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      }
      try {
        final resp = await dio.post(
          endpoint,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            responseType: ResponseType.plain,
          ),
        );
        print("Process Status Code [$type]: ${resp.statusCode}");
        print("Process Response Raw Data [$type]: ${resp.data}");
        if (resp.data == null || resp.data.toString().trim().isEmpty) {
          Fluttertoast.showToast(msg: "[$type] Tidak ada respons dari server.");
          continue;
        }
        late Map<String, dynamic> json;
        try {
          json = jsonDecode(resp.data.toString());
        } catch (e) {
          Fluttertoast.showToast(msg: "[$type] Format respon tidak valid.");
          print("🛑 JSON Decode Error [$type]: $e");
          print("🛑 Response content: ${resp.data}");
          continue;
        }
        if (json['status'] == 'success') {
          String successMsg = "✅ $type berhasil diproses!";
          if (type != 'sekolah' && json.containsKey('log')) {
            final logs = json['log'] as List;
            for (String logLine in logs) {
              if (logLine.contains('Summary $type')) {
                final summaryLine = logLine.replaceFirst(
                  '📊 Summary $type - ',
                  '',
                );
                successMsg += "\n📊 $summaryLine";
                break;
              }
            }
          }
          Fluttertoast.showToast(
            msg: successMsg,
            toastLength: Toast.LENGTH_LONG,
          );
          if (type == 'sekolah') {
            hasSekolahData = true;
          } else if (type == 'guru') {
            hasGuruData = true;
          } else if (type == 'siswa') {
            hasSiswaData = true;
          }
        } else {
          Fluttertoast.showToast(
            msg: "❌ $type gagal: ${json['message']}",
            toastLength: Toast.LENGTH_LONG,
          );
        }
        if (json.containsKey('log')) {
          print("📝 Log Backend [$type]:");
          for (var line in json['log']) {
            print("  • $line");
          }
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: "❌ $type gagal: $e",
          toastLength: Toast.LENGTH_LONG,
        );
        print("❌ Process Error [$type]: $e");
      }
    }
    setState(() {
      sekolahFile = null;
      sekolahFileName = null;
      guruFile = null;
      guruFileName = null;
      siswaFile = null;
      siswaFileName = null;
      isUploadingAll = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_sekolah_data', hasSekolahData);
    await prefs.setBool('has_guru_data', hasGuruData);
    await prefs.setBool('has_siswa_data', hasSiswaData);
    await checkExistingData();
  }

  Future<void> updateData(String type) async {
    if (adminEmail == null) {
      Fluttertoast.showToast(msg: "Email admin tidak ditemukan");
      return;
    }
    File? selectedFile;
    if (type == 'sekolah') selectedFile = sekolahFile;
    if (type == 'guru') selectedFile = guruFile;
    if (type == 'siswa') selectedFile = siswaFile;
    if (selectedFile == null) {
      Fluttertoast.showToast(msg: "Pilih file $type terlebih dahulu");
      return;
    }

    // Show import mode dialog first
    await _showImportModeDialog(() => _processDataUpdate(type, selectedFile!));
  }

  Future<void> _processDataUpdate(String type, File selectedFile) async {
    setState(() => isUploadingAll = true);
    final dio = Dio();
    String endpoint;
    FormData formData;
    if (type == 'sekolah') {
      endpoint =
          'http://10.167.91.233/aplikasi-checkin/pages/admin/update_data_sekolah.php';
      formData = FormData.fromMap({
        'admin_email': adminEmail,
        'import_mode': importMode, // Add import mode parameter
        'file': await MultipartFile.fromFile(
          selectedFile.path,
          filename: selectedFile.path.split('/').last,
        ),
      });
    } else {
      endpoint =
          'http://10.167.91.233/aplikasi-checkin/pages/admin/update_data_guru_siswa.php';
      formData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': type,
        'import_mode': importMode, // Add import mode parameter
        'file': await MultipartFile.fromFile(
          selectedFile.path,
          filename: selectedFile.path.split('/').last,
        ),
      });
    }
    try {
      final resp = await dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      print("Update Status Code [$type]: ${resp.statusCode}");
      print("Update Response Raw Data [$type]: ${resp.data}");
      if (resp.data == null || resp.data.toString().trim().isEmpty) {
        Fluttertoast.showToast(msg: "[$type] Tidak ada respons dari server.");
        return;
      }
      late Map<String, dynamic> json;
      try {
        json = jsonDecode(resp.data.toString());
      } catch (e) {
        Fluttertoast.showToast(msg: "[$type] Format respon tidak valid.");
        print("🛑 Update JSON Decode Error [$type]: $e");
        return;
      }
      if (json['status'] == 'success') {
        String successMsg = "✅ Update data $type berhasil!";
        if (json.containsKey('log')) {
          final logs = json['log'] as List;
          for (String logLine in logs) {
            if (logLine.contains('Summary $type')) {
              final summaryLine = logLine.replaceFirst(
                '📊 Summary $type - ',
                '',
              );
              successMsg += "\n📊 $summaryLine";
              break;
            }
          }
        }
        Fluttertoast.showToast(msg: successMsg, toastLength: Toast.LENGTH_LONG);
        setState(() {
          if (type == 'sekolah') {
            sekolahFile = null;
            sekolahFileName = null;
            hasSekolahData = true;
          }
          if (type == 'guru') {
            guruFile = null;
            guruFileName = null;
            hasGuruData = true;
          }
          if (type == 'siswa') {
            siswaFile = null;
            siswaFileName = null;
            hasSiswaData = true;
          }
        });
        final prefs = await SharedPreferences.getInstance();
        if (type == 'sekolah') {
          await prefs.setBool('has_sekolah_data', true);
        } else if (type == 'guru') {
          await prefs.setBool('has_guru_data', true);
        } else if (type == 'siswa') {
          await prefs.setBool('has_siswa_data', true);
        }
      } else {
        Fluttertoast.showToast(
          msg: "❌ Update $type gagal: ${json['message']}",
          toastLength: Toast.LENGTH_LONG,
        );
      }
      if (json.containsKey('log')) {
        print("📝 Update Log Backend [$type]:");
        for (var line in json['log']) {
          print("  • $line");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Update $type gagal: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      print("❌ Update Error [$type]: $e");
    }
    setState(() => isUploadingAll = false);
    await checkExistingData();
  }

  Future<void> download(String type) async {
    setState(() {
      if (type == 'sekolah') isDownloadingSekolah = true;
      if (type == 'guru') isDownloadingGuru = true;
      if (type == 'siswa') isDownloadingSiswa = true;
    });
    try {
      if (Platform.isAndroid && (await _androidVersion() <= 29)) {
        final status = await Permission.storage.request();
        if (!status.isGranted) throw Exception("Izin penyimpanan ditolak");
      }
      final dio = Dio();
      final url =
          'http://10.167.91.233/aplikasi-checkin/pages/admin/download_file_excel.php?file=$type';
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$type.xlsx';
      print("🔄 Mencoba download file: $type");
      print("📍 URL: $url");
      print("💾 Temp path: $tempPath");
      final checkResponse = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) {
            return status != null && status >= 200 && status < 400;
          },
        ),
      );
      print("✅ Response status: ${checkResponse.statusCode}");
      print("📋 Response headers: ${checkResponse.headers}");
      await checkResponse.data.stream.drain();
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        final file = File(tempPath);
        await file.writeAsBytes(response.data);
        print("✅ File berhasil ditulis ke: $tempPath");
        print("📊 Ukuran file: ${await file.length()} bytes");
        if (await file.length() == 0) {
          throw Exception("File yang didownload kosong");
        }
        final params = SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: '$type.xlsx',
        );
        final savedPath = await FlutterFileDialog.saveFile(params: params);
        if (savedPath != null) {
          Fluttertoast.showToast(
            msg: '✅ Berhasil mengunduh: $type.xlsx',
            toastLength: Toast.LENGTH_LONG,
          );
          print("✅ File disimpan ke: $savedPath");
        } else {
          Fluttertoast.showToast(msg: '❌ Download dibatalkan pengguna');
        }
      } else {
        throw Exception("Response tidak valid: ${response.statusCode}");
      }
    } on DioException catch (e) {
      String errorMsg = 'Gagal mengunduh $type: ';
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          errorMsg += 'Koneksi timeout';
          break;
        case DioExceptionType.sendTimeout:
          errorMsg += 'Timeout saat mengirim request';
          break;
        case DioExceptionType.receiveTimeout:
          errorMsg += 'Timeout saat menerima data';
          break;
        case DioExceptionType.badResponse:
          errorMsg += 'Bad response (${e.response?.statusCode})';
          if (e.response?.data != null) {
            try {
              final errorData = e.response!.data;
              if (errorData is String) {
                final jsonError = json.decode(errorData);
                if (jsonError['message'] != null) {
                  errorMsg += ': ${jsonError['message']}';
                }
              }
            } catch (_) {
              errorMsg += ': ${e.response!.data}';
            }
          }
          break;
        case DioExceptionType.connectionError:
          errorMsg += 'Tidak dapat terhubung ke server';
          break;
        case DioExceptionType.badCertificate:
          errorMsg += 'Masalah sertifikat SSL';
          break;
        case DioExceptionType.cancel:
          errorMsg += 'Request dibatalkan';
          break;
        case DioExceptionType.unknown:
          errorMsg += 'Error tidak dikenal: ${e.message}';
          break;
      }
      print("❌ DioException: $errorMsg");
      print("❌ Error details: ${e.toString()}");
      Fluttertoast.showToast(msg: errorMsg, toastLength: Toast.LENGTH_LONG);
    } catch (e) {
      final errorMsg = 'Gagal mengunduh $type: $e';
      print("❌ General Error: $errorMsg");
      Fluttertoast.showToast(msg: errorMsg, toastLength: Toast.LENGTH_LONG);
    } finally {
      setState(() {
        if (type == 'sekolah') isDownloadingSekolah = false;
        if (type == 'guru') isDownloadingGuru = false;
        if (type == 'siswa') isDownloadingSiswa = false;
      });
    }
  }

  Widget buildFileTile({
    required String label,
    required File? file,
    required String? lastUploadedName,
    required VoidCallback onPick,
    required VoidCallback onDownload,
    required Color color,
    required IconData icon,
    required bool hasExistingData,
    VoidCallback? onUpdate,
  }) {
    bool isDownloading = false;
    if (label.contains('Sekolah')) {
      isDownloading = isDownloadingSekolah;
    } else if (label.contains('Guru')) {
      isDownloading = isDownloadingGuru;
    } else if (label.contains('Siswa')) {
      isDownloading = isDownloadingSiswa;
    }
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, size: 36, color: color),
            title: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file?.path.split('/').last ??
                      lastUploadedName ??
                      'Pilih File',
                  style: const TextStyle(fontSize: 13),
                ),
                if (hasExistingData)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Data sudah ada',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isDownloading)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Mengunduh...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline),
                  onPressed: isDownloading ? null : onPick,
                  tooltip: "Pilih File",
                  color: isDownloading ? Colors.grey : Colors.green,
                ),
                IconButton(
                  icon:
                      isDownloading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.download),
                  onPressed: isDownloading ? null : onDownload,
                  tooltip: "Unduh Template",
                  color: isDownloading ? Colors.grey : Colors.blue,
                ),
              ],
            ),
          ),
          if (hasExistingData && onUpdate != null && file != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (isUploadingAll || isDownloading) ? null : onUpdate,
                  icon: const Icon(Icons.update, size: 18),
                  label: Text(() {
                    if (label.contains('Sekolah')) {
                      return 'Update Data Sekolah';
                    } else if (label.contains('Guru')) {
                      return 'Update Data Guru';
                    } else if (label.contains('Siswa')) {
                      return 'Update Data Siswa';
                    }
                    return 'Update Data';
                  }()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (isUploadingAll || isDownloading)
                            ? Colors.grey
                            : Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Kelola Data Excel",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'TitilliumWeb',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Import data awal atau update data yang sudah ada.\nSistem akan otomatis update jika email sudah ada, atau insert jika email baru.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                buildFileTile(
                  label: 'File Data Sekolah',
                  file: sekolahFile,
                  lastUploadedName: sekolahFileName,
                  onPick: () => pickFile('sekolah'),
                  onDownload: () => download('sekolah'),
                  icon: Icons.school,
                  color: Colors.teal,
                  hasExistingData: hasSekolahData,
                  onUpdate: () => updateData('sekolah'),
                ),
                buildFileTile(
                  label: 'File Data Guru',
                  file: guruFile,
                  lastUploadedName: guruFileName,
                  onPick: () => pickFile('guru'),
                  onDownload: () => download('guru'),
                  icon: Icons.person,
                  color: Colors.indigo,
                  hasExistingData: hasGuruData,
                  onUpdate: () => updateData('guru'),
                ),
                buildFileTile(
                  label: 'File Data Siswa',
                  file: siswaFile,
                  lastUploadedName: siswaFileName,
                  onPick: () => pickFile('siswa'),
                  onDownload: () => download('siswa'),
                  icon: Icons.group,
                  color: Colors.deepPurple,
                  hasExistingData: hasSiswaData,
                  onUpdate: () => updateData('siswa'),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isUploadingAll ? null : uploadAllFiles,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    hasSekolahData || hasGuruData || hasSiswaData
                        ? "Proses Semua Data (Update)"
                        : "Proses Semua Data (Import Awal)",
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (isUploadingAll)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
