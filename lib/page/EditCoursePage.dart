import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class EditCoursePage extends StatefulWidget {
  final String courseId;
  final String initialName;
  final String initialTitle;
  final String initialImageUrl;

  const EditCoursePage({
    Key? key,
    required this.courseId,
    required this.initialName,
    required this.initialTitle,
    required this.initialImageUrl,
  }) : super(key: key);

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _titleController = TextEditingController();
  bool _isEditingTitle = false;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();


  Future<String> _uploadFileToStorage(
      File file, String folder, String extension) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('$folder/$fileName.$extension');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
  
  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle;
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _pickedImage = File(picked.path);
      });
    }
  }
    File? _pickedVideoFile;

Future<void> _pickingVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedVideoFile = File(result.files.single.path!);
      });
    }
  }
  Future<void> _pickVideo() async {
    await _pickingVideo();
    if (_pickedVideoFile != null) {
      final TextEditingController videoTitleController = TextEditingController();
      bool isFree = true;

      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('تعديل بيانات الفيديو'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: videoTitleController,
                      decoration: const InputDecoration(labelText: 'اسم الفيديو'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('هل الفيديو مجاني؟'),
                        Checkbox(
                          value: isFree,
                          onChanged: (value) {
                            setStateDialog(() {
                              isFree = value ?? true;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final videoTitle = videoTitleController.text.trim();
                      if (videoTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('يرجى إدخال اسم الفيديو')),
                        );
                        return;
                      }

                      final videoUrl  = await _uploadFileToStorage(_pickedVideoFile!, 'course_videos', 'mp4');

                      await FirebaseFirestore.instance
                          .collection('courses')
                          .doc(widget.courseId)
                          .collection('videos')
                          .add({
                        'title': videoTitle,
                        'videoUrl': videoUrl,
                        'thumbnail': '',
                        'isFree': isFree, // ✅ تمت الإضافة هنا
                      });

                      Navigator.of(context).pop();
                    },
                    child: const Text('حفظ'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }

  Future<Uint8List?> getThumbnail(String videoUrl) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: videoUrl,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );
    } catch (e) {
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  Widget _buildVideoItem(Map<String, dynamic> videoData) {
    return FutureBuilder<Uint8List?>(
      future: getThumbnail(videoData['videoUrl']),
      builder: (context, snapshot) {
        Widget leadingWidget;
        if (snapshot.connectionState == ConnectionState.waiting) {
          leadingWidget = Container(
            width: 60,
            height: 40,
            color: Colors.grey.shade300,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          leadingWidget = Image.memory(
            snapshot.data!,
            width: 60,
            height: 40,
            fit: BoxFit.cover,
          );
        } else {
          leadingWidget = const Icon(Icons.videocam, size: 40);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: leadingWidget,
            title: Text(videoData['title'] ?? 'عنوان غير متوفر'),
            subtitle: Text(videoData['isFree'] == true ? 'مجاني' : 'مدفوع'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(videoUrl: videoData['videoUrl']),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _generateCode() async {
    final newCode = _generateRandomCode(16);
    await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('codes')
        .add({'code': newCode, 'isUsed': false, 'usedBy': null});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم توليد كود جديد: $newCode')),
    );
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الكورس'),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('courses')
                .doc(widget.courseId)
                .collection('codes')
                .where('isUsed', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              return PopupMenuButton<String>(
                icon: const Icon(Icons.vpn_key),
                onSelected: (value) async {
                  if (value == 'generate') {
                    await _generateCode();
                  } else {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم نسخ الكود")),
                    );
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    const PopupMenuItem(
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
                  ];
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _pickedImage != null
                      ? FileImage(_pickedImage!)
                      : NetworkImage(widget.initialImageUrl) as ImageProvider,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.black, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _titleController,
                  readOnly: !_isEditingTitle,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الكورس',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isEditingTitle ? Icons.check : Icons.edit),
                onPressed: () {
                  setState(() {
                    _isEditingTitle = !_isEditingTitle;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('إضافة فيديو'),
            onPressed: _pickVideo,
          ),
          const SizedBox(height: 20),
          const Text(
            'الفيديوهات التابعة لهذا الكورس:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('courses')
                .doc(widget.courseId)
                .collection('videos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('لا توجد فيديوهات مضافة بعد.');
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildVideoItem(data);
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
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مشغل الفيديو')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
        onPressed: () {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        },
      ),
    );
  }
}
