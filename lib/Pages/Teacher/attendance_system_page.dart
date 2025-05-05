import 'package:flutter/material.dart';

class AttendanceSystemPage extends StatefulWidget {
  const AttendanceSystemPage({super.key});

  @override
  _AttendanceSystemPageState createState() => _AttendanceSystemPageState();
}

class _AttendanceSystemPageState extends State<AttendanceSystemPage> {
  bool _isFaceDetectionActive = false;

  void _toggleFaceDetection() {
    setState(() {
      _isFaceDetectionActive = !_isFaceDetectionActive;
    });
    if (_isFaceDetectionActive) {
      print("Pendeteksian wajah diaktifkan.");
    } else {
      print("Pendeteksian wajah dinonaktifkan.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sistem Presensi',
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _toggleFaceDetection,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isFaceDetectionActive ? Colors.green : Colors.red,
                ),
                child: Center(
                  child: Icon(
                    _isFaceDetectionActive ? Icons.sensors : Icons.sensors_off,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _isFaceDetectionActive
                  ? 'Sistem Presensi Aktif'
                  : 'Sistem Presensi Nonaktif',
              style: const TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
