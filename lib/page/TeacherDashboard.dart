import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'AddCoursePage.dart';
import 'EditCoursePage.dart';

class TeacherDashboard extends StatefulWidget {
  final String teacherEmail;
  final String teacherName;


  const TeacherDashboard({
    super.key,
    required this.teacherEmail,
    required this.teacherName,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  String teacherName = '';
  String? profileImageUrl;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadName();
    _loadProfileImage();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final localName = prefs.getString('teacherName');

    if (localName != null && localName.isNotEmpty) {
      setState(() {
        teacherName = localName;
      });
    } else {
      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherEmail)
          .get();

      if (doc.exists && doc.data()!.containsKey('name')) {
        final nameFromFirebase = doc['name'];
        setState(() {
          teacherName = nameFromFirebase;
        });
        await prefs.setString('teacherName', nameFromFirebase);
      }
    }
  }

  Future<void> _loadProfileImage() async {
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(widget.teacherEmail)
        .get();

    if (doc.exists && doc.data()!.containsKey('profileImageUrl')) {
      setState(() {
        profileImageUrl = doc['profileImageUrl'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('teacher_profiles/${widget.teacherEmail}.jpg');

      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherEmail)
          .set({'profileImageUrl': imageUrl}, SetOptions(merge: true));

      setState(() {
        profileImageUrl = imageUrl;
      });
    }
  }

  void _showEditNameDialog() async {
    final doc = await FirebaseFirestore.instance
        .collection('teachers')
        .doc(widget.teacherEmail)
        .get();

    final existingSubject = doc.data()?['subject'] ?? '';
    final subjectController = TextEditingController(text: existingSubject);

    final courseSnapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('teacherEmail', isEqualTo: widget.teacherEmail)
        .get();

    final courseCount = courseSnapshot.docs.length;

    _nameController.text = teacherName;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 10),
              Text('Courses: $courseCount',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final subject = subjectController.text.trim();

              await FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(widget.teacherEmail)
                  .set({
                'name': name,
                'subject': subject,
              }, SetOptions(merge: true));

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('teacherName', name);

              setState(() {
                teacherName = name;
              });

              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Course',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCoursePage(teacherEmail: widget.teacherEmail, teacherName: widget.teacherName),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                    image: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                        ? DecorationImage(
                      image: NetworkImage(profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                      ? const Center(
                    child: Icon(Icons.person, size: 80, color: Colors.white),
                  )
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _pickAndUploadImage,
                  tooltip: 'Edit Profile Image',
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(widget.teacherEmail)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final subject = data['subject'] ?? 'No subject';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F8CAA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subject: $subject',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('courses')
                            .where('teacherEmail', isEqualTo: widget.teacherEmail)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox();
                          }
                          final courseCount = snapshot.data!.docs.length;
                          return Text(
                            'Courses: $courseCount',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: _showEditNameDialog,
                          icon: const Icon(Icons.settings, color: Colors.white),
                          tooltip: 'Edit Info',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('teacherEmail', isEqualTo: widget.teacherEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No courses found');
                }

                final courses = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    final courseTitle = course['title'] ?? 'No Title';
                    final courseImage = course['imageUrl'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(courseTitle),
                        leading: courseImage.isNotEmpty
                            ? Image.network(
                          courseImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.book),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCoursePage(
                                  courseId: course.id,
                                  initialTitle: courseTitle,
                                  initialImageUrl: courseImage, initialName: 'initialName',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
