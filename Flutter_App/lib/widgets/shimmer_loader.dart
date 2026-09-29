import 'package:flutter/material.dart';

enum SkeletonLayout { list, products, product, conversation, profile, form }

/// Animation is presentation-only; loading state remains owned by the Bloc.
class ShimmerLoader extends StatefulWidget {
  final SkeletonLayout layout;
  final bool inline;
  const ShimmerLoader(
      {super.key, this.layout = SkeletonLayout.list, this.inline = false});
  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      animation.stop();
    } else {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xff28382f) : const Color(0xffe3ebe6);
    final highlight = dark ? const Color(0xff415349) : const Color(0xfff7faf8);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Loading content',
      liveRegion: true,
      child: ExcludeSemantics(
          child: IgnorePointer(
              child: AnimatedBuilder(
        animation: animation,
        child: _skeleton(),
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-3 + animation.value * 6, -0.3),
            end: Alignment(-1 + animation.value * 6, 0.3),
            colors:
                reducedMotion ? [base, base, base] : [base, highlight, base],
            stops: const [0, .5, 1],
          ).createShader(bounds),
          child: child,
        ),
      ))),
    );
  }

  Widget _skeleton() {
    final children = <Widget>[];
    switch (widget.layout) {
      case SkeletonLayout.products:
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .72),
          itemBuilder: (_, index) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Expanded(child: _Bone()),
            const SizedBox(height: 12),
            const _Bone(height: 14),
            const SizedBox(height: 8),
            const FractionallySizedBox(
                widthFactor: .55, child: _Bone(height: 18)),
          ]),
        );
      case SkeletonLayout.product:
        children.addAll(const [
          _Bone(height: 280),
          SizedBox(height: 24),
          _Bone(height: 26),
          SizedBox(height: 12),
          FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: .4,
              child: _Bone(height: 22)),
          SizedBox(height: 28)
        ]);
        children.addAll(List.generate(
            4,
            (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: _Bone(height: 14))));
      case SkeletonLayout.profile:
        children.addAll(const [
          Center(child: _Bone(height: 88, width: 88, radius: 44)),
          SizedBox(height: 18),
          Center(child: _Bone(height: 22, width: 180)),
          SizedBox(height: 12),
          Center(child: _Bone(height: 14, width: 130)),
          SizedBox(height: 32)
        ]);
        children.addAll(List.generate(5, (_) => _row()));
      case SkeletonLayout.form:
        children.addAll(
            const [_Bone(height: 24, width: 180), SizedBox(height: 24)]);
        children.addAll(List.generate(
            5,
            (_) => const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: _Bone(height: 54))));
      case SkeletonLayout.conversation:
        children.addAll(List.generate(
            7,
            (index) => Align(
                  alignment: index.isEven
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                      widthFactor: index % 3 == 0 ? .72 : .5,
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: _Bone(height: index.isEven ? 64 : 42))),
                )));
      case SkeletonLayout.list:
        children.addAll(List.generate(widget.inline ? 3 : 7, (_) => _row()));
    }
    if (widget.inline) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: children));
    }
    return ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: children);
  }

  Widget _row() => const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(children: [
        _Bone(height: 48, width: 48, radius: 24),
        SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FractionallySizedBox(widthFactor: .7, child: _Bone(height: 16)),
          SizedBox(height: 10),
          _Bone(height: 12),
        ])),
      ]));
}

class _Bone extends StatelessWidget {
  final double? width;
  final double height, radius;
  const _Bone({this.width, this.height = double.infinity, this.radius = 12});
  @override
  Widget build(BuildContext context) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(radius)));
}
