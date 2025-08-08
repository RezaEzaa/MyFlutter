import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> faceRecognitionData = [];
  bool isFaceDataLoading = false;
  @override
  void initState() {
    super.initState();
    fetchDetailData();
    // fetchFaceRecognitionData(); // Dihapus dari sini, akan dipanggil setelah detail data berhasil dimuat
  }

  Future<void> fetchDetailData() async {
    setState(() => isLoading = true);
    try {
      final idPresensiSiswa = widget.presensi['id'] ?? '';
      print('=== FETCH DETAIL DATA START ===');
      print('ID Presensi Siswa: $idPresensiSiswa');

      final response = await http.get(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/siswa/get_detail_presensi_siswa.php?id_presensi_siswa=$idPresensiSiswa',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            detailData = data['data'];
          });
          print('✅ Detail data loaded successfully');
          print('Detail ID: ${detailData!['detail_id']}');
          print('Pertemuan: ${detailData!['pertemuan']}');

          _showSuccessToast('Data presensi berhasil dimuat.');

          // Setelah detail data berhasil dimuat, ambil data face recognition
          print('📱 Starting face recognition data fetch...');
          await fetchFaceRecognitionData();
        } else {
          setState(() {
            detailData = null;
          });
          _showErrorDialog(data['message'] ?? 'Data presensi tidak ditemukan.');
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
      print('=== FETCH DETAIL DATA END ===');
    }
  }

  Future<void> fetchFaceRecognitionData() async {
    setState(() => isFaceDataLoading = true);
    try {
      final idFromWidget = widget.presensi['id']?.toString() ?? '';
      print('=== FETCH FACE RECOGNITION DEBUG ===');
      print('Widget presensi data: ${widget.presensi}');
      print('Original ID from widget: $idFromWidget');

      if (idFromWidget.isEmpty) {
        print('ERROR: ID from widget is empty!');
        setState(() {
          faceRecognitionData = [];
        });
        return;
      }

      // Step 1: Get detail data to obtain detail_id if available
      String finalId = idFromWidget;
      String idType = 'unknown';

      if (detailData != null && detailData!['detail_id'] != null) {
        finalId = detailData!['detail_id'].toString();
        idType = 'detail_id';
        print('✅ Using detail_id from detailData: $finalId');
      } else {
        idType = 'presensi_siswa_id';
        print('⚠️ Using original ID as presensi_siswa_id: $finalId');
      }

      // Step 2: Get debug info to understand the data structure
      await _fetchDebugInfo();

      // Step 3: Build API URL with smart ID detection
      final apiUrl =
          'http://10.167.91.233/aplikasi-checkin/api/get_face_recognition_data.php?id_presensi_siswa=$finalId';
      print('API URL: $apiUrl');
      print('ID Type: $idType');

      final response = await http.get(Uri.parse(apiUrl));
      print('Face recognition API response status: ${response.statusCode}');
      print('Face recognition API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed face recognition data: $data');

        // Log backend detection info
        if (data['debug_info'] != null) {
          final debugInfo = data['debug_info'];
          print('🔍 Backend Detection:');
          print('  - Detected as: ${debugInfo['detected_as'] ?? 'unknown'}');
          print('  - Lookup method: ${data['lookup_method'] ?? 'unknown'}');
          print('  - Lookup value: ${data['lookup_value'] ?? 'unknown'}');
        }

        if (data['status'] == true && data['data'] != null) {
          final List<Map<String, dynamic>> faceData =
              List<Map<String, dynamic>>.from(data['data']);

          // Filter face recognition data berdasarkan pertemuan yang sesuai
          final currentPertemuan =
              detailData?['pertemuan']?.toString() ??
              widget.presensi['pertemuan']?.toString() ??
              '';

          print('🔍 Filtering face recognition data...');
          print('Current pertemuan: $currentPertemuan');
          print('Total records from server: ${faceData.length}');

          List<Map<String, dynamic>> filteredFaceData = [];

          if (currentPertemuan.isNotEmpty) {
            // Filter berdasarkan pertemuan yang sama
            for (var face in faceData) {
              final facePertemuan = face['pertemuan']?.toString() ?? '';
              final matchType = face['match_type'] ?? 'UNKNOWN_MATCH';

              print('Checking face record:');
              print('  - Face pertemuan: $facePertemuan');
              print('  - Current pertemuan: $currentPertemuan');
              print('  - Match type: $matchType');
              print('  - foto_path: ${face['foto_path'] ?? ''}');

              // Hanya tampilkan foto yang benar-benar dari pertemuan yang sama
              // EXACT_MATCH = pertemuan, tanggal, dan siswa sama
              if (matchType == 'EXACT_MATCH' &&
                  facePertemuan == currentPertemuan) {
                filteredFaceData.add(face);
                print('  ✅ INCLUDED (Exact match for current meeting)');
              } else if (matchType == 'DATE_MATCH' &&
                  facePertemuan == currentPertemuan) {
                filteredFaceData.add(face);
                print('  ✅ INCLUDED (Date match for current meeting)');
              } else {
                print(
                  '  ❌ EXCLUDED (Wrong meeting: $facePertemuan vs $currentPertemuan)',
                );
              }
            }
          } else {
            // Jika pertemuan tidak diketahui, tampilkan semua dengan prioritas EXACT_MATCH
            filteredFaceData =
                faceData
                    .where((face) => face['match_type'] == 'EXACT_MATCH')
                    .toList();
            print(
              '⚠️ No current meeting info, showing only EXACT_MATCH records',
            );
          }

          setState(() {
            faceRecognitionData = filteredFaceData;
          });

          print('✅ Face recognition data filtered and loaded:');
          print('  - Original records: ${faceData.length}');
          print('  - Filtered records: ${filteredFaceData.length}');
          print('  - Current pertemuan: $currentPertemuan');

          // Log filtered records
          for (int i = 0; i < filteredFaceData.length; i++) {
            final record = filteredFaceData[i];
            print(
              'Filtered Record $i (${record['match_type'] ?? 'UNKNOWN_MATCH'}):',
            );
            print('  - foto_path: "${record['foto_path'] ?? ''}"');
            print('  - similarity: ${record['similarity'] ?? 0}%');
            print('  - pertemuan: ${record['pertemuan'] ?? 'N/A'}');
            print('  - tanggal: ${record['tanggal'] ?? 'N/A'}');
          }

          if (filteredFaceData.isNotEmpty) {
            final matchTypes =
                filteredFaceData
                    .map((item) => item['match_type'] ?? 'UNKNOWN')
                    .toSet();
            _showSuccessToast(
              'Ditemukan ${filteredFaceData.length} hasil deteksi wajah untuk pertemuan $currentPertemuan (${matchTypes.join(', ')})',
            );
          } else if (faceData.isNotEmpty) {
            _showErrorToast(
              'Tidak ada data face recognition untuk pertemuan $currentPertemuan (ditemukan ${faceData.length} data dari pertemuan lain)',
            );
          }
        } else {
          setState(() {
            faceRecognitionData = [];
          });
          print('❌ No face recognition data found');
          print('API message: ${data['message'] ?? 'No message'}');
          print('Server response: ${data['status']}');

          // Show more specific error message based on backend response
          final message =
              data['message'] ?? 'Data face recognition tidak ditemukan';
          if (message.contains('tidak ditemukan')) {
            _showErrorToast(
              'Data face recognition tidak tersedia untuk presensi ini',
            );
          } else {
            _showErrorToast(message);
          }
        }
      } else {
        setState(() {
          faceRecognitionData = [];
        });
        print('❌ HTTP Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        _showErrorToast(
          'Gagal mengambil data face recognition (HTTP ${response.statusCode})',
        );
      }
    } catch (e, stackTrace) {
      setState(() {
        faceRecognitionData = [];
      });
      print('❌ Error fetching face recognition data: $e');
      print('Stack trace: $stackTrace');
      _showErrorToast('Terjadi kesalahan saat mengambil data face recognition');
    } finally {
      setState(() => isFaceDataLoading = false);
      print('=== END FETCH FACE RECOGNITION DEBUG ===');
    }
  }

  Future<void> _fetchDebugInfo() async {
    try {
      final debugUrl =
          'http://10.167.91.233/aplikasi-checkin/api/debug_face_recognition.php';
      print('Fetching debug info from: $debugUrl');

      final debugResponse = await http.get(Uri.parse(debugUrl));
      if (debugResponse.statusCode == 200) {
        final debugData = json.decode(debugResponse.body);
        if (debugData['status'] == true && debugData['debug_info'] != null) {
          final debugInfo = debugData['debug_info'];

          print('=== DEBUG INFO FROM SERVER ===');
          print('Server time: ${debugInfo['server_time']}');
          print('Working detail IDs: ${debugInfo['working_detail_ids']}');

          if (debugInfo['issue_summary'] != null) {
            final issueSummary = debugInfo['issue_summary'];
            print('Issue Summary:');
            print(
              '  - Total cross issues: ${issueSummary['total_cross_issues']}',
            );
            print('  - Valid matches: ${issueSummary['valid_matches']}');
            print('  - Invalid matches: ${issueSummary['invalid_matches']}');
          }

          // Log cross-meeting issues if any
          if (debugInfo['cross_meeting_issues'] != null) {
            final crossIssues = debugInfo['cross_meeting_issues'] as List;
            if (crossIssues.isNotEmpty) {
              print('⚠️ Cross-meeting issues detected:');
              for (var issue in crossIssues) {
                print(
                  '  - Face ID ${issue['face_id']}: pertemuan ${issue['face_pertemuan']} vs ${issue['detail_pertemuan']}',
                );
              }
            }
          }
          print('=== END DEBUG INFO ===');
        }
      }
    } catch (e) {
      print('Debug info fetch failed (continuing normally): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelas = detailData?['kelas'] ?? widget.presensi['kelas'] ?? '';
    final prodi = detailData?['prodi'] ?? widget.presensi['prodi'] ?? '';
    final semester =
        detailData?['semester'] ?? widget.presensi['semester'] ?? '';
    final mataPelajaran =
        detailData?['mata_pelajaran'] ??
        widget.presensi['mata_pelajaran'] ??
        '';
    final namaLengkap = detailData?['nama_lengkap'] ?? '';
    final jenisKelamin = detailData?['jenis_kelamin'] ?? '';
    final foto =
        detailData?['foto'] ??
        'http://10.167.91.233/aplikasi-checkin/uploads/siswa/default.png';
    final status = (detailData?['status'] ?? '').toString();
    final keterangan = detailData?['keterangan'] ?? '';
    final statusManual = detailData?['status_manual'] ?? 0;
    final pertemuan =
        detailData?['pertemuan']?.toString() ??
        widget.presensi['pertemuan']?.toString() ??
        '';
    final tanggal = detailData?['tanggal'] ?? widget.presensi['tanggal'] ?? '';
    final jam = detailData?['jam'] ?? widget.presensi['jam'] ?? '';
    final presensiStatus = widget.presensi['status'] ?? '';
    final attendanceStatus = status.toLowerCase();
    IconData statusIcon;
    Color statusColor;
    String statusText;
    if (presensiStatus == 'belum') {
      statusIcon = Icons.info_outline;
      statusColor = Colors.orange;
      statusText = 'Presensi Belum Dimulai';
    } else if (presensiStatus == 'aktif') {
      statusIcon = Icons.remove_circle;
      statusColor = Colors.blue;
      statusText = 'Presensi Aktif';
    } else if (presensiStatus == 'selesai') {
      if (attendanceStatus == 'hadir') {
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = 'Status: Hadir';
      } else if (attendanceStatus == 'tidak hadir') {
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = 'Status: Tidak Hadir';
      } else {
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
        statusText = 'Status: Belum Diketahui';
      }
    } else {
      statusIcon = Icons.help_outline;
      statusColor = Colors.grey;
      statusText = 'Status tidak diketahui';
    }
    String formattedTanggal = tanggal;
    try {
      if (tanggal.isNotEmpty) {
        final parsedDate = DateTime.parse(tanggal);
        formattedTanggal = DateFormat(
          'dd MMMM yyyy',
          'id_ID',
        ).format(parsedDate);
      }
    } catch (e) {}
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
              : detailData == null
              ? const Center(child: Text('Data presensi tidak ditemukan.'))
              : RefreshIndicator(
                onRefresh: () async {
                  await fetchDetailData();
                  await fetchFaceRecognitionData();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Detail Presensi',
                                style: TextStyle(
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
                                  onBackgroundImageError: (_, __) {},
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    namaLengkap,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.class_, color: Colors.teal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Kelas: $kelas',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            if (prodi.isNotEmpty && prodi != '0')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      color: Colors.indigo,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Prodi: $prodi',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.timelapse,
                                  color: Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Semester: $semester',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.book, color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Mata Pelajaran: $mataPelajaran',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.date_range,
                                  color: Colors.deepOrange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pertemuan: $pertemuan',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.event, color: Colors.blueGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tanggal: $formattedTanggal',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jam: $jam',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (statusManual == 1)
                                    Tooltip(
                                      message:
                                          'Status ditetapkan manual oleh guru',
                                      child: Icon(
                                        Icons.edit,
                                        color: statusColor,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (presensiStatus == 'selesai' &&
                                attendanceStatus == 'tidak hadir' &&
                                keterangan.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.redAccent.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info,
                                        color: Colors.redAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Keterangan: $keterangan',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (statusManual == 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Status presensi ini ditetapkan secara manual oleh guru',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (faceRecognitionData.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.face_retouching_natural,
                                          color: Colors.indigo,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Hasil Deteksi Wajah (${faceRecognitionData.length})',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ...faceRecognitionData
                                        .map(
                                          (faceData) =>
                                              _buildFaceRecognitionCard(
                                                faceData,
                                              ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            // Loading indicator untuk face recognition data
                            if (isFaceDataLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Column(
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.face_retouching_natural,
                                          color: Colors.indigo,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Memuat data face recognition...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildFaceRecognitionCard(Map<String, dynamic> faceData) {
    final similarity = faceData['similarity'] ?? 0.0;
    final statusDeteksi = faceData['status_deteksi'] ?? 'dikenali';
    final waktu = faceData['waktu'] ?? '';
    final fotoPath = faceData['foto_path'] ?? '';
    final matchType = faceData['match_type'] ?? 'UNKNOWN_MATCH';
    final pertemuan = faceData['pertemuan']?.toString() ?? '';

    print('Building face card for foto_path: $fotoPath (Match: $matchType)');

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
    Color matchTypeColor;

    if (statusDeteksi == 'dikenali' && similarity > 70) {
      cardColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Wajah Dikenali';
    } else {
      cardColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Wajah Tidak Dikenali';
    }

    // Determine match type color and info
    switch (matchType) {
      case 'EXACT_MATCH':
        matchTypeColor = Colors.green;
        break;
      case 'DATE_MATCH':
        matchTypeColor = Colors.blue;
        break;
      case 'STUDENT_MATCH':
        matchTypeColor = Colors.orange;
        break;
      default:
        matchTypeColor = Colors.grey;
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

              // Match type indicator
              if (matchType != 'UNKNOWN_MATCH')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: matchTypeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: matchTypeColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getMatchTypeText(matchType),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: matchTypeColor,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              if (fotoPath.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: cardColor.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildFaceImage(fotoPath),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Waktu: $formattedTime',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.analytics,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Akurasi: ${similarity.toStringAsFixed(2)}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (pertemuan.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_note,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Pertemuan: $pertemuan',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFaceRecognitionDialog(faceData),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
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
                                  Text(
                                    'Lihat Detail',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
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

  void _showFaceRecognitionDialog(Map<String, dynamic> faceData) {
    final fotoPath = faceData['foto_path'] ?? '';
    final similarity = faceData['similarity'] ?? 0.0;
    final waktu = faceData['waktu'] ?? '';
    final statusDeteksi = faceData['status_deteksi'] ?? 'dikenali';
    final matchType = faceData['match_type'] ?? 'UNKNOWN_MATCH';
    final pertemuan = faceData['pertemuan']?.toString() ?? '';
    final tanggal = faceData['tanggal'] ?? '';
    final kelas = faceData['kelas'] ?? '';

    print('Showing dialog for foto_path: $fotoPath (Match: $matchType)');

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
                          'Detail Hasil Face Recognition',
                          style: TextStyle(
                            fontSize: 18,
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Tingkat Akurasi: ${similarity.toStringAsFixed(2)}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Waktu Deteksi: ${_formatDateTime(waktu)}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  statusDeteksi == 'dikenali'
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  size: 16,
                                  color:
                                      statusDeteksi == 'dikenali'
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${statusDeteksi == 'dikenali' ? 'Wajah Dikenali' : 'Wajah Tidak Dikenali'}',
                                  style: TextStyle(
                                    color:
                                        statusDeteksi == 'dikenali'
                                            ? Colors.green
                                            : Colors.orange,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (matchType != 'UNKNOWN_MATCH') ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _getMatchTypeIcon(matchType),
                                    size: 16,
                                    color: _getMatchTypeColor(matchType),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tipe Match: ${_getMatchTypeText(matchType)}',
                                    style: TextStyle(
                                      color: _getMatchTypeColor(matchType),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (pertemuan.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event_note, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Pertemuan: $pertemuan'),
                                ],
                              ),
                            ],
                            if (tanggal.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Tanggal: $tanggal'),
                                ],
                              ),
                            ],
                            if (kelas.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.class_, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Kelas: $kelas'),
                                ],
                              ),
                            ],
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

  String _getMatchTypeText(String matchType) {
    switch (matchType) {
      case 'EXACT_MATCH':
        return 'Exact Match';
      case 'DATE_MATCH':
        return 'Date Match';
      case 'STUDENT_MATCH':
        return 'Student Match';
      default:
        return 'Unknown Match';
    }
  }

  Color _getMatchTypeColor(String matchType) {
    switch (matchType) {
      case 'EXACT_MATCH':
        return Colors.green;
      case 'DATE_MATCH':
        return Colors.blue;
      case 'STUDENT_MATCH':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMatchTypeIcon(String matchType) {
    switch (matchType) {
      case 'EXACT_MATCH':
        return Icons.check_circle;
      case 'DATE_MATCH':
        return Icons.calendar_today;
      case 'STUDENT_MATCH':
        return Icons.person;
      default:
        return Icons.help_outline;
    }
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

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
