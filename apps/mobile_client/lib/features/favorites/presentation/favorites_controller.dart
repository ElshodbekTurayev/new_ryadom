import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/auth_controller.dart';

/// Favourite shop ids of the signed-in customer, newest first.
///
/// Stored on the device (the API has no favourites endpoint yet), one list
/// per user so a shared phone never mixes accounts. Shop details are always
/// fetched fresh, so only ids are kept.
final favoriteShopsProvider = NotifierProvider<FavoriteShopsController, List<String>>(FavoriteShopsController.new);

class FavoriteShopsController extends Notifier<List<String>> {
  static const _prefix = 'ryadom_favorite_shops_';

  String? _userId;

  /// Set once the user changed the list, so a slow initial load from storage
  /// never overwrites that change.
  bool _touched = false;

  @override
  List<String> build() {
    _userId = ref.watch(authControllerProvider.select((a) => a.valueOrNull?.id));
    _touched = false;
    if (_userId != null) _load(_userId!);
    return const [];
  }

  Future<void> _load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('$_prefix$userId') ?? const [];
      if (!_touched && _userId == userId) state = saved;
    } catch (_) {
      // No persistent storage (tests, private mode): favourites stay in memory.
    }
  }

  Future<void> _save() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_prefix$userId', state);
    } catch (_) {}
  }

  bool isFavorite(String shopId) => state.contains(shopId);

  /// Adds or removes [shopId]; returns true when it is now a favourite.
  bool toggle(String shopId) {
    _touched = true;
    final added = !state.contains(shopId);
    state = added ? [shopId, ...state] : [for (final id in state) if (id != shopId) id];
    _save();
    return added;
  }
}
