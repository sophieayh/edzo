import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../assets/VideoPlayerPage.dart';

class StudentCourseInfo extends StatelessWidget {
  final String courseId;
  final String userId;

  const StudentCourseInfo({
    Key? key,
    required this.courseId,
    required this.userId,
  }) : super(key: key);

  Future<bool> isUserSubscribed() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .doc(courseId)
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isUserSubscribed(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final isSubscribed = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('courses').doc(courseId).get(),
          builder: (context, courseSnapshot) {
            if (!courseSnapshot.hasData) return const Center(child: CircularProgressIndicator());

            final courseData = courseSnapshot.data!.data() as Map<String, dynamic>;
            final imageUrl = courseData['imageUrl'] ?? '';
            final teacherName = courseData['teacherName'] ?? 'غير معروف';
            final courseTitle = courseData['title'] ?? 'معلومات الكورس';

            return Scaffold(
              appBar: AppBar(
                title: Text(courseTitle),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(
                        child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                      )
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'الأستاذ: $teacherName',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('courses')
                          .doc(courseId)
                          .collection('videos')
                          .snapshots(),
                      builder: (context, videoSnapshot) {
                        if (!videoSnapshot.hasData) return const SizedBox();
                        final videos = videoSnapshot.data!.docs;
                        final count = videos.length;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count فيديو',
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    if (isSubscribed)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('courses')
                            .doc(courseId)
                            .collection('videos')
                            .snapshots(),
                        builder: (context, videoSnapshot) {
                          if (videoSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!videoSnapshot.hasData || videoSnapshot.data!.docs.isEmpty) {
                            return const Text('لا توجد فيديوهات بعد.');
                          }
                          final videos = videoSnapshot.data!.docs;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الفيديوهات:',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                itemCount: videos.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final video = videos[index].data() as Map<String, dynamic>;
                                  final videoUrl = video['videoUrl'] ?? '';
                                  final videoTitle = video['title'] ?? 'بدون عنوان';
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.play_circle_fill),
                                      title: Text(videoTitle),
                                      onTap: () {
                                        if (videoUrl.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => VideoPlayerPage(
                                                videoUrl: videoUrl,
                                                videoTitle: videoTitle,
                                              ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("رابط الفيديو غير متوفر")),
                                          );
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'يرجى الاشتراك لعرض الفيديوهات',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}