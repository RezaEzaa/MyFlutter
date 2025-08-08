import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:checkin/main.dart';
import 'package:checkin/Pages/information_app_page.dart';
import 'package:checkin/Pages/information_admin_page.dart';
import 'package:checkin/Pages/information_teacher_page.dart';
import 'package:checkin/Pages/information_student_page.dart';
class SettingsPage extends StatelessWidget {
  final String? userRole;
  const SettingsPage({super.key, this.userRole});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Pilih Tema Aplikasi',
              style: TextStyle(
                fontFamily: 'TitilliumWeb',
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildThemeButton(
              context,
              label: 'Tema Terang',
              icon: Icons.wb_sunny_outlined,
              color: Colors.orange,
              onPressed: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setTheme(ThemeMode.light);
              },
            ),
            const SizedBox(height: 16),
            _buildThemeButton(
              context,
              label: 'Tema Gelap',
              icon: Icons.nightlight_round,
              color: Colors.blueGrey,
              onPressed: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setTheme(ThemeMode.dark);
              },
            ),
            const SizedBox(height: 16),
            _buildThemeButton(
              context,
              label: 'Tema Sistem',
              icon: Icons.settings,
              color: Colors.teal,
              onPressed: () {
                Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                ).setTheme(ThemeMode.system);
              },
            ),
            const SizedBox(height: 40),
            Container(
              width: 260,
              height: 1,
              color: isDarkMode ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 20),
            if (userRole != null)
              ..._buildRoleSpecificButtons(context, isDarkMode),
            SizedBox(
              width: 260,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InformationAppsPage(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.info_outline,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                label: Text(
                  'Tentang Aplikasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'TitilliumWeb',
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildThemeButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  List<Widget> _buildRoleSpecificButtons(
    BuildContext context,
    bool isDarkMode,
  ) {
    List<Widget> buttons = [];
    switch (userRole?.toLowerCase()) {
      case 'admin':
        buttons.add(
          _buildRoleButton(
            context: context,
            isDarkMode: isDarkMode,
            label: 'Panduan Dashboard Admin',
            icon: Icons.admin_panel_settings,
            color: Colors.blue,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationAdminPage(),
                ),
              );
            },
          ),
        );
        break;
      case 'guru':
      case 'teacher':
        buttons.add(
          _buildRoleButton(
            context: context,
            isDarkMode: isDarkMode,
            label: 'Panduan Dashboard Guru',
            icon: Icons.person_pin,
            color: Colors.green,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationTeacherPage(),
                ),
              );
            },
          ),
        );
        break;
      case 'siswa':
      case 'student':
        buttons.add(
          _buildRoleButton(
            context: context,
            isDarkMode: isDarkMode,
            label: 'Panduan Dashboard Siswa',
            icon: Icons.school,
            color: Colors.teal,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationStudentPage(),
                ),
              );
            },
          ),
        );
        break;
      default:
        buttons.add(
          _buildRoleButton(
            context: context,
            isDarkMode: isDarkMode,
            label: 'Panduan Penggunaan',
            icon: Icons.help_center,
            color: Colors.orange,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InformationAppsPage(),
                ),
              );
            },
          ),
        );
        break;
    }
    buttons.add(const SizedBox(height: 16));
    return buttons;
  }
  Widget _buildRoleButton({
    required BuildContext context,
    required bool isDarkMode,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 260,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'TitilliumWeb',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
