import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChewieFileItem extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final bool looping;
  const ChewieFileItem({Key? key, required this.videoPlayerController, this.looping = false}) : super(key: key);

  @override
  _ChewieFileItemState createState() => _ChewieFileItemState();
}

class _ChewieFileItemState extends State<ChewieFileItem> {
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    // Wrapper on top of the videoPlayerController
    _chewieController = ChewieController(
        allowFullScreen: false,
        videoPlayerController: widget.videoPlayerController,
        aspectRatio: 16 / 9,
        autoInitialize: true,
        autoPlay: true,
        looping: widget.looping,
        placeholder: Container(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.white),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // IMPORTANT to dispose of all the used resources
    widget.videoPlayerController.dispose();
    _chewieController.dispose();
  }
}
