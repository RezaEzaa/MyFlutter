import 'package:flutter/material.dart';
class InformationTeacherPage extends StatelessWidget {
  const InformationTeacherPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Dashboard Guru'),
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
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.person_pin, size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Dashboard Guru',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'TitilliumWeb',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Panduan Penggunaan Fitur untuk Guru',
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
            const TeacherFeatureCard(
              icon: Icons.account_circle,
              title: 'Profil Guru',
              description: 'Kelola informasi profil dan akun pribadi',
              features: [
                '• Lihat informasi profil lengkap (nama, email, foto)',
                '• Edit data pribadi dan kontak',
                '• Update foto profil untuk sistem face recognition',
                '• Ubah password akun dengan validasi keamanan',
                '• Logout dengan konfirmasi',
                '• Sinkronisasi data profil dengan server',
              ],
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const TeacherFeatureCard(
              icon: Icons.view_timeline,
              title: 'Riwayat Presensi',
              description: 'Monitor dan kelola riwayat kehadiran siswa',
              features: [
                '• Lihat riwayat presensi semua kelas yang diampu',
                '• Filter berdasarkan tanggal, semester, dan kelas',
                '• Expand/collapse view untuk navigasi mudah',
                '• Detail kehadiran per siswa dengan status lengkap',
                '• Aktivasi presensi real-time untuk kelas',
                '• Notifikasi push saat presensi aktif',
                '• Refresh data secara manual atau otomatis',
              ],
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const TeacherFeatureCard(
              icon: Icons.edit_document,
              title: 'Edit & Kelola Presensi',
              description: 'Edit dan rekap data presensi siswa',
              features: [
                '• Edit status kehadiran siswa (hadir/izin/sakit/alfa)',
                '• Tambah keterangan untuk ketidakhadiran',
                '• Koreksi data presensi yang salah input',
                '• Download template Excel untuk edit offline',
                '• Upload data presensi yang sudah diedit',
                '• Download recap presensi dalam format Excel',
                '• Validasi dan konfirmasi sebelum save perubahan',
              ],
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            const TeacherFeatureCard(
              icon: Icons.groups,
              title: 'Data Siswa',
              description: 'Lihat dan kelola informasi siswa per kelas',
              features: [
                '• Daftar siswa berdasarkan kelas yang diampu',
                '• Filter siswa berdasarkan kelas dan mata pelajaran',
                '• Detail informasi lengkap setiap siswa',
                '• Lihat foto profil siswa untuk identifikasi',
                '• Statistik kehadiran individual per siswa',
                '• Cari siswa dengan nama atau nomor induk',
                '• Export daftar siswa ke format Excel',
              ],
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
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
                      Icon(Icons.timeline, color: Colors.indigo, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Alur Kerja Presensi',
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
                    '📚 Panduan Lengkap Penggunaan Dashboard Guru\n\n'
                    '1. Memulai Presensi:\n'
                    '   • Buka menu Riwayat Presensi\n'
                    '   • Pilih kelas yang akan diabsen\n'
                    '   • Aktifkan presensi dengan tombol "Aktifkan"\n'
                    '   • Sistem akan mengirim notifikasi ke siswa\n\n'
                    '2. Monitoring Kehadiran:\n'
                    '   • Pantau siswa yang sudah presensi real-time\n'
                    '   • Refresh data untuk update terbaru\n'
                    '   • Lihat detail kehadiran setiap siswa\n\n'
                    '3. Edit & Koreksi Data:\n'
                    '   • Gunakan menu "Manage Data Presensi"\n'
                    '   • Edit status kehadiran jika diperlukan\n'
                    '   • Tambahkan keterangan untuk siswa yang tidak hadir\n'
                    '   • Download template untuk edit offline\n\n'
                    '4. Export & Rekap:\n'
                    '   • Download rekap presensi bulanan\n'
                    '   • Export daftar siswa untuk keperluan administrasi\n'
                    '   • Simpan data sebagai backup',
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
class TeacherFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;
  final Color color;
  const TeacherFeatureCard({
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
