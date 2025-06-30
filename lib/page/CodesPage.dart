import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class EditCoursePage extends StatefulWidget {
  final String courseId;
  final String initialTitle;

  const EditCoursePage({
    super.key,
    required this.courseId,
    required this.initialTitle,
  });

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);

    // يمكنك حذف هذا السطر لو تريد عدم توليد أكواد تلقائيًا
    // ensureMinimumUnusedCodes(widget.courseId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String generateCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> generateAndSaveNewCode() async {
    final codesRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('codes');

    final newCode = generateCode(16);
    await codesRef.add({
      'code': newCode,
      'isUsed': false,
      'usedBy': null,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم توليد كود جديد: $newCode')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل الكورس'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('courses')
                .doc(widget.courseId)
                .collection('codes')
            //.where('isUsed', isEqualTo: false)  // حذفنا هذا الشرط
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final docs = snapshot.data!.docs;

              return PopupMenuButton<String>(
                icon: const Icon(Icons.vpn_key),
                onSelected: (value) {
                  if (value == 'generate') {
                    generateAndSaveNewCode();
                  } else {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم نسخ الكود")),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'generate',
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text('توليد كود جديد'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  ...docs.map((doc) {
                    final code = doc['code'] as String;
                    return PopupMenuItem<String>(
                      value: code,
                      child: Text(
                        code,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'اسم الكورس'),
            ),
            const SizedBox(height: 24),
            const Text(
              "أكواد الاشتراك المتاحة:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .doc(widget.courseId)
                  .collection('codes')
              //.where('isUsed', isEqualTo: false)  // حذفنا هذا الشرط
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("لا توجد أكواد حالياً.");
                }
                final docs = snapshot.data!.docs;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: docs.map((doc) {
                    final code = doc['code'];
                    return Text("🔐 $code", style: const TextStyle(fontSize: 16));
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
