// lib/screens/view_users_screen.dart

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

  int _currentPageApproved = 1, _rowsPerPageApproved = 10, _totalApproved = 0;
  int _currentPageNotApproved = 1,
      _rowsPerPageNotApproved = 10,
      _totalNotApproved = 0;
  int _currentPageNew = 1, _rowsPerPageNew = 10, _totalNew = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.info('ViewUsersScreen init', tag: 'VIEW_USERS');
    _tabController = TabController(length: 3, vsync: this);
    // Rebuild pagination footer when active tab changes (it tracks
    // the focused tab to know which page/perPage state to mutate).
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchUsers();
  }

  @override
  void dispose() {
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

  // ── Pagination helpers ───────────────────────────────────────

  List<dynamic> _page(List<dynamic> list, int page, int perPage) {
    final start = (page - 1) * perPage;
    if (start >= list.length) return [];
    final end = (start + perPage).clamp(0, list.length);
    return list.sublist(start, end);
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
          : Column(children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      _page(_approvedUsers, _currentPageApproved,
                          _rowsPerPageApproved),
                      S.viewUsersEmptyApproved.of(context),
                      isArabic,
                    ),
                    _buildList(
                      _page(_notApprovedUsers, _currentPageNotApproved,
                          _rowsPerPageNotApproved),
                      S.viewUsersEmptyNotApproved.of(context),
                      isArabic,
                    ),
                    _buildList(
                      _page(_newUsers, _currentPageNew, _rowsPerPageNew),
                      S.viewUsersEmptyNew.of(context),
                      isArabic,
                    ),
                  ],
                ),
              ),
              _buildPagination(context),
            ]),
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
          setState(() {
            _searchQuery = v;
            _currentPageApproved =
                _currentPageNotApproved = _currentPageNew = 1;
          });
          _fetchUsers();
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

  Widget _buildList(List<dynamic> users, String empty, bool isArabic) {
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
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildUserCard(users[i], isArabic),
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

  // ── Pagination footer (per-tab state) ───────────────────────

  Widget _buildPagination(BuildContext context) {
    final tabIdx = _tabController.index;
    int page, perPage, total;
    switch (tabIdx) {
      case 0:
        page = _currentPageApproved;
        perPage = _rowsPerPageApproved;
        total = _totalApproved;
        break;
      case 1:
        page = _currentPageNotApproved;
        perPage = _rowsPerPageNotApproved;
        total = _totalNotApproved;
        break;
      default:
        page = _currentPageNew;
        perPage = _rowsPerPageNew;
        total = _totalNew;
    }
    final totalPages = ((total / perPage).ceil()).clamp(1, 9999);
    final canPrev = page > 1;
    final canNext = page < totalPages;

    void setPage(int p) => setState(() {
          switch (tabIdx) {
            case 0:
              _currentPageApproved = p;
              break;
            case 1:
              _currentPageNotApproved = p;
              break;
            default:
              _currentPageNew = p;
          }
        });

    void setPerPage(int p) => setState(() {
          switch (tabIdx) {
            case 0:
              _rowsPerPageApproved = p;
              _currentPageApproved = 1;
              break;
            case 1:
              _rowsPerPageNotApproved = p;
              _currentPageNotApproved = 1;
              break;
            default:
              _rowsPerPageNew = p;
              _currentPageNew = 1;
          }
        });

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.bottomNavShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _rowsPerPagePill(context, perPage, setPerPage),
              _pageNavigator(context, page, totalPages, total, canPrev, canNext,
                  setPage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowsPerPagePill(
    BuildContext context,
    int perPage,
    void Function(int) setPerPage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              S.workListShowLabel.of(context),
              style: const TextStyle(
                fontFamily: 'NotoKufi',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: perPage,
                isDense: true,
                iconSize: 16,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 2),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white),
                ),
                dropdownColor: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                selectedItemBuilder: (_) => [10, 20, 50]
                    .map((r) => Center(
                          child: Text(
                            '$r',
                            style: const TextStyle(
                              fontFamily: 'NotoKufi',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ))
                    .toList(),
                items: [10, 20, 50]
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text('$r',
                              style: const TextStyle(
                                fontFamily: 'NotoKufi',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              )),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setPerPage(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageNavigator(
    BuildContext context,
    int page,
    int totalPages,
    int total,
    bool canPrev,
    bool canNext,
    void Function(int) setPage,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // chevron_right visually points → ("back/previous" in RTL).
          _navIconButton(
            icon: Icons.chevron_right_rounded,
            enabled: canPrev,
            onTap: () => setPage(page - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$page / $totalPages',
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1.1,
                  ),
                ),
                Text(
                  '$total ${S.workListResultsSuffix.of(context)}',
                  style: const TextStyle(
                    fontFamily: 'NotoKufi',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          _navIconButton(
            icon: Icons.chevron_left_rounded,
            enabled: canNext,
            onTap: () => setPage(page + 1),
          ),
        ],
      ),
    );
  }

  Widget _navIconButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppTheme.primary : AppTheme.divider.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
