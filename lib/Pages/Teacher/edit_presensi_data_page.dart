import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checkin/Pages/settings_page.dart';

class EditPresensiDataPage extends StatefulWidget {
  final String kelas;
  final String mataPelajaran;
  final String prodi;
  const EditPresensiDataPage({
    Key? key,
    required this.kelas,
    required this.mataPelajaran,
    required this.prodi,
  }) : super(key: key);
  @override
  State<EditPresensiDataPage> createState() => _EditPresensiDataPageState();
}

class _EditPresensiDataPageState extends State<EditPresensiDataPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? guruEmail;
  late TextEditingController _mataPelajaranController;
  late TextEditingController _kelasController;
  late TextEditingController _prodiController;
  late String _mataPelajaranLama;
  late String _kelasLama;
  late String _prodiLama;
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadGuruEmail();
  }

  void _initializeControllers() {
    _mataPelajaranLama = widget.mataPelajaran;
    _kelasLama = widget.kelas;
    _prodiLama = widget.prodi;
    _mataPelajaranController = TextEditingController(
      text: widget.mataPelajaran,
    );
    _kelasController = TextEditingController(text: widget.kelas);
    _prodiController = TextEditingController(text: widget.prodi);
  }

  Future<void> _loadGuruEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      guruEmail = prefs.getString('guru_email');
    });
  }

  @override
  void dispose() {
    _mataPelajaranController.dispose();
    _kelasController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  Future<void> _updatePresensiData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => isLoading = true);
    try {
      final updateData = {
        'mata_pelajaran_lama': _mataPelajaranLama,
        'kelas_lama': _kelasLama,
        'prodi_lama': _prodiLama,
        'mata_pelajaran_baru': _mataPelajaranController.text.trim(),
        'kelas_baru': _kelasController.text.trim(),
        'prodi_baru': _prodiController.text.trim(),
      };
      debugPrint('📤 Mengirim request edit data presensi:');
      updateData.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      final response = await http.post(
        Uri.parse(
          'http://10.167.91.233/aplikasi-checkin/pages/guru/edit_presensi_kelas.php',
        ),
        body: updateData,
      );
      debugPrint('📥 Response status code: ${response.statusCode}');
      debugPrint('📥 Response body: ${response.body}');
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true) {
          debugPrint('✅ SUKSES: ${responseData['message']}');
          if (responseData['updated'] != null) {
            debugPrint('📊 Detail update berhasil:');
            responseData['updated'].forEach((key, value) {
              debugPrint('  $key: $value');
            });
          }
          _showToast('Data presensi berhasil diperbarui');
          Navigator.of(context).pop(true);
        } else {
          debugPrint('❌ ERROR: ${responseData['message']}');
          _showErrorDialog(
            responseData['message'] ?? 'Gagal memperbarui data presensi',
          );
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ EXCEPTION: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showToast(String message) {
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
      builder:
          (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('asset/images/logo.png', width: 120, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
          ),
        ],
      ),
      body: Container(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [Colors.blue[100]!, Colors.blue[50]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_note,
                                color: Colors.blue[800],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Data Presensi',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mata Pelajaran: ${widget.mataPelajaran}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Fitur ini memungkinkan Anda mengedit data metadata presensi seperti nama mata pelajaran, email guru, kelas, dan program studi untuk mengatasi kesalahan input data.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildFormField(
                  controller: _mataPelajaranController,
                  label: 'Mata Pelajaran',
                  icon: Icons.book,
                  hint: 'Masukkan nama mata pelajaran',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Mata pelajaran tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _kelasController,
                  label: 'Kelas',
                  icon: Icons.class_,
                  hint: 'X, XI, XII, dst.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kelas tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _prodiController,
                  label: 'Program Studi',
                  icon: Icons.school,
                  hint: 'Masukkan nama program studi',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Program studi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _updatePresensiData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue[700], size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[500]!, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                filled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
