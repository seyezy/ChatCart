import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatcart_ui/widgets/shimmer_loader.dart';

void main() {
  testWidgets('all skeletons fit small phones in light and dark themes',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final brightness in Brightness.values) {
      for (final layout in SkeletonLayout.values) {
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Scaffold(body: ShimmerLoader(layout: layout))));
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: '$brightness $layout');
        expect(find.bySemanticsLabel('Loading content'), findsOneWidget);
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'inline skeleton fits a parent scroll view and reduced motion settles',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: ShimmerLoader(inline: true))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
