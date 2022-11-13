import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lottie_editor/model/model.dart';

part 'view.freezed.dart';

class KeyframeView extends StatelessWidget {
  const KeyframeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class KeyframeEditor extends StatefulWidget {
  const KeyframeEditor({super.key});

  @override
  State<KeyframeEditor> createState() => _KeyframeEditorState();
}

enum ContextMode {
  view,
  edit,
}

class _KeyframeEditorState extends State<KeyframeEditor>
    with SingleTickerProviderStateMixin {
  final scrollController = ScrollController();
  late final animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  double frameWidth = 4;
  double keyframeWidth = 4;
  double scrollOffset = 0.0;
  ContextMode mode = ContextMode.view;

  Matrix4 _screenOrigin(BoxConstraints constraints) {
    final offset = constraints.biggest.center(Offset.zero);
    return Matrix4.translationValues(offset.dx, offset.dy, 0);
  }

  @override
  void initState() {
    super.initState();

    animationController.addStatusListener((status) {
      switch (status) {
        case AnimationStatus.dismissed:
          _restore();
          scrollController.jumpTo(scrollController.position.minScrollExtent);
          break;
        case AnimationStatus.forward:
        case AnimationStatus.reverse:
          _restore();
          break;
        case AnimationStatus.completed:
          break;
      }
      setState(() {});
    });
    scrollController.addListener(() {
      setState(() {
        scrollOffset = scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    animationController.dispose();
    super.dispose();
  }

  int get frameCount => animationController.duration!.inMilliseconds ~/ 30;
  double _rateToFrame(double rate) {
    return (frameCount * rate);
  }

  double _rateToPixels(double rate) {
    final frame = _rateToFrame(rate);
    return _frameToPixels(frame);
  }

  double _frameToRate(double frame) {
    return frame / frameCount;
  }

  double _frameToPixels(double frame) {
    return frameWidth * frame;
  }

  double _pixelsToFrame(double pixels) {
    return pixels / frameWidth;
  }

  double _pixelsToRate(double pixels) {
    final frame = _pixelsToFrame(pixels);
    return _frameToRate(frame);
  }

  List<Item> items = [];
  List<Animation<double>> xAnimations = [];
  List<Animation<double>> yAnimations = [];
  Map<String, Animation<double>> _map = {};
  Item? selected;
  final rand = math.Random();
  int lastId = 1;

  Color _genColor() {
    return Color.fromARGB(
      192,
      rand.nextInt(256),
      rand.nextInt(256),
      rand.nextInt(256),
    );
  }

  Map<String, Animation<double>> _buildAnimation(Item item) {
    if (item.keyframes.isEmpty) {
      return {
        'x': Tween(begin: 0.0, end: 0.0).animate(animationController),
        'y': Tween(begin: 0.0, end: 0.0).animate(animationController),
      };
    }
    Map<String, Animation<double>> result = {};
    for (final e in item.keyframes.entries) {
      List<TweenSequenceItem<double>> list = [];
      final frames = [...e.value]..sort((a, b) => a.frame.compareTo(b.frame));
      for (int i = 0; i < frames.length; i++) {
        final keyframe = frames[i];
        if (list.isEmpty) {
          list.add(
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: keyframe.value,
              ),
              weight: (keyframe.frame + 1) / frameCount,
            ),
          );
        }
        if (i < frames.length - 1) {
          final nextKeyframe = frames[i + 1];
          list.add(
            TweenSequenceItem(
              tween: Tween(
                begin: keyframe.value,
                end: nextKeyframe.value,
              ),
              weight: (nextKeyframe.frame - keyframe.frame) / frameCount,
            ),
          );
        } else if (keyframe.frame < frameCount) {
          list.add(
            TweenSequenceItem(
              tween: Tween(
                begin: keyframe.value,
                end: keyframe.value,
              ),
              weight: (frameCount - keyframe.frame) / frameCount,
            ),
          );
        }
      }
      if (list.isEmpty) {
        result[e.key] =
            Tween(begin: 0.0, end: 0.0).animate(animationController);
      } else {
        result[e.key] = TweenSequence(list).animate(animationController);
      }
    }
    return result;
  }

  int? _hitTest(Matrix4 origin, Offset position) {
    int? hitIndex;
    for (int i = items.length - 1; i >= 0; i--) {
      final model = _modelItem(i);
      if (mode == ContextMode.edit && !model.selected) continue;

      if (model.hitTest(origin,
          position - Offset(xAnimations[i].value, yAnimations[i].value))) {
        hitIndex = i;
        break;
      }
    }
    return hitIndex;
  }

  int? _hitTestForVertex(Matrix4 origin, Item item, Offset position) {
    final index = items.indexOf(item);
    return _modelItem(index).hitTestForVertex(origin,
        position - Offset(xAnimations[index].value, yAnimations[index].value));
  }

  ModelItem _modelItem(int i) {
    return ModelItem(
      item: items[i],
      selected: items[i] == selected,
      animation: Matrix4.translationValues(
        xAnimations[i].value,
        yAnimations[i].value,
        0,
      ),
    );
  }

  int? _vertexIndex;
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: mode == ContextMode.view
          ? AppBar(
              title: const Text('View'),
              actions: [
                IconButton(
                  onPressed: () {
                    final scale = rand.nextDouble() * 50 + 50;
                    const origin = Offset.zero;
                    final startRadian = rand.nextDouble() * math.pi;
                    final n = rand.nextInt(4) + 3;
                    final stepRadian = math.pi * 2 / n;
                    List<Offset> vs = [];
                    for (int i = 0; i < n; i++) {
                      final radian = startRadian + stepRadian * i;
                      final x = math.cos(radian);
                      final y = math.sin(radian);
                      vs.add(Offset(x, y) * scale + origin);
                    }
                    final model = Model(
                      origin: origin,
                      data: vs,
                    );
                    final item = Item(
                      id: lastId,
                      color: _genColor(),
                      model: model,
                      transform: Matrix4.identity(),
                    );
                    setState(() {
                      lastId++;
                      items.add(item);
                      _map = _buildAnimation(item);
                      xAnimations.add(_map['x']!);
                      yAnimations.add(_map['y']!);
                      selected = item;
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  onPressed: selected != null
                      ? () {
                          setState(() {
                            mode = ContextMode.edit;
                            _vertexIndex = null;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.edit),
                ),
                PopupMenuButton(
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'clear',
                        child: Text('Clear'),
                      ),
                    ];
                  },
                  onSelected: (value) {
                    setState(() {
                      items.clear();
                      xAnimations.clear();
                      yAnimations.clear();
                      selected = null;
                      lastId = 1;
                    });
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text('Editor'),
              backgroundColor: Colors.lightBlue,
              leading: BackButton(
                onPressed: () {
                  setState(() {
                    mode = ContextMode.view;
                  });
                },
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final origin = _screenOrigin(constraints);
                  return InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.1,
                    maxScale: 10.0,
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: GestureDetector(
                        onTapDown: (details) {
                          if (mode == ContextMode.view) {
                            final index =
                                _hitTest(origin, details.localPosition);
                            setState(() {
                              if (index != null) {
                                selected = items[index];
                              } else {
                                selected = null;
                              }
                              _selectedIndex = index;
                            });
                          } else {
                            final index = _hitTestForVertex(
                              origin,
                              selected!,
                              details.localPosition,
                            );
                            setState(() {
                              if (index != null) {
                                _vertexIndex = index;
                              }
                            });
                          }
                        },
                        onLongPress: () {
                          if (selected != null) {
                            setState(() {
                              mode = ContextMode.edit;
                              _vertexIndex = null;
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          if (mode == ContextMode.view) {
                            final i = _selectedIndex;
                            if (i == null) return;
                            setState(() {
                              items[i] =
                                  selected = items[i].move(details.delta);
                            });
                          } else {
                            final i = _vertexIndex;
                            if (i == null) return;
                            setState(() {
                              final data = [...selected!.model.data];
                              data[i] = data[i] + details.delta;
                              final index = items.indexOf(selected!);
                              items[index] = selected =
                                  selected!.copyWith.model(data: data);
                            });
                          }
                        },
                        child: AnimatedBuilder(
                            animation: animationController,
                            builder: (context, child) {
                              return ItemWidget(
                                transform: origin,
                                mode: mode,
                                items: items
                                    .asMap()
                                    .map((i, e) => MapEntry(i, _modelItem(i)))
                                    .values
                                    .toList(),
                                selectedIndex: _vertexIndex,
                              );
                            }),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    animationController.stop();
                    if (animationController.duration!.inSeconds >= 10) return;
                    setState(() {
                      animationController.duration =
                          animationController.duration! +
                              const Duration(seconds: 1);

                      final item = selected;
                      if (item != null) {
                        int index = items.indexOf(item);
                        items[index] =
                            selected = item.copyWith(keyframes: item.keyframes);
                        _map = _buildAnimation(items[index]);
                        xAnimations[index] = _map['x']!;
                        yAnimations[index] = _map['y']!;
                      }
                    });
                  },
                  child: const Text('+1s'),
                ),
                TextButton(
                  onPressed: () {
                    animationController.stop();
                    if (animationController.duration!.inSeconds <= 1) return;
                    setState(() {
                      animationController.duration =
                          animationController.duration! -
                              const Duration(seconds: 1);

                      final item = selected;
                      if (item != null) {
                        int index = items.indexOf(item);
                        items[index] =
                            selected = item.copyWith(keyframes: item.keyframes);
                        _map = _buildAnimation(items[index]);
                        xAnimations[index] = _map['x']!;
                        yAnimations[index] = _map['y']!;
                      }
                    });
                  },
                  child: const Text('-1s'),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (animationController.isCompleted) {
                      animationController.reset();
                    }
                    if (animationController.isAnimating) {
                      animationController.stop();
                    } else {
                      animationController.forward();
                    }
                  },
                  icon: animationController.isAnimating
                      ? const Icon(Icons.stop)
                      : const Icon(Icons.play_arrow),
                ),
                IconButton(
                  onPressed: () {
                    animationController.reset();
                  },
                  icon: const Icon(Icons.replay),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    final item = selected;
                    if (item != null) {
                      final keyframes = {...item.keyframes};
                      final v = item.transform.getTranslation();
                      keyframes
                          .putIfAbsent(
                              'x',
                              () => SplayTreeSet(
                                  (a, b) => a.frame.compareTo(b.frame)))
                          .add(Keyframe(
                            property: 'x',
                            frame:
                                _rateToFrame(animationController.value).toInt(),
                            value: v.x,
                          ));
                      keyframes
                          .putIfAbsent(
                              'y',
                              () => SplayTreeSet(
                                  (a, b) => a.frame.compareTo(b.frame)))
                          .add(Keyframe(
                            property: 'y',
                            frame:
                                _rateToFrame(animationController.value).toInt(),
                            value: v.y,
                          ));

                      int index = items.indexOf(item);
                      setState(() {
                        items[index] = selected = item.copyWith(
                          keyframes: keyframes,
                        );
                        _map = _buildAnimation(items[index]);
                        xAnimations[index] = _map['x']!;
                        yAnimations[index] = _map['y']!;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
                const IconButton(
                  onPressed: null,
                  icon: Icon(Icons.remove),
                ),
              ],
            ),
            const Divider(),
            SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: Stack(
                children: [
                  SizedBox(
                    width: frameCount * frameWidth * 2,
                    height: 150,
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: frameWidth * 5,
                    child: SizedBox(
                      width: frameCount * frameWidth,
                      child: Container(
                        color: Colors.grey.withAlpha(96),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        frameCount ~/ 10 * 2,
                        (index) => SizedBox(
                          width: frameWidth * 10,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  '${index * 10}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Expanded(
                                child: VerticalDivider(),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: 0,
                        bottom: 0,
                        left: frameWidth * 5 +
                            _rateToPixels(animationController.value),
                        child: Container(
                          color: Colors.blue,
                          width: 2,
                        ),
                      );
                    },
                  ),
                  for (final keyframe
                      in selected?.keyframes['x'] ?? <Keyframe>{})
                    Positioned(
                      key: ValueKey(keyframe.frame),
                      top: 0,
                      bottom: 0,
                      left: frameWidth * 5 +
                          keyframe.frame * frameWidth +
                          keyframeWidth / 2,
                      child: Center(
                        child: Container(
                          width: keyframeWidth,
                          height: keyframeWidth,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 0,
                    left: frameWidth * 5,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        _restore();
                        animationController.value +=
                            _pixelsToRate(details.delta.dx);
                      },
                      onTapUp: (details) {
                        _restore();
                        final dx = details.localPosition.dx;
                        animationController.value = _pixelsToRate(dx);
                      },
                      child: const SizedBox(height: 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _restore() {
    if (selected != null) {
      final idx = items.indexOf(selected!);
      items[idx] =
          selected = items[idx].copyWith(transform: Matrix4.identity());
    }
  }
}

@freezed
class ModelItem with _$ModelItem {
  const factory ModelItem({
    required Item item,
    required Matrix4 animation,
    @Default(false) bool selected,
  }) = _ModelItem;
}

extension ModelItemX on ModelItem {
  bool hitTest(Matrix4 view, Offset position) {
    final path = Path()..addPolygon(item.model.data, true);
    final m = view * item.transform;
    return path.transform(m.storage).contains(position);
  }

  int? hitTestForVertex(Matrix4 view, Offset position) {
    for (int i = 0; i < item.model.data.length; i++) {
      final center = item.model.data[i];

      final path = Path()..addOval(Rect.fromCircle(center: center, radius: 24));
      final m = view * item.transform;
      if (path.transform(m.storage).contains(position)) {
        return i;
      }
    }
    return null;
  }
}

class ModelPainter extends CustomPainter {
  final Matrix4 transform;
  final List<ModelItem> items;
  final ContextMode mode;
  final int? selectedIndex;

  ModelPainter({
    required this.transform,
    required this.items,
    required this.mode,
    required this.selectedIndex,
  });

  @override
  bool? hitTest(Offset position) {
    if (mode == ContextMode.edit) return null;
    for (int i = items.length - 1; i >= 0; i--) {
      final model = items[i];

      if (mode == ContextMode.view) {
        if (model.hitTest(transform * model.animation, position)) {
          return true;
        }
      } else {
        if (model.hitTestForVertex(transform * model.animation, position) !=
            null) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.transform(transform.storage);

    final paint = Paint();
    paint.color = Colors.black;

    final h = Offset(size.width, 0) * 10;
    final v = Offset(0, size.height) * 10;
    canvas.drawLine(-h, h, paint);
    canvas.drawLine(-v, v, paint);

    for (final model in items) {
      if (mode == ContextMode.edit && !model.selected) continue;

      canvas.save();
      canvas.transform(model.animation.storage);
      canvas.transform(model.item.transform.storage);

      final path = Path()..addPolygon(model.item.model.data, true);

      paint.color = model.item.color;
      paint.style = PaintingStyle.fill;
      canvas.drawPath(path, paint);

      if (model.selected) {
        paint.color = Colors.black;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawPath(path, paint);
      }

      paint.color = Colors.black;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(model.item.model.origin, 2, paint);

      if (mode == ContextMode.edit) {
        paint.style = PaintingStyle.fill;
        for (int i = 0; i < model.item.model.data.length; i++) {
          if (i == selectedIndex) {
            paint.color = Colors.orange;
          } else {
            paint.color = Colors.black;
          }
          final p = model.item.model.data[i];
          canvas.drawCircle(p, 4, paint);
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ModelPainter oldDelegate) {
    return transform != oldDelegate.transform ||
        items != oldDelegate.items ||
        mode != oldDelegate.mode;
  }
}

class ItemWidget extends StatelessWidget {
  final Matrix4 transform;
  final List<ModelItem> items;
  final ContextMode mode;
  final int? selectedIndex;
  const ItemWidget({
    super.key,
    required this.transform,
    required this.items,
    required this.mode,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      willChange: true,
      painter: ModelPainter(
        transform: transform,
        items: items,
        mode: mode,
        selectedIndex: selectedIndex,
      ),
    );
  }
}

class TickUnit {
  bool integers;
  double _factor = 1.0;
  double _power = 0.0;
  final double size;
  TickUnit(this.size, {this.integers = true});

  @override
  bool operator ==(Object other) {
    return other is TickUnit && size == other.size;
  }

  @override
  int get hashCode => size.hashCode;

  TickUnit getLargerTickUnit(TickUnit unit) {
    TickUnit t = getCeilingTickUnit(unit);
    if (t == unit) {
      _next();
      t = TickUnit(_tickSize);
    }
    return t;
  }

  TickUnit getCeilingTickUnit(TickUnit unit) {
    if (size.isInfinite) {
      throw Exception("Must be finite.");
    }
    _power = (math.log(unit.size) / math.ln10).ceilToDouble();
    if (integers) {
      _power = math.max(_power, 0);
    }
    _factor = 1;
    bool done = false;
    while (!done) {
      done = !_previous();
      if (_tickSize < unit.size) {
        _next();
        done = true;
      }
    }

    return TickUnit(_tickSize);
  }

  double get _tickSize => _factor * math.pow(10, _power);

  bool _next() {
    if (_factor == 1) {
      _factor = 2;
      return true;
    }
    if (_factor == 2) {
      _factor = 5;
      return true;
    }
    if (_factor == 5) {
      if (_power == 300) {
        return false;
      }
      _power++;
      _factor = 1;
      return true;
    }
    throw Exception("We should never get here.");
  }

  bool _previous() {
    if (_factor == 1) {
      if (integers && _power == 0 || _power == -300) {
        return false;
      }
      _factor = 5;
      _power--;
      return true;
    }
    if (_factor == 2) {
      _factor = 1;
      return true;
    }
    if (_factor == 5) {
      _factor = 2;
      return true;
    }
    throw Exception("We should never get here.");
  }
}
