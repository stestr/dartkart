library test_events;

import "package:unittest/unittest.dart";
import "package:unittest/html_enhanced_config.dart";
import "dart:math";
import "dart:async";
import "../../lib/src/core.dart";

class Named extends Object with PropertyObservable {
  String _name;

  String get name => _name;
  set name(String value) {
    var old = _name;
    _name = value;
    notify("name", old, value);
  }
}


main() {
  useHtmlEnhancedConfiguration();
  group("receiving notifications -", () {
    test("notifications aren't emitted unless there is a listener", () {
      listener(PropertyChangeEvent evt) {
        expect(evt.newValue,"name 2");
      }
      var named = new Named();
      // no listener registered yet - notification should not be
      // queued
      named.name = "name 1";

      var notification  = expectAsync1(listener);
      // add a listener
      var subscription = named.onPropertyChanged.listen(notification);

      // this should trigger a notification
      named.name = "name 2";
    });

    //TODO: write a test which shows that events aren't emitted if
    // all subscribers are paused
  });
}
