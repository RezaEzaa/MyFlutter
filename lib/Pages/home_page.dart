import 'package:flutter/material.dart';
import 'package:checkin/Pages/settings_page.dart';
import 'package:checkin/Pages/login_page.dart';
import 'package:checkin/Pages/registration_page.dart';
import 'package:checkin/Pages/information_app_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
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

          // Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Column(
                  children: [
                    // AppBar Custom
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings),
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
                    const SizedBox(height: 40),

                    // Logo
                    Image.asset(
                      'asset/images/logo.png',
                      width: 200,
                      height: 120,
                    ),
                    const SizedBox(height: 60),

                    // Welcome Text
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
                        fontSize: 30,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),

                    // Tombol Log In dengan Tooltip
                    Tooltip(
                      message: 'Masuk ke aplikasi',
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.login,
                          color: Colors.blue,
                          size: 35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    const Text(
                      'Jika Anda sudah memiliki akun, silakan tekan ikon di atas untuk masuk.',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '(Tekan lama ikon untuk informasi tombol)',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Tombol Sign Up dengan Tooltip
                    Tooltip(
                      message: 'Daftar untuk membuat akun',
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegistrationPage(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.app_registration,
                          color: Colors.green,
                          size: 35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    const Text(
                      'Jika Anda belum memiliki akun, silakan tekan ikon di atas untuk registrasi.',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      '(Tekan lama ikon untuk informasi tombol)',
                      style: TextStyle(
                        fontFamily: 'TitilliumWeb',
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 50),

                    // Tombol Tentang Aplikasi (ikon dan teks menyatu dalam TextButton)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InformationAppsPage(),
                          ),
                        );
                      },
                      style: ButtonStyle(
                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),
                        splashFactory:
                            NoSplash.splashFactory, // Hilangkan efek sentuhan
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 15,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Tentang Aplikasi',
                            style: TextStyle(
                              fontFamily: 'TitilliumWeb',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
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
