import "dart:html";
import "package:dartkart/src/map.dart";

var out;

log(msg) {
  out.value = "${out.value}\n$msg";
  out.scrollTop = out.scrollHeight;
}

main() {
  var pad = query("#mouse-pad");
  out = query("#log");
  var gestures = new MouseEventStream.from(pad);
  gestures.stream.listen((g) => log(g.toString()));
}


