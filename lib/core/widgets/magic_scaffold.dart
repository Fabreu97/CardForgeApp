import 'package:flutter/material.dart';

import 'magic_symbols.dart';

/// Base scaffold for every screen: dark background with the row of gold-framed
/// symbols at the top ([MagicSymbols]).
///
/// - With `appBar`: it stays transparent, the symbols sit right below it and the
///   `body` starts below the symbols.
/// - Without `appBar` (Splash, Login): the symbols sit below the status bar and
///   the `body` fills the rest; a SafeArea inside the body will not add the top
///   space twice.
/// - [showSymbols] can be turned off for a screen that needs the whole area.
class MagicScaffold extends StatelessWidget {
  const MagicScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.showSymbols = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final bool showSymbols;

  /// Space between the symbols and the content below them.
  static const double _symbolsGap = 8;

  @override
  Widget build(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    final width = MediaQuery.sizeOf(context).width;

    final appBarInset =
        appBar == null ? 0.0 : statusBar + appBar!.preferredSize.height;
    final symbolsTop = appBar == null ? statusBar : appBarInset;
    final symbolsBlock =
        showSymbols ? MagicSymbols.heightFor(width) + _symbolsGap : 0.0;
    final bodyTop = showSymbols ? symbolsTop + symbolsBlock : appBarInset;

    // The symbols already used the status bar space, so a SafeArea inside the
    // body must not add it again.
    final content = showSymbols && appBar == null
        ? MediaQuery.removePadding(context: context, removeTop: true, child: body)
        : body;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      drawer: drawer,
      body: Stack(
        children: [
          if (showSymbols)
            Positioned(
              top: symbolsTop,
              left: 0,
              right: 0,
              child: const MagicSymbols(),
            ),
          Positioned.fill(top: bodyTop, child: content),
        ],
      ),
    );
  }
}
