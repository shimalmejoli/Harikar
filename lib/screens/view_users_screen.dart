// lib/screens/view_users_screen.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../main.dart' show LocaleContext;
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/load_more_footer.dart';
import 'user_details_page.dart';

class ViewUsersScreen extends StatefulWidget {
  const ViewUsersScreen({Key? key}) : super(key: key);
  @override
  _ViewUsersScreenState createState() => _ViewUsersScreenState();
}

class _ViewUsersScreenState extends State<ViewUsersScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _approvedUsers = [];
  List<dynamic> _notApprovedUsers = [];
  List<dynamic> _newUsers = [];

  bool _isLoading = true;
  String _searchQuery = '';

  late TabController _tabController;

  /// get_users.php has no server-side paging — it returns every user in
  /// one response. So instead of slicing the list into pages we render a
  /// growing window: [_chunkSize] cards at a time, extended whenever the
  /// user scrolls near the bottom. Cards are built lazily and the heavy
  /// full-list rebuild that pagination caused is gone.
  static const int _chunkSize = 20;

  /// Distance (px) from the bottom that triggers the next chunk.
  static const double _loadMoreThreshold = 400;

  int _visibleApproved = _chunkSize, _totalApproved = 0;
  int _visibleNotApproved = _chunkSize, _totalNotApproved = 0;
  int _visibleNew = _chunkSize, _totalNew = 0;

  /// Search debounce — the endpoint returns ~300 records, so firing a
  /// request on every keystroke made typing feel sluggish.
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    AppLogger.info('ViewUsersScreen init', tag: 'VIEW_USERS');
    _tabController = TabController(length: 3, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching users, search: $_searchQuery', tag: 'VIEW_USERS');

    // Bypass HTTP cache: get_users.php sends Cache-Control headers
    // that would otherwise return a 5-minute-stale response after an
    // approval change, so the user wouldn't move to the right tab.
    final response = await ApiService.instance.get(
      AppConstants.getUsersEndpoint,
      queryParams: {
        'search': _searchQuery,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    if (!mounted) return;

    if (response.success && response.data != null) {
      final data = response.data!;
      if (data['status'] == 'success') {
        final users = data['data'] as List<dynamic>;
        AppLogger.info('Users loaded: ${users.length}', tag: 'VIEW_USERS');
        setState(() {
          _approvedUsers = users.where((u) => u['is_approved'] == 1).toList();
          _notApprovedUsers = users
              .where((u) =>
                  u['is_approved'] == 0 && u['subscription_expiry'] != null)
              .toList();
          _newUsers =
              users.where((u) => u['subscription_expiry'] == null).toList();
          _totalApproved = _approvedUsers.length;
          _totalNotApproved = _notApprovedUsers.length;
          _totalNew = _newUsers.length;
          // Fresh data → shrink each window back to the first chunk.
          _visibleApproved = _chunkSize;
          _visibleNotApproved = _chunkSize;
          _visibleNew = _chunkSize;
          _isLoading = false;
        });
      } else {
        AppLogger.error('Users API error: ${data['message']}',
            tag: 'VIEW_USERS');
        _snack('Error: ${data['message']}');
        setState(() => _isLoading = false);
      }
    } else {
      AppLogger.error('Users fetch failed: ${response.error}',
          tag: 'VIEW_USERS');
      _snack(response.error ?? 'Error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int userId) async {
    AppLogger.info('Deleting user: $userId', tag: 'VIEW_USERS');

    final response = await ApiService.instance.post(
      AppConstants.deleteUserEndpoint,
      fields: {'id': userId.toString()},
    );
    if (!mounted) return;

    if (response.success) {
      AppLogger.info('User deleted: $userId', tag: 'VIEW_USERS');
      _snack(S.viewUsersDeletedSnack.of(context), success: true);
      _fetchUsers();
    } else {
      AppLogger.error('Delete user failed: ${response.error}',
          tag: 'VIEW_USERS');
      _snack(response.error ?? 'Error');
    }
  }

  void _confirmDelete(int userId) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(S.viewUsersDeleteTitle.of(ctx)),
          content: Text(S.viewUsersDeleteContent.of(ctx)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(S.no.of(ctx)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteUser(userId);
              },
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: Text(S.yes.of(ctx)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                minimumSize: const Size(0, 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isArabic = context.isArabic;

    return AppScaffold(
      titleWidget: _buildSearchField(context),
      appBarBottom: _buildTabBar(context),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(
                  _approvedUsers,
                  _visibleApproved,
                  (v) => _visibleApproved = v,
                  S.viewUsersEmptyApproved.of(context),
                  isArabic,
                ),
                _buildList(
                  _notApprovedUsers,
                  _visibleNotApproved,
                  (v) => _visibleNotApproved = v,
                  S.viewUsersEmptyNotApproved.of(context),
                  isArabic,
                ),
                _buildList(
                  _newUsers,
                  _visibleNew,
                  (v) => _visibleNew = v,
                  S.viewUsersEmptyNew.of(context),
                  isArabic,
                ),
              ],
            ),
    );
  }

  // ── In-AppBar search field ──────────────────────────────────

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: TextField(
        style: const TextStyle(
            color: Colors.white, fontFamily: 'NotoKufi', fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: S.viewUsersSearchHint.of(context),
          hintStyle: const TextStyle(
              color: Colors.white60, fontFamily: 'NotoKufi', fontSize: 13),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Colors.white70, size: 18),
        ),
        onChanged: (v) {
          _searchQuery = v;
          _searchDebounce?.cancel();
          _searchDebounce =
              Timer(const Duration(milliseconds: 400), _fetchUsers);
        },
      ),
    );
  }

  // ── TabBar (passed as appBarBottom) ─────────────────────────

  PreferredSizeWidget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.white,
      indicatorWeight: 3,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(
        fontFamily: 'NotoKufi',
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'NotoKufi',
        fontSize: 12,
      ),
      tabs: [
        Tab(
            text:
                '${S.viewUsersTabApprovedPrefix.of(context)} ($_totalApproved)'),
        Tab(
            text:
                '${S.viewUsersTabNotApprovedPrefix.of(context)} ($_totalNotApproved)'),
        Tab(text: '${S.viewUsersTabNewPrefix.of(context)} ($_totalNew)'),
      ],
    );
  }

  // ── List + empty state ──────────────────────────────────────

  /// [users] is the FULL tab list; only the first [visible] entries are
  /// rendered. Scrolling near the bottom calls [setVisible] with a larger
  /// window, which grows the list in place — no page buttons, no refetch.
  Widget _buildList(
    List<dynamic> users,
    int visible,
    void Function(int) setVisible,
    String empty,
    bool isArabic,
  ) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.divider.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline_rounded,
                    size: 40, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                empty,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final shown = visible.clamp(0, users.length);
    final hasMore = shown < users.length;

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppTheme.accent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (hasMore &&
              n.metrics.axis == Axis.vertical &&
              n.metrics.pixels >=
                  n.metrics.maxScrollExtent - _loadMoreThreshold) {
            setState(() => setVisible(
                (shown + _chunkSize).clamp(0, users.length)));
          }
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          // +1 for the trailing loader / end-of-list line.
          itemCount: shown + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => i == shown
              ? LoadMoreFooter(
                  // The rows are already in memory, so the spinner would
                  // flash for a single frame — show the growth silently.
                  isLoading: false,
                  hasMore: hasMore,
                  showEndMessage: users.length > _chunkSize,
                )
              : _buildUserCard(users[i], isArabic),
        ),
      ),
    );
  }

  // ── User card ──────────────────────────────────────────────

  Widget _buildUserCard(dynamic user, bool isArabic) {
    final fmt = NumberFormat('#,###', 'en_US');
    final isApproved = (int.tryParse(user['is_approved'].toString()) ?? 0) == 1;
    final fullName =
        user['full_name']?.toString() ?? S.viewUsersUnknownName.of(context);
    final initial = fullName.isNotEmpty ? fullName[0] : '?';

    String formatDate(String? d) => (d == null || d.isEmpty)
        ? S.viewUsersNewBadge.of(context)
        : d.split(' ')[0];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'NotoKufi',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName,
                    style: AppTheme.headingSmall.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _approvalPill(isApproved),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          // Info grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                    child: _info(Icons.phone_rounded,
                        S.phoneNumberLabel.of(context),
                        user['phone_number'] ?? '—'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _info(Icons.location_city_rounded,
                        S.cityLabel.of(context), user['city'] ?? '—'),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: _info(
                      Icons.account_balance_wallet_rounded,
                      S.paymentAmountLabel.of(context),
                      fmt.format(double.tryParse(
                              user['payment_amount'].toString()) ??
                          0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _info(
                      Icons.date_range_rounded,
                      S.expiryDateLabel.of(context),
                      formatDate(user['subscription_expiry']),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          // Action footer
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusMd),
                bottomRight: Radius.circular(AppTheme.radiusMd),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _miniAction(
                  icon: Icons.edit_rounded,
                  color: AppTheme.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsPage(
                        userId: int.tryParse(user['id'].toString()) ?? 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _miniAction(
                  icon: Icons.delete_outline_rounded,
                  color: AppTheme.error,
                  onTap: () => _confirmDelete(
                      int.tryParse(user['id'].toString()) ?? 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalPill(bool isApproved) {
    final color = isApproved ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Icon(
        isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _miniAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withOpacity(0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
