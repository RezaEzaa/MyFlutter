import 'package:flutter/material.dart';

class AttendanceDetailPageStudent extends StatelessWidget {
  final String kelas;
  final String mataKuliah;

  const AttendanceDetailPageStudent({
    Key? key,
    required this.kelas,
    required this.mataKuliah,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$kelas - $mataKuliah')),
      body: Center(child: Text('Data presensi untuk $kelas - $mataKuliah')),
    );
  }
}
