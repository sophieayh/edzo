import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class StudentCoursePage extends StatefulWidget {
  final String courseId;
  final String title;
  final String description;
  final String imageUrl;
  final int subscribersCount;
  final bool isSubscribed;

  const StudentCoursePage({
    Key? key,
    required this.courseId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.subscribersCount,
    required this.isSubscribed,
  }) : super(key: key);

  @override
  State<StudentCoursePage> createState() => _StudentCoursePageState();
}

class _StudentCoursePageState extends State<StudentCoursePage> {
  late Future<QuerySnapshot> videosFuture;

  @override
  void initState() {
    super.initState();
    videosFuture = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('videos')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.imageUrl.isNotEmpty)
            Image.network(widget.imageUrl, height: 180, fit: BoxFit.cover),
          const SizedBox(height: 12),
          Text(widget.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Text(
            'عدد المشتركين: ${widget.subscribersCount}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (!widget.isSubscribed)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'اشترك بالكورس لتشغيل الفيديوهات المدفوعة',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'الفيديوهات:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future: videosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('لا توجد فيديوهات متوفرة');
              }

              final allVideos = snapshot.data!.docs;

              return Column(
                children: allVideos.map((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  final isFree = data['isFree'] == true;
                  final canAccess = widget.isSubscribed || isFree;
 print(data['videoUrl']);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: data['thumbnail'] != null && (data['thumbnail'] as String).isNotEmpty
                          ? Image.network(
                        data['thumbnail'],
                        width: 60,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                          : const Icon(Icons.videocam, size: 40),
                      title: Text(data['title'] ?? 'بدون عنوان'),
                      subtitle: canAccess
                          ? null
                          : const Text(
                        'مقفل - اشترك لمشاهدة الفيديو',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: canAccess
                          ? () {
                           
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                                videoUrl: data['videoUrl'] ?? ''),
                          ),
                        );
                      }
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}


class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشغل الفيديو')),
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isLandscape = orientation == Orientation.landscape;

          return Center(
            child: _chewieController != null &&
                    _videoPlayerController.value.isInitialized
                ? Container(
                    color: Colors.black,
                    width: isLandscape
                        ? MediaQuery.of(context).size.width
                        : MediaQuery.of(context).size.width * 0.9,
                    height: isLandscape
                        ? MediaQuery.of(context).size.height
                        : MediaQuery.of(context).size.width * 9 / 16,
                    child: Chewie(controller: _chewieController!),
                  )
                : const CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}