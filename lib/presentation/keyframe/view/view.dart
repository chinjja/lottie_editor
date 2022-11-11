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

  double itemExtent = 36.0;
  double scrollOffset = 0.0;
  int framesPerItem = 10;
  ContextMode mode = ContextMode.view;

  Matrix4 _screenOrigin(BoxConstraints constraints) {
    final offset = constraints.biggest.center(Offset.zero);
    return Matrix4.translationValues(offset.dx, offset.dy, 0);
  }

  @override
  void initState() {
    super.initState();

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // final pixels = frameToPixels(frameCount);
        // scrollController.jumpTo(pixels);
      } else if (status == AnimationStatus.dismissed) {
        scrollController.jumpTo(scrollController.position.minScrollExtent);
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
    return (itemExtent / 10) * frame;
  }

  double _pixelsToFrame(double pixels) {
    return pixels / (itemExtent / 10);
  }

  double _pixelsToRate(double pixels) {
    final frame = _pixelsToFrame(pixels);
    return _frameToRate(frame);
  }

  List<Item> items = [];
  List<Animation<Offset>> animations = [];
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

  Animation<Offset> _genAnimation(Item item) {
    // return TweenSequence([
    //   ...item.keyframes.map(
    //     (e) => TweenSequenceItem(
    //       tween: Tween(begin: Offset.zero, end: const Offset(1, 1)),
    //       weight: 1,
    //     ),
    //   )
    // ]).animate(animationController);

    return TweenSequence(
      [
        TweenSequenceItem(
          tween: Tween(
              begin: Offset.zero,
              end: Offset(
                rand.nextDouble() * 200 - 100,
                rand.nextDouble() * 200 - 100,
              )),
          weight: 1.0,
        ),
      ],
    ).animate(animationController);
  }

  int? _hitTest(Matrix4 origin, Offset position) {
    int? hitIndex;
    for (int i = items.length - 1; i >= 0; i--) {
      final model = _modelItem(i);
      if (mode == ContextMode.edit && !model.selected) continue;

      if (model.hitTest(origin, position - animations[i].value)) {
        hitIndex = i;
        break;
      }
    }
    return hitIndex;
  }

  int? _hitTestForVertex(Matrix4 origin, Item item, Offset position) {
    final index = items.indexOf(item);
    return _modelItem(index)
        .hitTestForVertex(origin, position - animations[index].value);
  }

  ModelItem _modelItem(int i) {
    return ModelItem(
      item: items[i],
      selected: items[i] == selected,
      animation: Matrix4.translationValues(
        animations[i].value.dx,
        animations[i].value.dy,
        0,
      ),
    );
  }

  int? _dragIndex;

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
                      animations.add(_genAnimation(item));
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
                      animations.clear();
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
                        onTapDown: mode == ContextMode.view
                            ? (details) {
                                final hitIndex =
                                    _hitTest(origin, details.localPosition);
                                setState(() {
                                  if (hitIndex != null) {
                                    selected = items[hitIndex];
                                  } else {
                                    selected = null;
                                  }
                                });
                              }
                            : null,
                        onLongPress: () {
                          if (selected != null) {
                            setState(() {
                              mode = ContextMode.edit;
                            });
                          }
                        },
                        onPanStart: (details) {
                          if (mode == ContextMode.view) {
                            _dragIndex =
                                _hitTest(origin, details.localPosition);
                          } else {
                            _dragIndex = _hitTestForVertex(
                              origin,
                              selected!,
                              details.localPosition,
                            );
                          }
                        },
                        onPanUpdate: (details) {
                          final i = _dragIndex;
                          if (i != null) {
                            if (mode == ContextMode.view) {
                              setState(() {
                                items[i] =
                                    selected = items[i].move(details.delta);
                              });
                            } else {
                              setState(() {
                                final data = [...selected!.model.data];
                                data[i] = data[i] + details.delta;
                                final index = items.indexOf(selected!);
                                items[index] = selected =
                                    selected!.copyWith.model(data: data);
                              });
                            }
                          }
                        },
                        onPanEnd: (details) {
                          _dragIndex = null;
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
                TextButton(
                  onPressed: () {
                    animationController.stop();
                    if (animationController.duration!.inSeconds <= 1) return;
                    setState(() {
                      animationController.duration =
                          animationController.duration! -
                              const Duration(seconds: 1);
                    });
                  },
                  child: const Text('-1s'),
                ),
                TextButton(
                  onPressed: () {
                    animationController.stop();
                    if (animationController.duration!.inSeconds >= 10) return;
                    setState(() {
                      animationController.duration =
                          animationController.duration! +
                              const Duration(seconds: 1);
                    });
                  },
                  child: const Text('+1s'),
                ),
              ],
            ),
            const Divider(),
            Stack(
              children: [
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: itemExtent / 2),
                    itemCount: (frameCount + 120) ~/ 10,
                    itemExtent: itemExtent,
                    itemBuilder: (context, index) {
                      return TimelineTile(
                        frameCount: frameCount,
                        start: index * 10,
                        end: index * 10 + 10,
                      );
                    },
                  ),
                ),
                AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: itemExtent / 2 +
                          _rateToPixels(animationController.value) -
                          scrollOffset,
                      child: Container(
                        color: Colors.blue,
                        width: 2,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (details) {
                      animationController.value +=
                          _pixelsToRate(details.delta.dx);
                    },
                    onTapUp: (details) {
                      final dx = details.localPosition.dx;
                      animationController.value =
                          _pixelsToRate(dx - itemExtent / 2 - scrollOffset);
                    },
                    child: const SizedBox(height: 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

      final path = Path()..addOval(Rect.fromCircle(center: center, radius: 8));
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

  ModelPainter({
    required this.transform,
    required this.items,
    required this.mode,
  });

  @override
  bool? hitTest(Offset position) {
    for (int i = items.length - 1; i >= 0; i--) {
      final model = items[i];
      if (mode == ContextMode.edit && !model.selected) continue;

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
        paint.color = Colors.black;
        paint.style = PaintingStyle.fill;
        for (final p in model.item.model.data) {
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
  const ItemWidget({
    super.key,
    required this.transform,
    required this.items,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      willChange: true,
      painter: ModelPainter(transform: transform, items: items, mode: mode),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final int frameCount;
  final int start;
  final int end;
  const TimelineTile({
    super.key,
    required this.frameCount,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final offset = ((frameCount - start) / (end - start)).clamp(0, 10);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SizedBox(
              width: offset * constraints.maxWidth,
              height: double.infinity,
              child: const Opacity(
                opacity: 0.2,
                child: ColoredBox(
                  color: Colors.grey,
                ),
              ),
            ),
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(-constraints.maxWidth / 2 + 1, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Text('$start'),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: const [
                          Spacer(),
                          VerticalDivider(),
                          Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
