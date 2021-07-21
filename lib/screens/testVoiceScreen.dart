import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picovoice/picovoice_error.dart';
import 'package:porcupine/porcupine_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';

class TestVideoScreen extends StatefulWidget {
  final String videoUrl;
  final bool looping;
  const TestVideoScreen({Key? key, required this.videoUrl, this.looping = false}) : super(key: key);

  @override
  _TestVideoScreenState createState() => _TestVideoScreenState();
}

class _TestVideoScreenState extends State<TestVideoScreen> with WidgetsBindingObserver {
  // TextEditingController _urlController = TextEditingController();
  late ChewieController _chewieController;
  late VideoPlayerController videoPlayerController;
  String mediaUrl = '';
  // final bool looping = false;
  String text = "";

  File imagePath = File("");
  List<String> imageFile = [];
  ScreenshotController screenshotController = ScreenshotController();

  PorcupineManager? _porcupineManager;
  bool _listeningForCommand = false;

  ScrollController _sc = ScrollController();

  @override
  void initState() {
    super.initState();
    createPorcupineManager();
    videoPlayerController = VideoPlayerController.network('${widget.videoUrl}')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });

    _chewieController = ChewieController(
        allowFullScreen: true,
        videoPlayerController: videoPlayerController,
        aspectRatio: 16 / 9,
        autoInitialize: true,
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

    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive) {
      print("THIS IS THE INACTIVE STATE: $state");
      await _stopProcessing();
      await _porcupineManager?.delete();
      _porcupineManager = null;
    } else if (state == AppLifecycleState.resumed) {
      print("THIS IS THE RESUMED STATE: $state");
      createPorcupineManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text("Video Player"),
            ],
          ),
        ),
        body: SingleChildScrollView(
          reverse: true,
          child: Column(
            children: <Widget>[
              Center(
                child: Screenshot(
                  controller: screenshotController,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Chewie(controller: _chewieController),
                  ),
                ),
              ),
              Container(
                height: 200,
                color: Colors.blue[100],
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: imageFile.length == 0
                      ? Center(
                          child: Text(
                            "No Screenshots",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          controller: _sc,
                          shrinkWrap: true,
                          itemCount: imageFile.length,
                          reverse: true,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                ),
                                child: File(imageFile[index]).existsSync()
                                    ? Image.file(
                                        File(imageFile[index]),
                                      )
                                    : Container(),
                              ),
                            );
                          }),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    text == "Take Screenshot" ? "$text (${imageFile.length})".toUpperCase() : "$text".toUpperCase(),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: text == "start"
                            ? Colors.green
                            : text == "stop"
                                ? Colors.red
                                : Colors.orange),
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
          key: UniqueKey(),
          heroTag: "F1",
          onPressed: () async {
            _listeningForCommand ? createPorcupineManager() : await _porcupineManager?.stop();
          },
          tooltip: 'Mic',
          child: Icon(!_listeningForCommand ? Icons.play_arrow : Icons.stop),
        ),
      ),
    );
  }

  Future<void> _stopProcessing() async {
    await _porcupineManager?.stop();
  }

  void createPorcupineManager() async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywords(
        ["computer", "picovoice", "alexa"],
        _wakeWordCallback,
      );

      _porcupineManager?.start();
    } on PvError catch (err) {
      // handle porcupine init error
      print("Failed to initialize Porcupine: ${err.message}");
    }
  }

  Future<void> _wakeWordCallback(int keywordIndex) async {
    if (keywordIndex == 0) {
      print("computer");
      setState(() {
        text = "start";
        _listeningForCommand = true;
      });
      _chewieController.play();
    } else if (keywordIndex == 1) {
      print("picovoice");

      _chewieController.pause();
      setState(() {
        text = "stop";
        _listeningForCommand = false;
      });
    } else if (keywordIndex == 2) {
      print("alexa");
      _chewieController.pause();
      await screenshotController.capture(delay: const Duration(milliseconds: 10)).then((Uint8List? image) async {
        if (image != null) {
          if (Platform.isAndroid) {
            final directory = await getExternalStorageDirectory();
            print("This is the directory path: ${directory?.path}");
            imagePath = await File('${directory?.path}/${DateTime.now()}.png').create();
            await imagePath.writeAsBytes(image);

            if (imageFile.length == 0) {
              imageFile.add(imagePath.path);
            } else {
              if (imageFile.every((element) => element != imagePath.path)) {
                imageFile.add(imagePath.path);
              }
            }
            setState(() {});
          }

          /// Share Plugin
          // await Share.shareFiles([imagePath.path]);
        }
        setState(() {
          text = "Take Screenshot";
          _listeningForCommand = false;
        });
      });
    }
  }
}
