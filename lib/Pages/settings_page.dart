import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:checkin/main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Pilih Tema Aplikasi',
              style: TextStyle(fontFamily: 'TitilliumWeb', fontSize: 24),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  // Mengubah tema menjadi terang
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setTheme(ThemeMode.light);
                },
                child: const Text('Tema Terang'),
              ),
            ),
            const SizedBox(height: 0),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  // Mengubah tema menjadi gelap
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setTheme(ThemeMode.dark);
                },
                child: const Text('Tema Gelap'),
              ),
            ),
            const SizedBox(height: 0),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () {
                  // Mengubah tema menjadi sistem
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setTheme(ThemeMode.system);
                },
                child: const Text('Tema Sistem'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
