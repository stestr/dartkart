

import "layer/base_test.dart" as base_test;
import "map/map_viewport_test.dart" as map_viewport_test;
import "geometry/point_test.dart" as point_test;
import "geometry/features_test.dart" as features_test;
import "map/layer_control_test.dart" as layer_control_test;
import "map/map_control_test.dart" as map_control_test;
import "map/pan_behaviour_test.dart" as pan_behaviour_test;


main() {
  base_test.main();
  map_viewport_test.main();
  point_test.main();
  features_test.main();
  layer_control_test.main();
  map_control_test.main();
  pan_behaviour_test.main();
}



