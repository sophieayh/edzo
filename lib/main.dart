import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'page/auth_page.dart';
import 'firebase_options.dart';

// ويدجت حماية الشاشة
class SecureWrapper extends StatefulWidget {
  final Widget child;
  const SecureWrapper({super.key, required this.child});

  @override
  State<SecureWrapper> createState() => _SecureWrapperState();
}

class _SecureWrapperState extends State<SecureWrapper> {
  static const platform = MethodChannel('secure_screen_channel');
  bool _isCaptured = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      _checkScreenCapture();
    }
  }

  Future<void> _checkScreenCapture() async {
    try {
      final bool isCaptured = await platform.invokeMethod('isCaptured');
      setState(() {
        _isCaptured = isCaptured;
      });
    } catch (e) {
      print("Error checking screen capture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCaptured) {
      return Container(color: Colors.black); // شاشة سوداء لو يسجل المستخدم
    }
    return widget.child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة التاريخ حسب اللغة
  await initializeDateFormatting('ar', null);

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // حماية الشاشة للأندرويد
  if (Platform.isAndroid) {
    const platform = MethodChannel('secure_screen_channel');
    try {
      await platform.invokeMethod('enableSecureScreen');
    } catch (e) {
      print("Failed to enable secure screen: $e");
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SecureWrapper(
        child: AuthPage(),
      ),
    );
  }
}

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  Future<String> getTeacherName(String email) async {
    final doc = await FirebaseFirestore.instance.collection('teachers').doc(email).get();
    if (doc.exists && doc.data()!.containsKey('name')) {
      return doc['name'];
    }
    return 'Unknown Teacher';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No courses available."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final courseTitle = data['title'] ?? 'No Title';
              final teacherEmail = data['teacherEmail'] ?? '';

              return FutureBuilder<String>(
                future: getTeacherName(teacherEmail),
                builder: (context, teacherSnapshot) {
                  if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text(courseTitle),
                      subtitle: const Text('Loading teacher...'),
                    );
                  }

                  final teacherName = teacherSnapshot.data ?? 'Unknown Teacher';

                  return ListTile(
                    title: Text(courseTitle),
                    subtitle: Text('Teacher: $teacherName'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
