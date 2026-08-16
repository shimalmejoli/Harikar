// lib/screens/UsersPage.dart
// Admin page — list users from get_users2.php, edit name/phone/password/approval

import 'package:flutter/material.dart';
import 'package:harikar/main.dart';

import '../core/app_constants.dart';
import '../core/app_logger.dart';
import '../core/app_strings.dart';
import '../core/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_scaffold.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchCtrl = TextEditingController();

  List<_User> _users = [];
  List<_User> _filteredUsers = [];
  bool _isLoading = true;
  bool _didFetch = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => _filterUsers(_searchCtrl.text));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      _fetchUsers();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    AppLogger.info('Fetching users (get_users2)', tag: 'USERS_PAGE');

    // Cache-bust so an edit (approval, password) is reflected
    // immediately on refetch, not after the HTTP cache expires.
    final r = await ApiService.instance.get(
      AppConstants.getUsers2Endpoint,
      queryParams: {
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
    if (!mounted) return;

    if (r.success && r.data != null) {
      // get_users2.php returns a bare JSON array. ApiService._decode
      // wraps it as `{status: 'success', data: [...]}` so the same
      // `r.data!['data']` pattern works as for normal endpoints.
      final list = (r.data!['data'] as List?) ?? const [];
      AppLogger.info('Users loaded: ${list.length}', tag: 'USERS_PAGE');
      setState(() {
        _users = list.map((e) => _User.fromJson(e)).toList();
        _filteredUsers = List.from(_users);
        _isLoading = false;
      });
    } else {
      AppLogger.error('Users fetch failed: ${r.error}', tag: 'USERS_PAGE');
      setState(() => _isLoading = false);
      _snack(context.isArabic
          ? 'خطأ في تحميل المستخدمين: ${r.error}'
          : 'هەڵە لە بارکردنی بەکارهێنەرەکان: ${r.error}');
    }
  }

  void _filterUsers(String q) {
    if (q.trim().isEmpty) {
      setState(() => _filteredUsers = List.from(_users));
    } else {
      final lower = q.toLowerCase();
      setState(() {
        _filteredUsers = _users.where((u) {
          return u.fullName.toLowerCase().contains(lower) ||
              u.phoneNumber.toLowerCase().contains(lower);
        }).toList();
      });
    }
  }

  // ── Edit dialog ───────────────────────────────────────────

  void _showEditDialog(_User user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    final passCtrl = TextEditingController(text: user.password);
    bool isApprovedLocal = user.isApproved;
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(S.usersPageEditTitle.of(ctx)),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(
                          fontFamily: 'NotoKufi', fontSize: 14),
                      decoration: InputDecoration(
                        labelText: S.fullNameLabel.of(ctx),
                        prefixIcon: const Icon(Icons.person_rounded,
                            color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? S.usersPageEnterName.of(ctx)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          fontFamily: 'NotoKufi', fontSize: 14),
                      decoration: InputDecoration(
                        labelText: S.usersPagePhoneLabel.of(ctx),
                        prefixIcon: const Icon(Icons.phone_rounded,
                            color: AppTheme.primary),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? S.usersPageEnterPhone.of(ctx)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: !isPasswordVisible,
                      style: const TextStyle(
                          fontFamily: 'NotoKufi', fontSize: 14),
                      decoration: InputDecoration(
                        labelText: S.usersPagePasswordLabel.of(ctx),
                        prefixIcon: const Icon(Icons.lock_rounded,
                            color: AppTheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setS(
                              () => isPasswordVisible = !isPasswordVisible),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? S.usersPageEnterPassword.of(ctx)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(color: AppTheme.divider, width: 1),
                      ),
                      child: SwitchListTile(
                        dense: true,
                        title: Text(
                          S.usersPageApprovedSwitch.of(ctx),
                          style: const TextStyle(
                            fontFamily: 'NotoKufi',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        secondary: Icon(
                          isApprovedLocal
                              ? Icons.verified_user_rounded
                              : Icons.gpp_maybe_rounded,
                          color: isApprovedLocal
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                        value: isApprovedLocal,
                        activeColor: AppTheme.success,
                        onChanged: (v) =>
                            setS(() => isApprovedLocal = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(S.usersPageCancelButton.of(ctx)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(ctx).pop();
                  await _updateUser(
                    user.id,
                    nameCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                    passCtrl.text.trim(),
                    isApprovedLocal,
                  );
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: Text(S.updateButton.of(ctx)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateUser(int id, String name, String phone, String password,
      bool isApproved) async {
    AppLogger.info('Updating user: $id', tag: 'USERS_PAGE');

    final r = await ApiService.instance.post(
      AppConstants.updateUser2Endpoint,
      jsonBody: {
        'id': id,
        'full_name': name,
        'phone_number': phone,
        'password': password,
        'is_approved': isApproved ? 1 : 0,
      },
    );

    if (!mounted) return;

    if (r.success) {
      AppLogger.info('User updated: $id', tag: 'USERS_PAGE');
      _snack(S.usersPageUpdateSuccess.of(context), success: true);
      _fetchUsers();
    } else {
      AppLogger.error('Update failed: ${r.error}', tag: 'USERS_PAGE');
      _snack(S.usersPageGenericError.of(context));
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? AppTheme.success : AppTheme.error,
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      titleWidget: _buildSearchField(context),
      footerIndex: 2,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : _filteredUsers.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  color: AppTheme.accent,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildUserCard(_filteredUsers[i]),
                  ),
                ),
    );
  }

  // ── In-AppBar search field ────────────────────────────────

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
        controller: _searchCtrl,
        style: const TextStyle(
            color: Colors.white, fontFamily: 'NotoKufi', fontSize: 14),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: S.usersPageSearchHint.of(context),
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
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
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
              S.usersPageEmpty.of(context),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── User card ─────────────────────────────────────────────

  Widget _buildUserCard(_User u) {
    final initial = u.fullName.isNotEmpty ? u.fullName[0] : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: () => _showEditDialog(u),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Avatar with initial
              Container(
                width: 48,
                height: 48,
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
                    fontSize: 20,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.fullName,
                      style: AppTheme.headingSmall.copyWith(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.phone_rounded,
                          size: 12, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          u.phoneNumber,
                          style: AppTheme.bodySmall.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Approval pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: u.isApproved
                      ? AppTheme.success.withOpacity(0.12)
                      : AppTheme.error.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      u.isApproved
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 12,
                      color: u.isApproved ? AppTheme.success : AppTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      u.isApproved
                          ? S.usersPageApprovedBadge.of(context)
                          : S.usersPageNotApprovedBadge.of(context),
                      style: TextStyle(
                        fontFamily: 'NotoKufi',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            u.isApproved ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── User model ────────────────────────────────────────────────

class _User {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String password;
  final bool isApproved;

  const _User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.isApproved,
  });

  factory _User.fromJson(Map<String, dynamic> j) {
    final appr = j['is_approved'];
    final bool flag = appr is bool
        ? appr
        : appr is num
            ? appr == 1
            : appr.toString() == '1';

    return _User(
      id: int.tryParse(j['id'].toString()) ?? 0,
      fullName: j['full_name'] ?? '',
      phoneNumber: j['phone_number'] ?? '',
      password: j['password'] ?? '',
      isApproved: flag,
    );
  }
}
