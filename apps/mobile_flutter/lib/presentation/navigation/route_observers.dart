import 'package:flutter/material.dart';

/// Notifies media viewers when another route covers them.
///
/// A global observer is intentional here: a video can remain mounted while a
/// dialog, bottom sheet, or another page is pushed above it. Mounted does not
/// mean visible, so relying only on `dispose` can leave its audio playing.
final vaultRouteObserver = RouteObserver<ModalRoute<dynamic>>();
