import 'package:flutter/material.dart';

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
    duration: const Duration(milliseconds: 1000),
  );
  late Animation<double> x;
  late Animation<double> y;

  final itemCount = 11;
  final itemExtent = 36.0;

  double scrollOffset = 0.0;
  double get timelineLength => itemCount * itemExtent;

  @override
  void initState() {
    super.initState();

    x = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 60.0),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 60.0, end: 10.0),
        weight: 1,
      ),
    ]).animate(animationController);

    y = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.0),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 60.0),
        weight: 1,
      ),
    ]).animate(animationController);

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(color: Colors.green),
                  Positioned(
                    child: AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        return Center(
                          child: Transform.translate(
                            offset: Offset(x.value, y.value),
                            child: Container(
                              color: Colors.red,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
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
              ],
            ),
            const Divider(),
            Stack(
              children: [
                SizedBox(
                  height: 150,
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      itemExtent: itemExtent,
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        return TimelineView(frameNumber: index * 10);
                      },
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Positioned(
                      top: 0,
                      bottom: 0,
                      left: itemExtent / 2 +
                          (timelineLength - itemExtent) *
                              animationController.value -
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
                      final w = timelineLength - itemExtent;
                      animationController.value += details.delta.dx / w;
                    },
                    onTapUp: (details) {
                      final w = timelineLength - itemExtent;
                      animationController.value = (details.localPosition.dx -
                              itemExtent / 2 +
                              scrollOffset) /
                          w;
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

class TimelineView extends StatelessWidget {
  final int frameNumber;
  const TimelineView({super.key, required this.frameNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 40,
          child: Center(
            child: Text('$frameNumber'),
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
    );
  }
}
