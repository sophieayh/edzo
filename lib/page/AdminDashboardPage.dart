import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void showUsersBottomSheet() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    List<QueryDocumentSnapshot> allUsers = usersSnapshot.docs;
    List<QueryDocumentSnapshot> filteredUsers = List.from(allUsers);
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void filterUsers(String query) {
              setModalState(() {
                filteredUsers = allUsers.where((doc) {
                  final email = doc['email']?.toLowerCase() ?? '';
                  return email.contains(query.toLowerCase());
                }).toList();
              });
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'All Users',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by email...'
                      ,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: filterUsers,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final doc = filteredUsers[index];
                        final email = doc['email'] ?? '';
                        final currentRole = doc['role'] ?? 'student';
                        final userId = doc.id;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(email),
                            subtitle: Text('Current Role: $currentRole'),
                            trailing: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: currentRole,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'student', child: Text('Student')),
                                  DropdownMenuItem(
                                      value: 'teacher', child: Text('Teacher')),
                                  DropdownMenuItem(
                                      value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (newRole) async {
                                  if (newRole != null) {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(userId)
                                        .update({'role': newRole});

                                    final updatedSnapshot =
                                    await FirebaseFirestore.instance.collection('users').get();
                                    allUsers = updatedSnapshot.docs;
                                    filterUsers(searchController.text);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Role updated to $newRole')),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchTeachersData() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').get();
    List<Map<String, dynamic>> teachersData = [];

    for (var userDoc in usersSnapshot.docs) {
      final String teacherEmail = userDoc['email'] ?? '';
      final coursesSnapshot = await FirebaseFirestore.instance.collection('courses').where('teacherEmail', isEqualTo: teacherEmail).get();
      int totalCourses = coursesSnapshot.docs.length;
      int totalSubscribers = 0;

      DateTime now = DateTime.now();
      List<String> recentFiveMonths = [];
      for (int i = 4; i >= 0; i--) {
        DateTime month = DateTime(now.year, now.month - i, 1);
        recentFiveMonths.add(DateFormat('yyyy-MM').format(month));
      }

      Map<String, int> monthlySubscribers = {
        for (var month in recentFiveMonths) month: 0,
      };

      for (var courseDoc in coursesSnapshot.docs) {
        final String courseId = courseDoc.id;
        final subsSnapshot = await FirebaseFirestore.instance.collection('subscriptions').where('courseId', isEqualTo: courseId).get();
        totalSubscribers += subsSnapshot.docs.length;

        for (var subDoc in subsSnapshot.docs) {
          Timestamp? createdAtTimestamp = subDoc['createdAt'];
          if (createdAtTimestamp != null) {
            DateTime createdAt = createdAtTimestamp.toDate();
            String subMonth = DateFormat('yyyy-MM').format(DateTime(createdAt.year, createdAt.month, 1));
            if (monthlySubscribers.containsKey(subMonth)) {
              monthlySubscribers[subMonth] = monthlySubscribers[subMonth]! + 1;
            }
          }
        }
      }

      teachersData.add({
        'email': teacherEmail,
        'totalCourses': totalCourses,
        'totalSubscribers': totalSubscribers,
        'monthlySubscribers': monthlySubscribers,
      });
    }

    return teachersData;
  }

  @override
  Widget build(BuildContext context) {
    const double horizontalPadding = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(horizontalPadding),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    image: _selectedImage != null
                        ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                        : const DecorationImage(
                      image: NetworkImage('https://via.placeholder.com/800x150'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: showUsersBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.people, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      'عرض كل المستخدمين',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'المدرسين المسجلين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchTeachersData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('خطأ في تحميل البيانات: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('لا يوجد مدرسين.'));
                  }

                  final teachers = snapshot.data!;

                  return ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {
                      final teacher = teachers[index];
                      final monthlySubs = teacher['monthlySubscribers'] as Map<String, int>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(
                            teacher['email'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'الكورسات: ${teacher['totalCourses']} | المشتركين: ${teacher['totalSubscribers']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الاشتراكات الشهرية:',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  ...monthlySubs.entries.map((entry) {
                                    final monthLabel = DateFormat('MMMM yyyy', 'ar').format(DateTime.parse('${entry.key}-01'));
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text('$monthLabel: ${entry.value} مشترك'),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
