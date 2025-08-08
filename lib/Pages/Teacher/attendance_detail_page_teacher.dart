import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:intl/intl.dart';

class AttendanceDetailPageTeacher extends StatefulWidget {
  final String kelas;
  final String mataPelajaran;
  final int idPresensiKelas;
  final int pertemuanKe;
  final String tanggal;
  final String jam;
  final String semester;
  final String prodi;
  const AttendanceDetailPageTeacher({
    Key? key,
    required this.kelas,
    required this.mataPelajaran,
    required this.idPresensiKelas,
    required this.pertemuanKe,
    required this.tanggal,
    required this.jam,
    required this.semester,
    required this.prodi,
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
  Map<int, List<Map<String, dynamic>>> faceRecognitionData = {};
  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
    fetchFaceRecognitionData();
  }

  Future<void> fetchFaceRecognitionData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/api/get_face_recognition_by_class.php?id_presensi_kelas=${widget.idPresensiKelas}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            final List<dynamic> faceData = data['data'];
            faceRecognitionData.clear();
            for (var studentData in faceData) {
              final int idSiswa = studentData['student_info']['id_siswa'];
              final List<Map<String, dynamic>> detections =
                  List<Map<String, dynamic>>.from(
                    studentData['face_detections'],
                  );
              faceRecognitionData[idSiswa] = detections;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching face recognition data: $e');
    }
  }

  Future<void> fetchAttendanceData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/get_detail_presensi_guru.php?id_presensi_kelas=${widget.idPresensiKelas}',
        ),
      );
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          if (mounted) {
            setState(() {
              siswaList = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        } else {
          _showErrorDialog(data['message'] ?? 'Gagal memuat data presensi.');
        }
      } else {
        _showErrorDialog('Gagal menghubungi server.');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan koneksi: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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
          'http://10.167.91.233/aplikasi-checkin/pages/guru/edit_presensi_siswa.php',
        ),
        body: {
          'id_presensi_detail': idPresensiDetail.toString(),
          'status': status,
          if (status == 'Tidak Hadir' && keterangan != null)
            'keterangan': keterangan,
        },
      );
      final data = json.decode(response.body);
      if (data['status'] == true) {
        _showToast(data['message'] ?? 'Status berhasil diperbarui');
        await fetchAttendanceData();
      } else {
        _showErrorDialog(data['message'] ?? 'Gagal memperbarui status');
      }
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan saat memperbarui data!');
    }
    setState(() => isUpdating = false);
  }

  void _editStatusDialog(Map<String, dynamic> siswa) async {
    String selectedStatus = (siswa['status'] ?? 'Hadir').toString();
    String selectedKeterangan = (siswa['keterangan'] ?? '').toString();
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
                    isExpanded: true,
                    value:
                        ['Hadir', 'Tidak Hadir'].contains(selectedStatus)
                            ? selectedStatus
                            : 'Hadir',
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
                      if (value != null) {
                        setDialogState(() {
                          selectedStatus = value;
                          if (value == 'Hadir') selectedKeterangan = '';
                        });
                      }
                    },
                  ),
                  if (selectedStatus == 'Tidak Hadir')
                    DropdownButton<String>(
                      isExpanded: true,
                      value:
                          [
                                'Sakit',
                                'Izin',
                                'Tanpa Keterangan',
                              ].contains(selectedKeterangan)
                              ? selectedKeterangan
                              : null,
                      hint: const Text('Pilih Keterangan'),
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
                        if (value != null) {
                          setDialogState(() {
                            selectedKeterangan = value;
                          });
                        }
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
                    if (selectedStatus == 'Tidak Hadir' &&
                        ![
                          'Sakit',
                          'Izin',
                          'Tanpa Keterangan',
                        ].contains(selectedKeterangan)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Keterangan wajib diisi jika status Tidak Hadir.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
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

  void _showFaceRecognitionDialog(Map<String, dynamic> siswa) {
    final idSiswa = siswa['id_siswa'];
    final faceDetections = faceRecognitionData[idSiswa] ?? [];
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          siswa['foto']?.toString() ??
                              'http://10.167.91.233/aplikasi-checkin/uploads/siswa/default.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              siswa['nama_lengkap'] ?? 'Nama Siswa',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Hasil Face Recognition (${faceDetections.length})',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      faceDetections.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.face_retouching_natural,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada deteksi wajah',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: faceDetections.length,
                            itemBuilder: (context, index) {
                              final detection = faceDetections[index];
                              return _buildFaceDetectionCard(detection);
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceDetectionCard(Map<String, dynamic> detection) {
    final similarity = detection['similarity'] ?? 0.0;
    final statusDeteksi = detection['status_deteksi'] ?? 'dikenali';
    final waktu = detection['waktu'] ?? '';
    final fotoPath = detection['foto_path'] ?? '';
    print('Building face card for foto_path: $fotoPath');
    String formattedTime = '';
    if (waktu.isNotEmpty) {
      try {
        final DateTime dateTime = DateTime.parse(waktu);
        formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
      } catch (e) {
        formattedTime = waktu;
      }
    }
    Color cardColor;
    IconData statusIcon;
    String statusText;
    if (statusDeteksi == 'dikenali' && similarity > 70) {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Wajah Dikenali';
    } else {
      cardColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Wajah Tidak Dikenali';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: cardColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${similarity.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (fotoPath.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _showDetailImageDialog(detection),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildFaceImage(fotoPath),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  formattedTime,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Tap foto',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailImageDialog(Map<String, dynamic> detection) {
    final fotoPath = detection['foto_path'] ?? '';
    final similarity = detection['similarity'] ?? 0.0;
    final waktu = detection['waktu'] ?? '';
    final statusDeteksi = detection['status_deteksi'] ?? 'dikenali';
    print('Showing detail dialog for foto_path: $fotoPath');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        statusDeteksi == 'dikenali'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusDeteksi == 'dikenali'
                            ? Icons.check_circle
                            : Icons.warning,
                        color:
                            statusDeteksi == 'dikenali'
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Detail Foto Face Recognition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildLargeFaceImage(fotoPath),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Similarity: ${similarity.toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_formatDateTime(waktu))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFaceImage(String fotoPath) {
    if (fotoPath.isEmpty) {
      print('Empty foto_path provided');
      return Container(
        color: Theme.of(context).cardColor,
        child: Icon(
          Icons.image_not_supported,
          color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
          size: 32,
        ),
      );
    }
    final String imageUrl =
        'http://10.167.91.233/aplikasi-checkin/api/get_face_recognition_image.php?foto_path=${Uri.encodeQueryComponent(fotoPath)}';
    print('=== IMAGE LOADING DEBUG ===');
    print('Original foto_path: "$fotoPath"');
    print('Encoded image URL: $imageUrl');
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('✅ Image loaded successfully for: $fotoPath');
          return child;
        }
        final progress =
            loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null;
        print('⏳ Loading image progress: ${(progress ?? 0) * 100}%');
        return Center(
          child: CircularProgressIndicator(value: progress, strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('❌ Error loading image for "$fotoPath"');
        print('Error details: $error');
        print('Image URL was: $imageUrl');
        return Container(
          color: Theme.of(context).cardColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Gagal memuat',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 8,
                ),
              ),
              Text(
                'Tap untuk retry',
                style: TextStyle(color: Colors.blue[600], fontSize: 8),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLargeFaceImage(String fotoPath) {
    if (fotoPath.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Theme.of(context).cardColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Foto tidak tersedia',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final String imageUrl =
        'http://10.167.91.233/aplikasi-checkin/api/get_face_recognition_image.php?foto_path=${Uri.encodeQueryComponent(fotoPath)}';
    print('Loading large image from URL: $imageUrl');
    return Image.network(
      imageUrl,
      width: double.infinity,
      height: 200,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          print('Large image loaded successfully for: $fotoPath');
          return child;
        }
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading large image for $fotoPath: $error');
        return Container(
          height: 200,
          color: Theme.of(context).cardColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Foto tidak dapat dimuat',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String waktu) {
    if (waktu.isEmpty) return 'Tidak tersedia';
    try {
      final DateTime dateTime = DateTime.parse(waktu);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dateTime);
    } catch (e) {
      return waktu;
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Kesalahan'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Map<String, dynamic> _getStatusInfo(Map<String, dynamic> siswa) {
    final status = siswa['status']?.toString() ?? 'Belum Diisi';
    final keterangan = siswa['keterangan']?.toString() ?? '';
    switch (status) {
      case 'Hadir':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'text': 'Hadir',
        };
      case 'Tidak Hadir':
        switch (keterangan) {
          case 'Sakit':
            return {
              'icon': Icons.local_hospital,
              'color': Colors.orange,
              'text': 'Sakit',
            };
          case 'Izin':
            return {'icon': Icons.mail, 'color': Colors.blue, 'text': 'Izin'};
          default:
            return {
              'icon': Icons.cancel,
              'color': Colors.red,
              'text': 'Tanpa Keterangan',
            };
        }
      default:
        return {
          'icon': Icons.hourglass_empty,
          'color': Colors.grey,
          'text': 'Belum Diisi',
        };
    }
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Pertemuan ke-${widget.pertemuanKe}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                widget.mataPelajaran,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            _buildHeaderInfo(
              Icons.school,
              'Prodi: ${widget.prodi}',
              Colors.indigo[600]!,
            ),
            _buildHeaderInfo(
              Icons.class_,
              'Kelas: ${widget.kelas}',
              Colors.teal[600]!,
            ),
            _buildHeaderInfo(
              Icons.timelapse,
              'Semester: ${widget.semester}',
              Colors.purple[500]!,
            ),
            _buildHeaderInfo(
              Icons.calendar_today,
              widget.tanggal,
              Colors.blue[600]!,
            ),
            _buildHeaderInfo(
              Icons.access_time,
              widget.jam,
              Colors.deepOrange[500]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(IconData icon, String text, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 15)),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await fetchAttendanceData();
                  await fetchFaceRecognitionData();
                },
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildHeaderCard(),
                    Expanded(
                      child:
                          siswaList.isEmpty
                              ? const Center(
                                child: Text('Belum ada data presensi siswa.'),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                itemCount: siswaList.length,
                                itemBuilder: (context, index) {
                                  final siswa = siswaList[index];
                                  final fotoUrl =
                                      siswa['foto']?.toString() ??
                                      'http://10.167.91.233/aplikasi-checkin/uploads/siswa/default.png';
                                  final statusInfo = _getStatusInfo(siswa);
                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 16,
                                          ),
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 15,
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${siswa['no_absen'] ?? '-'}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 25,
                                                backgroundImage: NetworkImage(
                                                  fotoUrl,
                                                ),
                                                onBackgroundImageError:
                                                    (_, __) {},
                                              ),
                                              if (faceRecognitionData
                                                  .containsKey(
                                                    siswa['id_siswa'],
                                                  ))
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.face,
                                                      size: 10,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              siswa['nama_lengkap'] ??
                                                  'Nama Siswa',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            siswa['jenis_kelamin'] == 'L'
                                                ? Icons.male
                                                : Icons.female,
                                            color:
                                                siswa['jenis_kelamin'] == 'L'
                                                    ? Colors.blue
                                                    : Colors.pink,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            siswa['email'] ?? 'Tidak ada email',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                statusInfo['icon'],
                                                color: statusInfo['color'],
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  statusInfo['text'],
                                                  style: TextStyle(
                                                    color: statusInfo['color'],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (faceRecognitionData.containsKey(
                                            siswa['id_siswa'],
                                          ))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .face_retouching_natural,
                                                    color: Colors.indigo,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      '${faceRecognitionData[siswa['id_siswa']]!.length} deteksi wajah',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.indigo,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                          if (faceRecognitionData.containsKey(
                                            siswa['id_siswa'],
                                          ))
                                            IconButton(
                                              icon: const Icon(
                                                Icons.face_retouching_natural,
                                                color: Colors.indigo,
                                                size: 20,
                                              ),
                                              onPressed:
                                                  () =>
                                                      _showFaceRecognitionDialog(
                                                        siswa,
                                                      ),
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                            ),
                                            onPressed:
                                                () => _editStatusDialog(siswa),
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
