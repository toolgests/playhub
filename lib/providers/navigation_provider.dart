import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected bottom navigation tab: 0 Home, 1 Categories, 2 Favorites, 3 Settings.
class ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellTabProvider =
    NotifierProvider<ShellTabNotifier, int>(ShellTabNotifier.new);
