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
  final view = Matrix4.identity();
  ContextMode mode = ContextMode.view;

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
  late BoxConstraints constraints;
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

  int? _hitTest(Offset position) {
    int? hitIndex;
    for (int i = items.length - 1; i >= 0; i--) {
      final model = _modelItem(i);
      if (mode == ContextMode.edit && !model.selected) continue;

      if (model.hitTest(position - animations[i].value)) {
        hitIndex = i;
        break;
      }
    }
    return hitIndex;
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
                    setState(() {
                      final center = Offset(
                        rand.nextDouble(),
                        rand.nextDouble(),
                      );
                      const model = Model(
                        origin: Offset(50, 50),
                        data: [
                          Offset.zero,
                          Offset(100, 0),
                          Offset(100, 100),
                          Offset(0, 100),
                        ],
                      );
                      final item = Item(
                        id: lastId,
                        color: _genColor(),
                        model: model,
                        transform:
                            Matrix4.translationValues(center.dx, center.dy, 0),
                      );
                      lastId++;
                      items.add(item);
                      animations.add(_genAnimation(item));
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
                )
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
                  this.constraints = constraints;
                  return ClipRect(
                    child: Transform(
                      transform: view,
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: GestureDetector(
                          onTapDown: mode == ContextMode.view
                              ? (details) {
                                  final hitIndex =
                                      _hitTest(details.localPosition);
                                  setState(() {
                                    if (hitIndex != null) {
                                      selected = items[hitIndex];
                                    } else {
                                      selected = null;
                                    }
                                  });
                                }
                              : null,
                          onPanStart: (details) {
                            _dragIndex = _hitTest(details.localPosition);
                          },
                          onPanUpdate: (details) {
                            final i = _dragIndex;
                            if (i != null) {
                              setState(() {
                                items[i] =
                                    selected = items[i].move(details.delta);
                              });
                            }
                          },
                          onPanEnd: (details) {
                            _dragIndex = null;
                          },
                          child: AnimatedBuilder(
                              animation: animationController,
                              builder: (context, child) {
                                return ItemWidget(
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
  bool hitTest(Offset position) {
    final path = Path()..addPolygon(item.model.data, true);
    return path.transform(item.transform.storage).contains(position);
  }
}

class ModelPainter extends CustomPainter {
  final List<ModelItem> items;
  final ContextMode mode;

  ModelPainter({required this.items, required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

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
    return items != oldDelegate.items || mode != oldDelegate.mode;
  }
}

class ItemWidget extends StatelessWidget {
  final List<ModelItem> items;
  final ContextMode mode;
  const ItemWidget({
    super.key,
    required this.items,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      willChange: true,
      painter: ModelPainter(items: items, mode: mode),
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
