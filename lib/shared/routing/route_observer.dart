import 'package:flutter/widgets.dart';

/// Global RouteObserver for RouteAware screens (e.g., NoteEditorScreen).
///
/// Used to manage session entry/exit based on route visibility without
/// relying on GoRouter onExit. Register this with GoRouter observers.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
