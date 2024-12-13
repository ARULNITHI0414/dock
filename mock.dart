import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Dock<IconData>(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (e) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.primaries[e.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(e, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    this.items = const [],
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> 
    with TickerProviderStateMixin {
  /// [T] items being manipulated.
  late final List<T> _items = widget.items.toList();
  
  /// Animation controller for smooth reordering
  late List<AnimationController> _controllers;
  
  @override
  void initState() {
    super.initState();
    // Create animation controllers for each item
    _controllers = List.generate(
      _items.length, 
      (_) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          _items.length,
          (index) => AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: Offset.zero,
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _controllers[index],
                    curve: Curves.easeInOut,
                  ),
                ),
                child: GestureDetector(
                  key: ValueKey(_items[index]),
                  child: Draggable<T>(
                    data: _items[index],
                    feedback: widget.builder(_items[index]),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: widget.builder(_items[index]),
                    ),
                    child: DragTarget<T>(
                      builder: (context, candidateData, rejectedData) {
                        return widget.builder(_items[index]);
                      },
                      onWillAcceptWithDetails: (droppedItem) => droppedItem != null,
                      onAcceptWithDetails: (droppedItem) {
                        setState(() {
                          // Find indices of the dragged and dropped items
                          final draggedIndex = _items.indexOf(droppedItem.data);
                          final targetIndex = _items.indexOf(_items[index]);

                          // Reorder items
                          if (draggedIndex != -1 && 
                              targetIndex != -1 && 
                              draggedIndex != targetIndex) {
                            // Remove the dragged item and insert at new position
                            final item = _items.removeAt(draggedIndex);
                            _items.insert(targetIndex, item);

                            // Animate the reordering
                            for (var i = 0; i < _controllers.length; i++) {
                              _controllers[i].forward(from: 0);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}