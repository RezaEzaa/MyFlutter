import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:checkin/Pages/Teacher/profile_teacher_page.dart';
import 'package:checkin/Pages/Teacher/attendance_history_teacher_page.dart';
import 'package:checkin/Pages/Teacher/recap_attendance_page.dart';
import 'package:checkin/Pages/Teacher/student_detail_page.dart';
import 'package:checkin/Pages/Teacher/attendance_system_page.dart';
import 'package:checkin/Pages/settings_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String email;
  const TeacherHomePage({super.key, required this.email});

  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;
  bool _isFirstVisitTeacher = true;
  int? _activeLabelIndexTeacher;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await http.post(
      Uri.parse('http://192.168.218.89/aplikasi-checkin/get_profile_guru.php'),
      body: {'email': widget.email},
    );

    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          final String baseUrl =
              'http://192.168.218.89/aplikasi-checkin/uploads/guru/';
          setState(() {
            _profileData = result['data'];
            if (_profileData!['foto'] != null && _profileData!['foto'] != '') {
              _profileData!['foto'] = baseUrl + _profileData!['foto'];
            }
            _isLoading = false;
          });
        } else {
          showError(result['message']);
        }
      } catch (e) {
        showError('Format JSON tidak valid: $e');
      }
    } else {
      showError(
        'Gagal terhubung ke server. Status code: ${response.statusCode}',
      );
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isFirstVisitTeacher = false;
      _activeLabelIndexTeacher = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> _pages = [
      ProfileTeacherPage(
        email: _profileData?['email'] ?? '',
        onProfileUpdated: fetchProfile,
      ),
      const AttendanceHistoryTeacherPage(),
      const AttendanceRecapPage(),
      StudentDetailPage(),
      const AttendanceSystemPage(),
    ];

    return WillPopScope(
      onWillPop: () async => await _showExitDialog(context),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child:
                  _isFirstVisitTeacher
                      ? _buildWelcomeMessage()
                      : _pages[_selectedIndex],
            ),
            _buildNavigationBar(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      flexibleSpace: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 25, child: Container()),
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
    );
  }

  Widget _buildWelcomeMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Dashboard Aplikasi Check In Guru',
            style: TextStyle(fontFamily: 'LilitaOne', fontSize: 20),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            'Jangan Lupa Untuk Tersenyum :)',
            style: TextStyle(fontFamily: 'TitilliumWeb', fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildIconButton(Icons.person_outlined, Icons.person, 'Profil Akun', 0),
        buildIconButton(
          Icons.view_timeline_outlined,
          Icons.view_timeline,
          'Riwayat Presensi',
          1,
        ),
        buildIconButton(
          Icons.receipt_outlined,
          Icons.receipt,
          'Input Data Siswa',
          2,
        ),
        buildIconButton(
          Icons.view_list_outlined,
          Icons.view_list,
          'Daftar Siswa',
          3,
        ),
        buildIconButton(
          Icons.camera_outlined,
          Icons.camera,
          'Sistem Presensi',
          4,
        ),
      ],
    );
  }

  Widget buildIconButton(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    bool isActive = _activeLabelIndexTeacher == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        children: [
          Icon(isActive ? filledIcon : outlinedIcon, size: 25),
          if (isActive)
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> _showExitDialog(BuildContext context) async {
  return (await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    SystemNavigator.pop();
                  },
                  child: const Text('Ya'),
                ),
              ],
            ),
      )) ??
      false;
}
