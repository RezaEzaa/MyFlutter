import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:checkin/Pages/Teacher/profile_teacher_page.dart';
import 'package:checkin/Pages/Teacher/attendance_history_teacher_page.dart';
import 'package:checkin/Pages/Teacher/recap_attendance_page.dart';
import 'package:checkin/Pages/Teacher/student_detail_page.dart';
import 'package:checkin/Pages/settings_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String email;
  const TeacherHomePage({super.key, required this.email});
  @override
  _TeacherHomePageState createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _selectedIndex = 0;
  bool _isFirstVisit = true;
  int? _activeLabelIndex;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final response = await http.post(
      Uri.parse(
        'http://10.167.91.233/aplikasi-checkin/pages/guru/get_profile_guru.php',
      ),
      body: {'email': widget.email},
    );
    if (response.statusCode == 200) {
      try {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _profileData = result['data'];
            _isLoading = false;
          });
        } else {
          showError(result['message']);
        }
      } catch (e) {
        showError('Format JSON tidak valid: $e');
      }
    } else {
      showError('Gagal terhubung ke server. Status: ${response.statusCode}');
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
      _isFirstVisit = false;
      _activeLabelIndex = index;
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
                  _isFirstVisit
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
              MaterialPageRoute(
                builder: (context) => const SettingsPage(userRole: 'guru'),
              ),
            );
          },
        ),
      ],
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.dashboard_customize,
                size: 48,
                color: Colors.deepPurple,
              ),
              SizedBox(height: 12),
              Text(
                'Dashboard Guru Aplikasi Check-In',
                style: TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 22,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Selamat datang! Jangan lupa tersenyum :)',
                style: TextStyle(fontFamily: 'TitilliumWeb', fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildIconButton(Icons.person_outline, Icons.person, 'Profil', 0),
        buildIconButton(
          Icons.view_timeline_outlined,
          Icons.view_timeline,
          'Riwayat',
          1,
        ),
        buildIconButton(
          Icons.drive_file_move_outline,
          Icons.drive_file_move,
          'Manage Data',
          2,
        ),
        buildIconButton(Icons.view_list_outlined, Icons.view_list, 'Siswa', 3),
      ],
    );
  }

  Widget buildIconButton(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    bool isActive = _activeLabelIndex == index;
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
              content: const Text('Yakin ingin keluar dari aplikasi?'),
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
