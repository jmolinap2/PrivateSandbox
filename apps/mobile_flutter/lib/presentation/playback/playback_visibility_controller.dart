typedef PausePlayback = void Function();

/// Keeps media silent whenever its viewer is not the visible foreground route.
///
/// Visibility changes only pause playback. They never resume it: after
/// returning to a video, playback always requires an explicit user action.
class PlaybackVisibilityController {
  final PausePlayback _pause;

  bool _routeVisible = true;
  bool _appVisible = true;

  PlaybackVisibilityController(this._pause);

  bool get canStartAutomatically => _routeVisible && _appVisible;

  void setRouteVisible(bool visible) {
    _routeVisible = visible;
    if (!visible) _pause();
  }

  void setAppVisible(bool visible) {
    _appVisible = visible;
    if (!visible) _pause();
  }

  void stop() {
    _routeVisible = false;
    _pause();
  }
}
