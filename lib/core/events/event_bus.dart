import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'app_event.dart';

class EventBus {
  final _streamControllers = <String, StreamController<AppEvent>>{};
  
  Stream<T> on<T extends AppEvent>() {
    final controller = _getStreamController(T.toString());
    return controller.stream.where((event) => event is T).cast<T>();
  }
  
  void publish(AppEvent event) {
    final controller = _getStreamController(event.eventType);
    controller.add(event);
  }
  
  StreamController<AppEvent> _getStreamController(String eventType) {
    if (!_streamControllers.containsKey(eventType)) {
      _streamControllers[eventType] = StreamController<AppEvent>.broadcast();
    }
    return _streamControllers[eventType]!;
  }
  
  void dispose() {
    for (var controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
  }
}

// Riverpod provider for EventBus
final eventBusProvider = Provider((ref) => EventBus());