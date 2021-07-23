import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Utilities {
  static const bool DEBUG = true;
  static const String BASE_URL = "";
  static const String HEADERS = "";
  static const String ImgKey = "Image Key";

  static customDivider({required BuildContext context, required Color divColor}) {
    return Container(
      width: Utilities.screenWidth(context),
      height: 0.5,
      color: divColor,
    );
  }

  static doubleBack(BuildContext context) {
    Utilities.closeActivity(context);
    Utilities.closeActivity(context);
  }

  static String base64String(Uint8List data) {
    return base64Encode(data);
  }

  static Image imageFromBase64String(String base64String) {
    return Image.memory(
      base64Decode(base64String),
      fit: BoxFit.fill,
    );
  }

  static fadeInImage({double? height, double? width, required String image, required String placeholderPath}) {
    return FadeInImage.assetNetwork(
      width: width,
      height: height,
      placeholder: "$placeholderPath",
      image: image,
      fit: BoxFit.cover,
    );
  }

  static double screenWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return screenWidth;
  }

  static double screenHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight;
  }

  static getSnackBar({required BuildContext context, required SnackBar snackBar}) {
    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static log(String message) {
    if (DEBUG) print(message);
  }

  static bool isEmpty(dynamic data) {
    if (data == null) {
      return true;
    }
    var d = data.toString().trim();
    if (d == "" || d == "[]" || d == "{}") {
      return true;
    }
    return false;
  }

  static Future<dynamic> openActivity(context, object) async {
    return await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => object),
    );
  }

  // static Future<dynamic> fadeOpenActivity(context, object) async {
  //   return await Navigator.of(context).push(
  //     new PageRouteBuilder(
  //       pageBuilder: (BuildContext context, _, __) {
  //         return object;
  //       },
  //       transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
  //         return FadeTransition(opacity: animation, child: child);
  //       },
  //     ),
  //   );
  // }

  static Future<Null> fadeReplaceActivity(context, object) async {
    return await Navigator.of(context).pushReplacement(
      new PageRouteBuilder(
        pageBuilder: (BuildContext context, _, __) {
          return object;
        },
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static void replaceActivity(context, object) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => object),
    );
  }

  static replaceNamedActivity(context, routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  static openNamedActivity(context, routeName) {
    Navigator.pushNamed(context, routeName);
  }

  static void removeStackActivity(context, object) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => object), (r) => false);
  }

  static void closeActivity(context) {
    Navigator.pop(context);
  }

  static void returnDataCloseActivity(context, object) {
    Navigator.pop(context, object);
  }

  static String encodeJson(dynamic jsonData) {
    return json.encode(jsonData);
  }

  static dynamic decodeJson(String jsonString) {
    return json.decode(jsonString);
  }

  static String shortString(String str, [int length = 50]) {
    if (str.length > length) {
      return str.substring(0, length) + "...";
    } else {
      return str;
    }
  }

  static Widget getLoadingAnimation(bool isLoading) {
    return PreferredSize(
        preferredSize: Size(double.infinity, 6.0),
        child: isLoading
            ? LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.5)),
              )
            : Container());
  }

  static Widget widgetWithLoading({bool visible: true, Widget? child}) {
    return Stack(children: <Widget>[
      child ?? Container(),
      Visibility(
          visible: visible,
          child: Container(
            color: Colors.black26,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ))
    ]);
  }

  static Widget myImage({required String imageUrl, double? width, double? height, fit}) {
    return Image.network(imageUrl, width: width, height: height, fit: fit ?? BoxFit.cover);
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static getCustomImage({int? width, int? height, required String link}) {
    return "https://www.goingnepal.com/image.php?src=$link&w=$width&h=$height&static=true";
  }

  static bool keyboardIsVisible(BuildContext context) {
    return (MediaQuery.of(context).viewInsets.bottom == 0.0);
  }

  static fieldFocusChange(BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }
}

class TransparentRoute extends PageRoute<void> {
  TransparentRoute({
    required this.builder,
    RouteSettings? settings,
  }) : super(settings: settings, fullscreenDialog: false);
  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 800);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}
