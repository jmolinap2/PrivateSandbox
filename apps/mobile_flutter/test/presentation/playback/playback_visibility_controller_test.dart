import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/presentation/playback/playback_visibility_controller.dart';

void main() {
  test('covering or leaving the video always requests a pause', () {
    var pauses = 0;
    final controller = PlaybackVisibilityController(() => pauses++);

    expect(controller.canStartAutomatically, isTrue);

    controller.setRouteVisible(false);
    expect(pauses, 1);
    expect(controller.canStartAutomatically, isFalse);

    controller.setRouteVisible(true);
    expect(pauses, 1, reason: 'returning must never auto-resume');
    expect(controller.canStartAutomatically, isTrue);

    controller.stop();
    expect(pauses, 2);
    expect(controller.canStartAutomatically, isFalse);
  });

  test('backgrounding pauses and returning does not invoke playback', () {
    var pauses = 0;
    final controller = PlaybackVisibilityController(() => pauses++);

    controller.setAppVisible(false);
    expect(pauses, 1);
    expect(controller.canStartAutomatically, isFalse);

    controller.setAppVisible(true);
    expect(pauses, 1);
    expect(controller.canStartAutomatically, isTrue);
  });

  test('initialization cannot auto-play behind another route', () {
    var pauses = 0;
    final controller = PlaybackVisibilityController(() => pauses++);

    controller.setRouteVisible(false);

    expect(pauses, 1);
    expect(controller.canStartAutomatically, isFalse);
  });
}
