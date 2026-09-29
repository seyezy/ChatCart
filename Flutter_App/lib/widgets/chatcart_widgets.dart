import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/chatcart_theme.dart';

class ChatCartLogo extends StatelessWidget {
  final double size;
  const ChatCartLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Center(
          child: SvgPicture.asset(
            'assets/branding/chatcart-logo.svg',
            width: size * 113 / 137,
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticsLabel: 'ChatCart logo',
          ),
        ),
      );
}

class AppShell extends StatelessWidget {
  final String title;
  final Widget child;
  final int navIndex;
  final ValueChanged<int>? onNav;
  final List<Widget> actions;
  const AppShell(
      {super.key,
      required this.title,
      required this.child,
      this.navIndex = 0,
      this.onNav,
      this.actions = const []});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(title,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            actions: actions),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navIndex,
          onDestinationSelected: onNav,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: 'Chats'),
            NavigationDestination(
                icon: Icon(Icons.call_outlined),
                selectedIcon: Icon(Icons.call),
                label: 'Calls'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront),
                label: 'Marketplace'),
            NavigationDestination(
                icon: Icon(Icons.bolt_outlined),
                selectedIcon: Icon(Icons.bolt),
                label: 'Updates'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      );
}

class ChatAvatar extends StatelessWidget {
  final String initials;
  final bool online;
  final double size;
  final String? photoUrl;
  const ChatAvatar(this.initials,
      {super.key, this.online = false, this.size = 48, this.photoUrl});
  @override
  Widget build(BuildContext context) => Stack(children: [
        CircleAvatar(
            radius: size / 2,
            backgroundColor: ChatCartColors.brand100,
            child: photoUrl == null || photoUrl!.isEmpty
                ? Text(initials,
                    style: const TextStyle(
                        color: ChatCartColors.brand900,
                        fontWeight: FontWeight.w700))
                : ClipOval(
                    child: Image.network(photoUrl!,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Center(child: Text(initials))))),
        if (online)
          Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: ChatCartColors.brand400,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2)))),
      ]);
}

class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final IconData icon;
  final VoidCallback? onTap;
  final String? imageUrl;
  const ProductCard(
      {super.key,
      required this.title,
      required this.price,
      required this.icon,
      this.onTap,
      this.imageUrl});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: .55))),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                    height: 136,
                    width: double.infinity,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF151E1C)
                        : const Color(0xFFF3F4F6),
                    child: imageUrl == null
                        ? Center(
                            child: Icon(icon,
                                size: 72,
                                color: Theme.of(context).colorScheme.primary))
                        : Image.network(imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                                child: Icon(icon,
                                    size: 72,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary))))),
            Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(price,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                        SizedBox(width: 3),
                        Text('4.8', style: TextStyle(fontSize: 12))
                      ])
                    ]))
          ]),
        ),
      );
}
