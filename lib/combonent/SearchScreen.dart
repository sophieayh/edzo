import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ لإحضار userId
import '../page/studentcourseinfo.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String searchText = "";
  String debouncedText = "";
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance; // ✅ مرجع للمصادقة
  Timer? _debounce;

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        debouncedText = text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ جلب userId من المستخدم المسجل حاليًا
    final currentUser = auth.currentUser;
    final currentUserId = currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
              _onSearchChanged(value);
            },
            decoration: InputDecoration(
              hintText: 'ابحث عن كورس أو مدرس',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: debouncedText.isEmpty
                ? const Center(child: Text('ابدأ بالبحث بكتابة اسم كورس أو مدرس'))
                : StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('courses')
                  .where('title', isGreaterThanOrEqualTo: debouncedText)
                  .where('title', isLessThanOrEqualTo: '$debouncedText\uf8ff')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد نتائج'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final course = docs[index];
                    final courseTitle = course['title'] ?? 'بدون اسم';
                    final teacherName = course['teacherName'] ?? 'بدون مدرس';
                    final courseImage = course['imageUrl'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: courseImage.isNotEmpty
                            ? Image.network(courseImage, width: 60, fit: BoxFit.cover)
                            : const Icon(Icons.book, size: 40),
                        title: Text(courseTitle),
                        subtitle: Text('المدرس: $teacherName'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          if (currentUserId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("الرجاء تسجيل الدخول أولاً")),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentCourseInfo(
                                courseId: course.id,
                                userId: currentUserId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
