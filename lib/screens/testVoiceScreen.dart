import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:link_video_player/screens/command.dart';
import 'package:link_video_player/screens/speech_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picovoice/picovoice_error.dart';
import 'package:porcupine/porcupine_manager.dart';
import 'package:screenshot/screenshot.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

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
  List<Uint8List?> imageFile = [];
  // List<String> imageFile = [];
  ScreenshotController screenshotController = ScreenshotController();

  PorcupineManager? _porcupineManager;
  bool _listeningForCommand = false;

  ScrollController _sc = ScrollController();

  bool isListening = false;
  Uint8List? bytes;
  @override
  void initState() {
    super.initState();
    createPorcupineManager();
    print(widget.videoUrl);
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
    } else if (state == AppLifecycleState.paused) {
      print("THIS IS THE PAUSED STATE: $state");
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
                                child: imageFile[index] == null ? Container() : Image.memory(imageFile[index]!),
                              ),
                            );
                          }),
                ),
              ),
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    "$text",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              )
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          animate: isListening,
          endRadius: 75,
          glowColor: Theme.of(context).primaryColor,
          child: FloatingActionButton(
            // onPressed: toggleRecording,
            onPressed: () async {},
            tooltip: 'Mic',
            child: Icon(isListening ? Icons.mic : Icons.mic_none),
          ),
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
        ["jarvis", "picovoice", "alexa"],
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
      print("jarvis");
      _stopProcessing();
      text = "";
      toggleRecording();
    }
  }

  Future toggleRecording() => SpeechApi.toggleRecording(
          onResult: (text) => setState(() => this.text = text),
          onListening: (isListening) async {
            setState(() => this.isListening = isListening);
            print("Print: $isListening");
            if (!isListening) {
              Future.delayed(Duration(milliseconds: 500), () async {
                Utils.scanText(text);

                if (Utils.scanText(text) == "start") {
                  print(Utils.scanText(text));
                  _chewieController.play();
                  SpeechApi.stopListening();
                } else if (Utils.scanText(text) == "stop") {
                  print(Utils.scanText(text));

                  _chewieController.pause();
                  SpeechApi.stopListening();
                } else if (Utils.scanText(text) == "screenshot") {
                  _chewieController.pause();
                  SpeechApi.stopListening();

                  if (Platform.isAndroid) {
                    bytes = await VideoThumbnail.thumbnailData(
                      video: "${widget.videoUrl}", // Path of that video
                      imageFormat: ImageFormat.PNG,
                      quality: 100,
                      timeMs: videoPlayerController.value.position.inMilliseconds,
                    );

                    print(bytes);

                    if (bytes != null) {
                      if (imageFile.length == 0) {
                        imageFile.add(bytes);
                      } else {
                        if (imageFile.every((element) => element != bytes)) {
                          imageFile.add(bytes);
                        }
                      }
                      print(imageFile.length);
                      setState(() {});
                    }
                    _chewieController.play();
                  }
                }
              });
            }
            createPorcupineManager();
          }).then((data) {
        print("This is the data: $data");
      });
}
