import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscribePage extends StatefulWidget {
  final String courseId;
  final String courseName;

  const SubscribePage({
    Key? key,
    required this.courseId,
    required this.courseName,
  }) : super(key: key);

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  final TextEditingController _codeController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _subscribeWithCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود الاشتراك')),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // **هنا التغيير الأساسي: نبحث داخل مسار الأكواد الخاص بالكورس**
      final query = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('codes')
          .where('code', isEqualTo: code)
          .where('isUsed', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الكود غير صحيح أو مستخدم بالفعل')),
        );
        return;
      }

      // تحقق إذا المستخدم مشترك بالفعل
      final subRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('subscriptions')
          .doc(widget.courseId);

      final subSnapshot = await subRef.get();
      if (subSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أنت مشترك بالفعل في هذا الكورس')),
        );
        return;
      }

      // جلب بيانات الكورس
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .get();
      final courseData = courseDoc.data() ?? {};

      // الاشتراك في مسار المستخدم
      await subRef.set({
        'courseId': widget.courseId,
        'courseName': widget.courseName,
        'courseImage': courseData['imageUrl'] ?? '',
        'subscribedAt': FieldValue.serverTimestamp(),
      });

      // الاشتراك في مجموعة عامة لحساب العدد تلقائياً (اختياري)
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': user!.uid,
        'courseId': widget.courseId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // تعليم الكود كمستخدم
      await query.docs.first.reference.update({'isUsed': true, 'usedBy': user?.uid});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ت?م الاشتراك بنجاح')),
      );

      _codeController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('الاشتراك')),
        body: const Center(child: Text('يجب تسجيل الدخول لاستخدام الكود')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('الاشتراك في ${widget.courseName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'أدخل كود الاشتراك الخاص بك:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'كود الاشتراك',
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _subscribeWithCode,
              child: const Text('اشترك الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
