import 'package:flutter/material.dart';
import 'package:checkin/Pages/Student/attendance_detail_student_page.dart';

class AttendanceHistoryStudentPage extends StatelessWidget {
  const AttendanceHistoryStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Riwayat Presensi',
                style: TextStyle(
                  fontFamily: 'TitilliumWeb',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                  final backgroundColor =
                      Theme.of(context).brightness == Brightness
                          ? Colors.grey[500]
                          : Colors.grey[850];

                  return GestureDetector(
                    onTap: () {
                      // Navigate to the attendance detail page here
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AttendanceDetailPageStudent(
                                kelas: 'MATH${101 + index}',
                                mataKuliah:
                                    'MATEMATIKA ${index.isEven ? 1 : 2}',
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      margin: const EdgeInsets.only(bottom: 10.0),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelas: MATH${101 + index}',
                            style: const TextStyle(
                              fontFamily: 'TitilliumWeb',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Mata Kuliah: MATEMATIKA ${index.isEven ? 1 : 2}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Guru: Sri Tiana',
                            style: TextStyle(
                              fontFamily: 'TitilliumWeb',
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tanggal ${index + 1}',
                                style: const TextStyle(
                                  fontFamily: 'TitilliumWeb',
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              index.isEven
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                  : const Icon(Icons.cancel, color: Colors.red),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
