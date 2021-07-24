class Command {
  static final all = [start, stop, takeScreenshot];

  static const start = "start";
  static const stop = "stop";
  static const takeScreenshot = "screenshot";
}

class Utils {
  static String? scanText(String rawText) {
    final text = rawText.toLowerCase();

    if (text.contains(Command.start)) {
      final body = startPlayer(text: text, command: Command.start);
      print("THIS IS THE START BODY: $body");
      return body;
    } else if (text.contains(Command.stop)) {
      final body = startPlayer(text: text, command: Command.stop);
      print("THIS IS THE STOP BODY: $body");
      return body;
    } else if (text.contains(Command.takeScreenshot)) {
      final body = startPlayer(text: text, command: Command.takeScreenshot);
      print("THIS IS THE STOP BODY: $body");
      return body;
    }
    return null;
  }

  static String? startPlayer({required String text, required String command}) {
    final indexCommand = text.indexOf(command);

    if (indexCommand == -1) {
      return null;
    } else {
      return text;
    }
  }
}
