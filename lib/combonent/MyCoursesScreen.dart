// MyCoursesScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../page/StudentCoursePage.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> fetchSubscribedCourses() async {
    if (user == null) return [];

    final subsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('subscriptions')
        .get();

    final courses = subsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // هذا هو courseId
      return data;
    }).toList();

    return courses;
  }

  Future<Map<String, dynamic>?> fetchCourseById(String courseId) async {
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .get();

    if (!courseDoc.exists) return null;

    final data = courseDoc.data()!;
    data['id'] = courseId;

    // لن نحتاج لجلب الفيديوهات هنا بعد التعديل، لأن StudentCoursePage يجلبها بنفسه

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("كورساتي")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchSubscribedCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("لا توجد كورسات مشتركة."));
          }

          final courses = snapshot.data!;

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: (course['courseImage'] != null && course['courseImage'] != "")
                      ? Image.network(course['courseImage'], width: 60, height: 60, fit: BoxFit.cover)
                      : const Icon(Icons.image),
                  title: Text(course['courseName'] ?? 'بدون عنوان'),
                  subtitle: Text('ID: ${course['id']}'),
                  onTap: () async {
                    final courseData = await fetchCourseById(course['id'].toString());
                    if (courseData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentCoursePage(
                            courseId: courseData['id'].toString(),
                            title: courseData['courseName']?.toString() ?? '',
                            description: courseData['description']?.toString() ?? '',
                            imageUrl: courseData['courseImage']?.toString() ?? '',
                            subscribersCount: courseData['subscribersCount'] is int
                                ? courseData['subscribersCount']
                                : int.tryParse(courseData['subscribersCount']?.toString() ?? '0') ?? 0,
                            isSubscribed: true,  // المستخدم مشترك في هذا الكورس
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تعذر تحميل بيانات الكورس.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
