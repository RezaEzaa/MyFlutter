import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';

class AdminImportPhotosPage extends StatefulWidget {
  const AdminImportPhotosPage({super.key});
  @override
  State<AdminImportPhotosPage> createState() => _AdminImportPhotosPageState();
}

class _AdminImportPhotosPageState extends State<AdminImportPhotosPage> {
  File? zipGuru, zipSiswa;
  String? zipGuruName, zipSiswaName;
  bool isUploading = false;
  String? adminEmail;
  bool hasGuruPhotos = false;
  bool hasSiswaPhotos = false;
  bool isDownloadingGuru = false;
  bool isDownloadingSiswa = false;
  String importMode = 'replace_all'; // Add import mode variable
  @override
  void initState() {
    super.initState();
    _initializePhotos();
  }

  Future<void> _initializePhotos() async {
    await loadAdminEmail();
    await checkExistingPhotos();
  }

  Future<void> loadAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminEmail = prefs.getString('admin_email');
      hasGuruPhotos = prefs.getBool('has_guru_photos') ?? false;
      hasSiswaPhotos = prefs.getBool('has_siswa_photos') ?? false;
    });
    print("🔍 loadAdminEmail (Photos) - adminEmail: '$adminEmail'");
    print(
      "🔍 loadAdminEmail (Photos) - hasGuruPhotos: $hasGuruPhotos, hasSiswaPhotos: $hasSiswaPhotos",
    );
  }

  Future<void> checkExistingPhotos() async {
    print("🔍 checkExistingPhotos called with adminEmail: '$adminEmail'");
    if (adminEmail == null) {
      print("❌ checkExistingPhotos: adminEmail is null, skipping");
      return;
    }
    final dio = Dio();
    try {
      final formData = FormData.fromMap({
        'admin_email': adminEmail,
        'check_type': 'photos_only',
      });
      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_upload_status.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      print("Check Photos Status Response Code: ${resp.statusCode}");
      print("Check Photos Status Response Data: ${resp.data}");
      if (resp.statusCode == 200) {
        final responseData = json.decode(resp.data);
        print("🔍 checkExistingPhotos - Full Response: $responseData");
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          print("🔍 checkExistingPhotos - Data section: $data");
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            hasGuruPhotos = data['guru']?['photo_zip_exists'] ?? false;
            hasSiswaPhotos = data['siswa']?['photo_zip_exists'] ?? false;
          });
          await prefs.setBool('has_guru_photos', hasGuruPhotos);
          await prefs.setBool('has_siswa_photos', hasSiswaPhotos);
          print("✅ Photos status check berhasil:");
          print("   Guru Photos: $hasGuruPhotos");
          print("   Siswa Photos: $hasSiswaPhotos");
        }
      }
    } catch (e) {
      print('Error checking existing photos: $e');
      await _checkIndividualPhotos();
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
                    'Pilih bagaimana Anda ingin mengimpor foto:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text('🔄 Ganti Semua'),
                    subtitle: const Text(
                      'Hapus foto lama, ganti dengan yang baru',
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
                      'Pertahankan foto lama, tambah yang baru',
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          importMode == 'replace_all'
                              ? 'Semua foto yang sudah ada akan dihapus dan diganti dengan foto baru dari file ZIP.'
                              : 'Foto yang sudah ada akan dipertahankan. Foto baru akan ditambahkan.',
                          style: const TextStyle(fontSize: 12),
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

  Future<void> showAllPhotosStatus() async {
    if (adminEmail == null) {
      Fluttertoast.showToast(msg: "Email admin tidak ditemukan");
      return;
    }
    final dio = Dio();
    try {
      final formData = FormData.fromMap({
        'admin_email': adminEmail,
        'check_type': 'photos_only',
      });
      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_upload_status.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (resp.statusCode == 200) {
        final responseData = json.decode(resp.data);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          String statusMessage = "📸 Status Semua Foto:\n\n";
          statusMessage += "👨‍🏫 Foto Guru:\n";
          if (data['guru']?['photo_zip_exists'] == true) {
            statusMessage += "   ✅ File: ${data['guru']['latest_photo_zip']}\n";
            statusMessage +=
                "   📊 Jumlah: ${data['guru']['photo_zip_count']} file ZIP\n";
            statusMessage += "   💬 ${data['guru']['message']}\n\n";
          } else {
            statusMessage += "   ❌ Belum ada foto ZIP\n";
            statusMessage += "   💬 ${data['guru']['message']}\n\n";
          }
          statusMessage += "👨‍🎓 Foto Siswa:\n";
          if (data['siswa']?['photo_zip_exists'] == true) {
            statusMessage +=
                "   ✅ File: ${data['siswa']['latest_photo_zip']}\n";
            statusMessage +=
                "   📊 Jumlah: ${data['siswa']['photo_zip_count']} file ZIP\n";
            statusMessage += "   💬 ${data['siswa']['message']}";
          } else {
            statusMessage += "   ❌ Belum ada foto ZIP\n";
            statusMessage += "   💬 ${data['siswa']['message']}";
          }
          Fluttertoast.showToast(
            msg: statusMessage,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal mengambil status foto: $e");
      print('Error getting all photos status: $e');
    }
  }

  Future<void> _checkIndividualPhotos() async {
    final dio = Dio();
    try {
      final guruFormData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': 'guru',
      });
      final guruResp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_photos_status.php',
        data: guruFormData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (guruResp.statusCode == 200) {
        final guruData = json.decode(guruResp.data);
        print("🔍 Guru Photos Status Response: $guruData");
        hasGuruPhotos = guruData['has_data'] ?? false;
        print("🔍 hasGuruPhotos: $hasGuruPhotos");
      }
      final siswaFormData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': 'siswa',
      });
      final siswaResp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_photos_status.php',
        data: siswaFormData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (siswaResp.statusCode == 200) {
        final siswaData = json.decode(siswaResp.data);
        print("🔍 Siswa Photos Status Response: $siswaData");
        hasSiswaPhotos = siswaData['has_data'] ?? false;
        print("🔍 hasSiswaPhotos: $hasSiswaPhotos");
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_guru_photos', hasGuruPhotos);
      await prefs.setBool('has_siswa_photos', hasSiswaPhotos);
      print("✅ _checkIndividualPhotos completed:");
      print("   Guru Photos: $hasGuruPhotos");
      print("   Siswa Photos: $hasSiswaPhotos");
      setState(() {});
    } catch (e) {
      print('Error in individual photos check: $e');
    }
  }

  Future<Map<String, dynamic>?> getDetailedPhotoStatus(String type) async {
    if (adminEmail == null) return null;
    final dio = Dio();
    try {
      final formData = FormData.fromMap({
        'admin_email': adminEmail,
        'type': type,
      });
      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_photos_status.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      if (resp.statusCode == 200) {
        final responseData = json.decode(resp.data);
        if (responseData['status'] == true) {
          return responseData;
        }
      }
    } catch (e) {
      print('Error getting detailed photo status for $type: $e');
    }
    return null;
  }

  Future<void> showPhotoInfo(String type) async {
    final photoStatus = await getDetailedPhotoStatus(type);
    if (photoStatus == null) {
      Fluttertoast.showToast(msg: "Tidak dapat mengambil informasi foto $type");
      return;
    }
    String infoMessage = "📸 Informasi Foto $type:\n\n";
    if (photoStatus['has_data'] == true) {
      infoMessage += "✅ Status: ${photoStatus['message']}\n";
      infoMessage += "📁 File: ${photoStatus['latest_file'] ?? 'N/A'}\n";
      infoMessage += "📊 Jumlah: ${photoStatus['file_count'] ?? 0} file ZIP";
    } else {
      infoMessage += "❌ Status: ${photoStatus['message']}\n";
      infoMessage += "💡 Silakan upload file ZIP foto $type";
    }
    Fluttertoast.showToast(msg: infoMessage, toastLength: Toast.LENGTH_LONG);
  }

  Future<void> debugPhotosStatusCheck() async {
    print("🔧 DEBUG: Manual photos status check started");
    if (adminEmail == null) {
      print("🔧 DEBUG: adminEmail is null");
      return;
    }

    final dio = Dio();
    try {
      final formData = FormData.fromMap({
        'admin_email': adminEmail,
        'check_type': 'photos_only',
      });

      print("🔧 DEBUG: Sending request with adminEmail: $adminEmail");

      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/check_upload_status.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );

      print("🔧 DEBUG: Response status: ${resp.statusCode}");
      print("🔧 DEBUG: Raw response: ${resp.data}");

      if (resp.statusCode == 200) {
        final responseData = json.decode(resp.data);
        print("🔧 DEBUG: Parsed response: $responseData");

        if (responseData['data'] != null) {
          final data = responseData['data'];
          print("🔧 DEBUG: Data section: $data");
          print(
            "🔧 DEBUG: Guru photo_zip_exists: ${data['guru']?['photo_zip_exists']}",
          );
          print(
            "🔧 DEBUG: Siswa photo_zip_exists: ${data['siswa']?['photo_zip_exists']}",
          );
        }
      }
    } catch (e) {
      print("🔧 DEBUG: Error occurred: $e");
    }
  }

  Future<int> _androidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> pickZip(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result != null && result.files.single.path != null) {
      final pickedFile = File(result.files.single.path!);
      setState(() {
        if (type == 'guru') {
          zipGuru = pickedFile;
          zipGuruName = pickedFile.path.split('/').last;
        }
        if (type == 'siswa') {
          zipSiswa = pickedFile;
          zipSiswaName = pickedFile.path.split('/').last;
        }
      });
    }
  }

  Future<void> uploadAll() async {
    if (zipGuru == null && zipSiswa == null) {
      Fluttertoast.showToast(
        msg: "Pilih minimal satu file ZIP terlebih dahulu.",
      );
      return;
    }
    if (adminEmail == null) {
      Fluttertoast.showToast(msg: "Email admin tidak ditemukan");
      return;
    }

    // Show import mode dialog first
    await _showImportModeDialog(() => _processAllPhotos());
  }

  Future<void> _processAllPhotos() async {
    setState(() => isUploading = true);
    final dio = Dio();
    Future<void> processPhotos(String type, File file) async {
      String endpoint;
      FormData formData;
      bool hasExistingData = (type == 'guru') ? hasGuruPhotos : hasSiswaPhotos;
      if (hasExistingData) {
        endpoint =
            'http://10.167.91.233/aplikasi-checkin/pages/admin/update_photos_guru_siswa.php';
        formData = FormData.fromMap({
          'admin_email': adminEmail,
          'type': type,
          'import_mode': importMode, // Add import mode parameter
          'photos': await MultipartFile.fromFile(
            file.path,
            filename: file.path.split('/').last,
          ),
        });
      } else {
        if (type == 'guru') {
          endpoint =
              'http://10.167.91.233/aplikasi-checkin/pages/admin/upload_teacher_photos.php';
        } else {
          endpoint =
              'http://10.167.91.233/aplikasi-checkin/pages/admin/upload_student_photos.php';
        }
        formData = FormData.fromMap({
          'import_mode': importMode, // Add import mode parameter
          'zipfile': await MultipartFile.fromFile(
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
        print("Process Photos Status Code [$type]: ${resp.statusCode}");
        print("Process Photos Response Raw Data [$type]: ${resp.data}");
        if (resp.data == null || resp.data.toString().trim().isEmpty) {
          Fluttertoast.showToast(msg: "[$type] Tidak ada respons dari server.");
          return;
        }
        late Map<String, dynamic> json;
        try {
          json = jsonDecode(resp.data.toString());
        } catch (e) {
          Fluttertoast.showToast(msg: "[$type] Format respon tidak valid.");
          print("🛑 [$type] JSON Decode Error: $e");
          return;
        }
        if (json['status'] == 'success') {
          String successMsg = "✅ $type berhasil diproses!\n";
          if (hasExistingData) {
            final data = json['data'];
            if (data != null) {
              successMsg += "📊 Diproses: ${data['processed']}, ";
              successMsg += "Diupdate: ${data['updated']}, ";
              successMsg += "Tidak ditemukan: ${data['not_found']}";
            }
          } else {
            successMsg += "📊 Import awal foto $type berhasil";
          }
          Fluttertoast.showToast(
            msg: successMsg,
            toastLength: Toast.LENGTH_LONG,
          );
          if (type == 'guru') {
            hasGuruPhotos = true;
          } else if (type == 'siswa') {
            hasSiswaPhotos = true;
          }
        } else {
          Fluttertoast.showToast(
            msg: "❌ $type gagal: ${json['message']}",
            toastLength: Toast.LENGTH_LONG,
          );
        }
        if (json.containsKey('log')) {
          print("📝 [$type] Log Backend:");
          for (var line in json['log']) {
            print("  • $line");
          }
        }
      } catch (e) {
        print("❌ [$type] Process error: $e");
        Fluttertoast.showToast(
          msg: "❌ $type gagal: $e",
          toastLength: Toast.LENGTH_LONG,
        );
      }
    }

    if (zipGuru != null) await processPhotos('guru', zipGuru!);
    if (zipSiswa != null) await processPhotos('siswa', zipSiswa!);
    setState(() {
      zipGuru = null;
      zipGuruName = null;
      zipSiswa = null;
      zipSiswaName = null;
      isUploading = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_guru_photos', hasGuruPhotos);
    await prefs.setBool('has_siswa_photos', hasSiswaPhotos);
    await checkExistingPhotos();
  }

  Future<void> updatePhotos(String type) async {
    if (adminEmail == null) {
      Fluttertoast.showToast(msg: "Email admin tidak ditemukan");
      return;
    }
    File? selectedFile;
    if (type == 'guru') selectedFile = zipGuru;
    if (type == 'siswa') selectedFile = zipSiswa;
    if (selectedFile == null) {
      Fluttertoast.showToast(msg: "Pilih file ZIP $type terlebih dahulu");
      return;
    }

    // Show import mode dialog first
    await _showImportModeDialog(
      () => _processPhotosUpdate(type, selectedFile!),
    );
  }

  Future<void> _processPhotosUpdate(String type, File selectedFile) async {
    setState(() => isUploading = true);
    final dio = Dio();
    final formData = FormData.fromMap({
      'admin_email': adminEmail,
      'type': type,
      'import_mode': importMode, // Add import mode parameter
      'photos': await MultipartFile.fromFile(
        selectedFile.path,
        filename: selectedFile.path.split('/').last,
      ),
    });
    try {
      final resp = await dio.post(
        'http://10.167.91.233/aplikasi-checkin/pages/admin/update_photos_guru_siswa.php',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );
      print("Update Photos Status Code [$type]: ${resp.statusCode}");
      print("Update Photos Response Raw Data [$type]: ${resp.data}");
      if (resp.data == null || resp.data.toString().trim().isEmpty) {
        Fluttertoast.showToast(msg: "[$type] Tidak ada respons dari server.");
        return;
      }
      late Map<String, dynamic> json;
      try {
        json = jsonDecode(resp.data.toString());
      } catch (e) {
        Fluttertoast.showToast(msg: "[$type] Format respon tidak valid.");
        print("🛑 Update Photos JSON Decode Error [$type]: $e");
        return;
      }
      if (json['status'] == 'success') {
        final data = json['data'];
        String successMsg = "✅ Update foto $type berhasil!\n";
        if (data != null) {
          successMsg += "📊 Diproses: ${data['processed']}, ";
          successMsg += "Diupdate: ${data['updated']}, ";
          successMsg += "Tidak ditemukan: ${data['not_found']}";
        }
        Fluttertoast.showToast(msg: successMsg, toastLength: Toast.LENGTH_LONG);
        setState(() {
          if (type == 'guru') {
            zipGuru = null;
            zipGuruName = null;
            hasGuruPhotos = true;
          }
          if (type == 'siswa') {
            zipSiswa = null;
            zipSiswaName = null;
            hasSiswaPhotos = true;
          }
        });
        final prefs = await SharedPreferences.getInstance();
        if (type == 'guru') {
          await prefs.setBool('has_guru_photos', true);
        } else if (type == 'siswa') {
          await prefs.setBool('has_siswa_photos', true);
        }
      } else {
        Fluttertoast.showToast(
          msg: "❌ Update $type gagal: ${json['message']}",
          toastLength: Toast.LENGTH_LONG,
        );
      }
      if (json.containsKey('log')) {
        print("📝 Update Photos Log Backend [$type]:");
        for (var line in json['log']) {
          print("  • $line");
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Update foto $type gagal: $e",
        toastLength: Toast.LENGTH_LONG,
      );
      print("❌ Update Photos Error [$type]: $e");
    }
    setState(() => isUploading = false);
    await checkExistingPhotos();
  }

  Future<void> downloadZip(String type) async {
    setState(() {
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
          'http://10.167.91.233/aplikasi-checkin/pages/admin/download_photos_zip.php?file=$type';
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$type.zip';
      print("🔄 Mencoba download file ZIP: $type");
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
          throw Exception("File ZIP yang didownload kosong");
        }
        final params = SaveFileDialogParams(
          sourceFilePath: tempPath,
          fileName: '$type.zip',
        );
        final savedPath = await FlutterFileDialog.saveFile(params: params);
        if (savedPath != null) {
          Fluttertoast.showToast(
            msg: '✅ Berhasil mengunduh: $type.zip',
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
      String errorMsg = 'Gagal mengunduh ZIP $type: ';
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
      final errorMsg = 'Gagal mengunduh ZIP $type: $e';
      print("❌ General Error: $errorMsg");
      Fluttertoast.showToast(msg: errorMsg, toastLength: Toast.LENGTH_LONG);
    } finally {
      setState(() {
        if (type == 'guru') isDownloadingGuru = false;
        if (type == 'siswa') isDownloadingSiswa = false;
      });
    }
  }

  Widget buildZipTile({
    required String label,
    required File? file,
    required String? lastUploadedName,
    required VoidCallback onPick,
    required VoidCallback onDownload,
    required Color color,
    required IconData icon,
    required bool hasExistingPhotos,
    VoidCallback? onUpdate,
  }) {
    bool isDownloading = false;
    if (label.contains('Guru')) {
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
                if (hasExistingPhotos)
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
                      'Foto sudah ada',
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
                  tooltip: "Pilih File ZIP",
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
                  tooltip: "Unduh Template ZIP",
                  color: isDownloading ? Colors.grey : Colors.blue,
                ),
              ],
            ),
          ),
          if (hasExistingPhotos && onUpdate != null && file != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isUploading || isDownloading) ? null : onUpdate,
                  icon: const Icon(Icons.update, size: 18),
                  label: Text('Update Foto ${label.split(' ')[1]}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (isUploading || isDownloading)
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
            icon: const Icon(Icons.bug_report),
            onPressed: debugPhotosStatusCheck,
            tooltip: "Debug Photos Status Check",
          ),
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
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 80,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Kelola Foto Guru & Siswa",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'TitilliumWeb',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Upload foto awal atau update foto yang sudah ada.\nFile ZIP berisi foto sesuai nama di database.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 20),
                buildZipTile(
                  label: 'Foto Guru (.zip)',
                  file: zipGuru,
                  lastUploadedName: zipGuruName,
                  onPick: () => pickZip('guru'),
                  onDownload: () => downloadZip('guru'),
                  icon: Icons.person,
                  color: Colors.indigo,
                  hasExistingPhotos: hasGuruPhotos,
                  onUpdate: () => updatePhotos('guru'),
                ),
                buildZipTile(
                  label: 'Foto Siswa (.zip)',
                  file: zipSiswa,
                  lastUploadedName: zipSiswaName,
                  onPick: () => pickZip('siswa'),
                  onDownload: () => downloadZip('siswa'),
                  icon: Icons.group,
                  color: Colors.deepPurple,
                  hasExistingPhotos: hasSiswaPhotos,
                  onUpdate: () => updatePhotos('siswa'),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                    hasGuruPhotos || hasSiswaPhotos
                        ? "Proses Semua Foto (Update)"
                        : "Proses Semua Foto (Import Awal)",
                  ),
                  onPressed: isUploading ? null : uploadAll,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (isUploading)
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
