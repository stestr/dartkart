library test_map;

import "test_layer_control.dart" as test_layer_control;
import "test_pan_behaviour.dart" as test_pan_behaviour;
import "test_map_viewport.dart" as test_map_viewport;
import "test_map_control.dart" as test_map_control;

main() {
  test_layer_control.main();
  test_pan_behaviour.main();
  test_map_viewport.main();
  test_map_control.main();
}