import 'package:flutter/material.dart';
import 'package:link_video_player/base/utilities.dart';
import 'package:link_video_player/screens/testVoiceScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Home Screen"),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: TextFormField(
                  maxLines: 3,
                  controller: _urlController,
                  autofocus: false,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.text,
                  onChanged: (String? value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Video Url",
                    errorStyle: TextStyle(color: Colors.red),
                    focusedBorder: OutlineInputBorder(),
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    suffixIcon: _urlController.text == ""
                        ? null
                        : InkWell(
                            onTap: () {
                              FocusScope.of(context).requestFocus(FocusNode());

                              setState(() {
                                _urlController.clear();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  if (_urlController.text.trim() == "") {
                    Utilities.getSnackBar(
                      context: context,
                      snackBar: SnackBar(
                        content: Text("Enter a video URL"),
                        duration: Duration(milliseconds: 2500),
                      ),
                    );
                  } else {
                    FocusScope.of(context).requestFocus(FocusNode());
                    Utilities.openActivity(context, TestVideoScreen(videoUrl: "${_urlController.text.trim()}"));
                  }
                },
                child: Text("Open"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
