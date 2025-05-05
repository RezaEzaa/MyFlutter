import 'package:flutter/material.dart';

class AttendanceRecapPage extends StatelessWidget {
  const AttendanceRecapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Rekap Presensi',
              style: TextStyle(fontFamily: 'TitilliumWeb', fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showAttendanceRecap(context);
              },
              child: const Text('Buat Rekap Presensi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceRecap(BuildContext context) {
    List<String> attendanceData = [
      'Tanggal: 01/01/2023 - Neymar Jr. - Status: Hadir',
      'Tanggal: 01/01/2023 - Kylian Mbappe - Status: Hadir',
      'Tanggal: 01/01/2023 - Marco Veratti - Status: Tidak Hadir',
      'Tanggal: 01/01/2023 - Nuno Mendes - Status: Hadir',
      'Tanggal: 01/01/2023 - Archraf Hakimi - Status: Hadir',
      'Tanggal: 01/01/2023 - Lionel Messi - Status: Tidak Hadir',
      'Tanggal: 01/01/2023 - Angel Di Maria - Status: Tidak Hadir',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Data Rekap Presensi'),
          content: SingleChildScrollView(
            child: ListBody(
              children: attendanceData.map((data) => Text(data)).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
