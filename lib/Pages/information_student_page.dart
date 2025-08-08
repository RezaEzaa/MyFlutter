import 'package:flutter/material.dart';
class InformationStudentPage extends StatelessWidget {
  const InformationStudentPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Dashboard Siswa'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.school, size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Dashboard Siswa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'TitilliumWeb',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Panduan Penggunaan Aplikasi untuk Siswa',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontFamily: 'TitilliumWeb',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const StudentFeatureCard(
              icon: Icons.account_circle,
              title: 'Profil Siswa',
              description: 'Kelola informasi profil dan akun pribadi',
              features: [
                '• Lihat informasi profil lengkap (nama, kelas, NIS)',
                '• Edit data pribadi dan informasi kontak',
                '• Update foto profil untuk face recognition',
                '• Ubah password akun dengan validasi keamanan',
                '• Logout dengan konfirmasi',
                '• Sinkronisasi otomatis data dengan server',
              ],
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.face_retouching_natural,
                        color: Colors.indigo,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cara Melakukan Presensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TitilliumWeb',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '🎯 Presensi Otomatis dengan Face Recognition:\n'
                    '• Guru akan mengaktifkan presensi untuk kelas Anda\n'
                    '• Anda akan menerima notifikasi saat presensi aktif\n'
                    '• Buka aplikasi dan arahkan wajah ke kamera\n'
                    '• Sistem akan mengenali wajah Anda secara otomatis\n'
                    '• Status kehadiran akan tercatat dalam sistem\n'
                    '• Cek riwayat presensi untuk konfirmasi',
                    style: TextStyle(fontSize: 14, fontFamily: 'TitilliumWeb'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const StudentFeatureCard(
              icon: Icons.history,
              title: 'Riwayat Presensi',
              description: 'Monitor riwayat kehadiran pribadi secara detail',
              features: [
                '• Lihat riwayat presensi harian dengan detail waktu',
                '• Filter berdasarkan tanggal, semester, dan mata pelajaran',
                '• Expand/collapse view untuk navigasi mudah',
                '• Status kehadiran lengkap (hadir, izin, sakit, alfa)',
                '• Detail keterangan untuk setiap ketidakhadiran',
                '• Statistik kehadiran bulanan dan semesteran',
                '• Refresh manual untuk update data terbaru',
              ],
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Tips Penggunaan Aplikasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TitilliumWeb',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '💡 Tips untuk Siswa:\n'
                    '• Pastikan foto profil Anda jelas untuk face recognition\n'
                    '• Selalu aktifkan notifikasi untuk tidak melewatkan presensi\n'
                    '• Gunakan pencahayaan yang baik saat presensi\n'
                    '• Periksa riwayat presensi secara berkala\n'
                    '• Laporkan masalah teknis kepada guru atau admin\n'
                    '• Update data profil jika ada perubahan',
                    style: TextStyle(fontSize: 14, fontFamily: 'TitilliumWeb'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.purple, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Cara Presensi yang Benar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'TitilliumWeb',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '📷 Langkah-langkah Face Recognition:\n'
                    '1. Pastikan wajah terlihat jelas di kamera\n'
                    '2. Hindari pencahayaan yang terlalu terang/gelap\n'
                    '3. Jangan memakai masker saat face scan\n'
                    '4. Posisikan wajah di tengah frame kamera\n'
                    '5. Tunggu hingga verifikasi berhasil\n'
                    '6. Check in saat tiba, check out saat pulang',
                    style: TextStyle(fontSize: 14, fontFamily: 'TitilliumWeb'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class StudentFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  const StudentFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'TitilliumWeb',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                feature,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'TitilliumWeb',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
