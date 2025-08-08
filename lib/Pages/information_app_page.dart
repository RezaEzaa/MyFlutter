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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.lightBlue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang Aplikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'TitilliumWeb',
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Check In Presensi adalah solusi digital inovatif yang dirancang khusus untuk mempermudah dan memodernisasi sistem absensi di lingkungan pendidikan. Aplikasi ini menghadirkan pengalaman presensi yang efisien, akurat, dan user-friendly bagi siswa maupun guru.',
                    style: TextStyle(fontSize: 16, fontFamily: 'TitilliumWeb'),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '✨ Fitur Unggulan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'TitilliumWeb',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Column(
                children: [
                  FeatureItem(
                    icon: '👤',
                    title: 'Presensi Digital Terpersonalisasi',
                    description:
                        'Sistem login berbasis akun dengan role siswa dan guru',
                  ),
                  FeatureItem(
                    icon: '🎭',
                    title: 'Face Recognition Technology',
                    description:
                        'Teknologi deteksi wajah untuk keamanan maksimal',
                  ),
                  FeatureItem(
                    icon: '📊',
                    title: 'Analitik & Laporan Lengkap',
                    description:
                        'Riwayat presensi detail dan ekspor data ke Excel',
                  ),
                  FeatureItem(
                    icon: '⚙️',
                    title: 'Manajemen Data Terintegrasi',
                    description:
                        'Kelola profil, kelas, dan data siswa dalam satu platform',
                  ),
                  FeatureItem(
                    icon: '🌙',
                    title: 'UI/UX Adaptif',
                    description:
                        'Tema terang, gelap, dan mengikuti sistem device',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🛠️ Teknologi & Arsitektur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'TitilliumWeb',
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TechItem(label: 'Frontend', value: 'Flutter'),
                      ),
                      Expanded(child: TechItem(label: 'Backend', value: 'PHP')),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TechItem(label: 'Database', value: 'MySQL'),
                      ),
                      Expanded(
                        child: TechItem(
                          label: 'Platform',
                          value: 'Cross-Platform',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Pengembang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'TitilliumWeb',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage(
                            'asset/images/foto_reza.png',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                          },
                          child: null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Reza',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'TitilliumWeb',
                    ),
                  ),
                  Text('NIM: 2101001', style: TextStyle(fontSize: 15)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'asset/images/logo_upi.png',
                            fit: BoxFit.contain,
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading logo_upi.png: $error');
                              print('StackTrace: $stackTrace');
                              return Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 30,
                                  color: Colors.red.shade700,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Universitas Pendidikan Indonesia',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Fakultas Pendidikan Teknik dan Industri',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Pendidikan Teknik Elektro',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
          ],
        ),
      ),
    );
  }
}
class FeatureItem extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  const FeatureItem({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: 'TitilliumWeb',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class TechItem extends StatelessWidget {
  final String label;
  final String value;
  const TechItem({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'TitilliumWeb',
          ),
        ),
      ],
    );
  }
}
