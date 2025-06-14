import 'package:flutter/material.dart';

class InformationAppsPage extends StatelessWidget {
  const InformationAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informasi Aplikasi')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'asset/images/logo.png',
                width: 140,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aplikasi Check In Presensi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'TitilliumWeb',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi ini digunakan untuk memudahkan proses presensi siswa di lingkungan sekolah. '
              'Fitur utama aplikasi meliputi:\n\n'
              '• Presensi digital berbasis akun siswa dan guru\n'
              '• Riwayat presensi dan rekap kehadiran\n'
              '• Manajemen profil akun\n'
              '• Input dan pengelolaan data kelas serta siswa\n'
              '• Sistem presensi dengan deteksi wajah\n'
              '• Ekspor data rekap kehadiran ke file Excel\n'
              '• Pengaturan tema aplikasi (terang/gelap/sistem)\n\n'
              'Aplikasi ini dikembangkan menggunakan Flutter dan terintegrasi dengan backend PHP serta database MySQL.',
              style: TextStyle(fontSize: 16, fontFamily: 'TitilliumWeb'),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pengembang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Reza\n2101001\nUniversitas Pendidikan Indonesia',
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Versi Aplikasi: 1.0.0',
              style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Hak Cipta © 2025 Reza.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
