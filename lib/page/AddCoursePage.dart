import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math';

class AddCoursePage extends StatefulWidget {
  final String teacherEmail;
  final String teacherName;

  const AddCoursePage({super.key, required this.teacherEmail,required this.teacherName});

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _courseTitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isPaid = false;
  File? _pickedVideoFile;
  File? _pickedImageFile;

  bool _isLoading = false; // مؤشر التحميل

  String generateRandomCode(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

 
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedImageFile = File(result.files.single.path!);
      });
    }
  }

  Future<String> _uploadFileToStorage(
      File file, String folder, String extension) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName.$extension');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  void _saveCourse() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String? videoUrl;
        String? imageUrl;

        if (_pickedVideoFile != null) {
          videoUrl = await _uploadFileToStorage(_pickedVideoFile!, 'course_videos', 'mp4');
        }

        if (_pickedImageFile != null) {
          imageUrl = await _uploadFileToStorage(_pickedImageFile!, 'course_images', 'jpg');
        }

        Map<String, dynamic> courseData = {
          'title': _courseTitleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'isPaid': _isPaid,
          'teacherId': user.uid,
          'teacherEmail': widget.teacherEmail,
          'teacherName': widget.teacherName,
          'createdAt': Timestamp.now(),
          'videoUrl': videoUrl ?? '',
          'imageUrl': imageUrl ?? '',
        };
        

        if (_isPaid) {
          courseData['price'] = double.tryParse(_priceController.text.trim()) ?? 0;
        }

        final courseRef = await FirebaseFirestore.instance.collection('courses').add(courseData);
        final courseId = courseRef.id;
        String uniqueCode = "";
        for(int i = 0; i < 3; i++){

          uniqueCode = generateRandomCode(15);
          print(uniqueCode);
          await FirebaseFirestore.instance.collection('courseCodes').add({
            'code': uniqueCode,
            'courseId': courseId,
            'isUsed': false,
            'createdAt': Timestamp.now(),
          });
        }


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course added with code: $uniqueCode')),
        );

        // التنقل إلى صفحة كورسات الأستاذ بعد الحفظ
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherCoursesPage(teacherEmail: widget.teacherEmail),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _courseTitleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Course')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _courseTitleController,
                  decoration: const InputDecoration(labelText: 'Course Title'),
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Paid Course'),
                  value: _isPaid,
                  onChanged: (val) => setState(() => _isPaid = val),
                ),
                if (_isPaid)
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Course Price'),
                    validator: (value) {
                      if (_isPaid && (value == null || value.isEmpty)) {
                        return 'Enter price for paid course';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text(_pickedImageFile == null
                      ? 'Pick Course Image (Optional)'
                      : 'Image Selected'),
                ),
                if (_pickedImageFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Image.file(
                      _pickedImageFile!,
                      height: 150,
                    ),
                  ),
                
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _saveCourse,
                  child: const Text('Save Course'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// صفحة كورسات الأستاذ (لا تنسى إضافتها في مشروعك)
class TeacherCoursesPage extends StatelessWidget {
  final String teacherEmail;

  const TeacherCoursesPage({super.key, required this.teacherEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Courses')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('teacherEmail', isEqualTo: teacherEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          if (courses.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                leading: course['imageUrl'] != ''
                    ? Image.network(course['imageUrl'],
                    width: 50, height: 50, fit: BoxFit.cover)
                    : null,
                title: Text(course['title']),
                subtitle: Text(course['description'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
