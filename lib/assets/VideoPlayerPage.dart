import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;

  const VideoPlayerPage({
    Key? key,
    required this.videoUrl,
    required this.videoTitle,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    await _controller.initialize();
    _controller.setVolume(_volume);
    _controller.play();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(position.inMinutes.remainder(60));
    final seconds = twoDigits(position.inSeconds.remainder(60));
    return '${twoDigits(position.inHours)}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.videoTitle)),
      body: _controller.value.isInitialized
          ? Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              children: [
                VideoPlayer(_controller),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenVideoPage(
                            controller: _controller,
                            volume: _volume,
                          ),
                        ),
                      );

                      // 🟢 الحل النهائي: إعادة تهيئة بعد الرجوع
                      final oldPosition = _controller.value.position;
                      _controller = VideoPlayerController.file(
                        File(widget.videoUrl),
                      );
                      await _controller.initialize();
                      await _controller.seekTo(oldPosition);
                      _controller.setVolume(_volume);
                      _controller.play();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, VideoPlayerValue value, _) {
              final duration = value.duration;
              final position = value.position;

              return Column(
                children: [
                  Row(
                    children: [
                      Text(_formatDuration(position)),
                      Expanded(
                        child: Slider(
                          min: 0,
                          max: duration.inMilliseconds.toDouble(),
                          value: position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                          onChanged: (value) {
                            _controller.seekTo(
                              Duration(milliseconds: value.toInt()),
                            );
                          },
                        ),
                      ),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.replay_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPos = position - const Duration(seconds: 10);
                          _controller.seekTo(newPos > Duration.zero ? newPos : Duration.zero);
                        },
                      ),
                      IconButton(
                        icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
                        onPressed: () {
                          value.isPlaying ? _controller.pause() : _controller.play();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.forward_10),
                        iconSize: 36,
                        onPressed: () {
                          final newPos = position + const Duration(seconds: 10);
                          _controller.seekTo(newPos < duration ? newPos : duration);
                        },
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_down),
                        onPressed: () {
                          setState(() {
                            _volume = (_volume - 0.1).clamp(0.0, 1.0);
                            _controller.setVolume(_volume);
                          });
                        },
                      ),
                      Text('الصوت: ${( _volume * 100 ).round()}%'),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          setState(() {
                            _volume = (_volume + 0.1).clamp(0.0, 1.0);
                            _controller.setVolume(_volume);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final double volume;

  const FullScreenVideoPage({
    Key? key,
    required this.controller,
    required this.volume,
  }) : super(key: key);

  @override
  State<FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.setVolume(widget.volume);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  String _formatDuration(Duration position) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(position.inMinutes.remainder(60));
    final seconds = twoDigits(position.inSeconds.remainder(60));
    return '${twoDigits(position.inHours)}:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ValueListenableBuilder(
                    valueListenable: widget.controller,
                    builder: (context, VideoPlayerValue value, _) {
                      final duration = value.duration;
                      final position = value.position;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Expanded(
                                  child: Slider(
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.grey,
                                    min: 0,
                                    max: duration.inMilliseconds.toDouble(),
                                    value: position.inMilliseconds
                                        .clamp(0, duration.inMilliseconds)
                                        .toDouble(),
                                    onChanged: (value) {
                                      widget.controller.seekTo(
                                        Duration(milliseconds: value.toInt()),
                                      );
                                    },
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
