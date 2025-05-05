import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ClassListPage extends StatefulWidget {
  final List<String> selectedClasses;

  const ClassListPage({super.key, required this.selectedClasses});

  @override
  State<ClassListPage> createState() => _ClassListPageState();
}

class _ClassListPageState extends State<ClassListPage> {
  List<Map<String, dynamic>> allClasses = [];

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    final response = await http.get(
      Uri.parse(
        'http://192.168.218.89/aplikasi-checkin/get_class_with_students.php',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status']) {
        setState(() {
          allClasses = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        setState(() {
          allClasses = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Kelas")),
      body:
          allClasses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: allClasses.length,
                itemBuilder: (context, index) {
                  final classItem = allClasses[index];
                  final isSelected = widget.selectedClasses.contains(
                    classItem['kelas'],
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: ListTile(
                      title: Text("Kelas ${classItem['kelas']}"),
                      subtitle: Text("Jumlah Siswa: ${classItem['jumlah']}"),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.add_circle,
                        color: isSelected ? Colors.green : Colors.blue,
                      ),
                      onTap: () {
                        if (!isSelected) {
                          Navigator.pop(context, classItem['kelas']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kelas sudah ditambahkan"),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
    );
  }
}
