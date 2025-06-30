import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../page/StudentCoursePage.dart';
import '../page/SubscribePage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int subscribersCount = 0;

  Future<List<String>> fetchUserSubscriptions() async {
    if (user == null) return [];
    final subsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('subscriptions')
        .get();

    return subsSnapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Courses'),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchUserSubscriptions(),
        builder: (context, subsSnapshot) {
          if (subsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (subsSnapshot.hasError) {
            return const Center(child: Text('Error loading subscriptions'));
          }

          final subscribedCourseIds = subsSnapshot.data ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('courses').snapshots(),
            builder: (context, coursesSnapshot) {
              if (coursesSnapshot.hasError) {
                return const Center(child: Text('Error loading courses'));
              }
              if (coursesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = coursesSnapshot.data?.docs ?? [];

              if (courses.isEmpty) {
                return const Center(child: Text('No courses available.'));
              }

              return ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final courseData = course.data() as Map<String, dynamic>;

                  final courseId = course.id;
                  final courseName = courseData['title'] ?? 'Untitled';
                  final courseImageUrl = courseData['imageUrl'] ?? '';
                  final courseDescription = courseData['description'] ?? '';
                  final isPaid = courseData['isPaid'] ?? false;
                  final price = courseData['price'] ?? 0;
                  final isSubscribed = subscribedCourseIds.contains(courseId);
                  final showSubscribeButton = isPaid && !isSubscribed;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('subscriptions')
                        .where('courseId', isEqualTo: courseId)
                        .snapshots(),
                    builder: (context, subsSnapshot) {
                      if (subsSnapshot.hasData) {
                        subscribersCount = subsSnapshot.data!.docs.length;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentCoursePage(
                                  courseId: courseId,
                                  title: courseName,
                                  description: courseDescription,
                                  imageUrl: courseImageUrl,
                                  subscribersCount: subscribersCount,
                                  isSubscribed: !isPaid || isSubscribed,
                                ),
                              ),
                            );
                          },
                          leading: courseImageUrl.isNotEmpty
                              ? Image.network(
                            courseImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                              : const Icon(Icons.book, size: 40),
                          title: Text(courseName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$subscribersCount مشترك'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.play_circle_outline,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('courses')
                                        .doc(courseId)
                                        .collection('videos')
                                        .snapshots(),
                                    builder: (context, videoSnapshot) {
                                      int videosCount = 0;
                                      if (videoSnapshot.hasData) {
                                        videosCount = videoSnapshot.data!.docs.length;
                                      }
                                      return Text(
                                        '$videosCount فيديو',
                                        style: TextStyle(
                                            color: Colors.grey[600], fontSize: 12),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  if (isPaid) ...[
                                    Icon(Icons.attach_money,
                                        size: 16, color: Colors.green[600]),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${price.toString()} د.ع',
                                      style: TextStyle(
                                        color: Colors.green[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: showSubscribeButton
                              ? ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubscribePage(
                                    courseId: courseId,
                                    courseName: courseName,
                                  ),
                                ),
                              );
                            },
                            child: const Text('اشترك'),
                          )
                              : isSubscribed
                              ? const Text(
                            'مشترك',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : const Text(
                            'مجاني',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
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
