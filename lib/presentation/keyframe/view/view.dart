import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie_editor/model/model.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                final b = rand.nextBool();
                final s = 100 * (0.5 + rand.nextDouble());
                final o = Offset(
                  rand.nextDouble() * (constraints.maxWidth - s),
                  rand.nextDouble() * (constraints.maxHeight - s),
                );
                final item = (b)
                    ? Item.circle(
                        color: _genColor(),
                        tl: o,
                        br: o + Offset(s, s),
                      )
                    : Item.rectangle(
                        color: _genColor(),
                        tl: o,
                        br: o + Offset(s, s),
                      );

                items.add(item);
                animations.add(_genAnimation(item));
              });
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  this.constraints = constraints;
                  return Stack(
                    children: [
                      ...items.asMap().map(
                        (i, item) {
                          return MapEntry(
                            i,
                            AnimatedBuilder(
                              animation: animationController,
                              builder: (context, child) {
                                return Positioned(
                                  left: item.tl.dx + animations[i].value.dx,
                                  top: item.tl.dy + animations[i].value.dy,
                                  child: Draggable(
                                    feedback: const SizedBox(),
                                    onDragUpdate: (details) {
                                      setState(() {
                                        items[i] =
                                            selected = item.move(details.delta);
                                      });
                                    },
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selected = item;
                                        });
                                      },
                                      child: ItemWidget(
                                        item: item,
                                        selected: item == selected,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ).values
                    ],
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

class ItemWidget extends StatelessWidget {
  final Item item;
  final bool selected;
  const ItemWidget({
    super.key,
    required this.item,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (item.br - item.tl).dx,
      height: (item.br - item.tl).dy,
      decoration: BoxDecoration(
        color: item.color,
        shape: item.map(
          circle: (e) => BoxShape.circle,
          rectangle: (e) => BoxShape.rectangle,
        ),
        border: selected ? Border.all(width: 4) : null,
      ),
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
