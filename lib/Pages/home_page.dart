import 'package:flutter/material.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/login_page.dart';
import 'package:checkin/Pages/registration_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDarkMode
                      ? 'asset/background/dashboard_gelap.jpg'
                      : 'asset/background/home_terang.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
                          tooltip: 'Pengaturan Tema',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 70),
                    Image.asset(
                      'asset/images/logo.png',
                      width: 200,
                      height: 120,
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'SELAMAT DATANG DI APLIKASI',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'CHECK IN',
                      style: TextStyle(
                        fontFamily: 'LilitaOne',
                        fontSize: 34,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    Tooltip(
                      message: 'Masuk ke aplikasi',
                      child: SizedBox(
                        width: 220,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Untuk guru dan siswa yang sudah memiliki akun dari admin.',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '(Tekan lama ikon untuk info tombol)',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Tooltip(
                      message: 'Daftar khusus untuk admin',
                      child: SizedBox(
                        width: 220,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegistrationPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.app_registration, size: 20),
                          label: const Text(
                            'Daftar',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khusus untuk admin sistem. Guru dan siswa mendapat akun dari admin.',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '(Tekan lama ikon untuk info tombol)',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
