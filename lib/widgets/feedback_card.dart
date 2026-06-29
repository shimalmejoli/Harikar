// lib/widgets/feedback_card.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';

class FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const FeedbackCard({
    required this.feedback,
    required this.onDelete,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
  }

  String _formatPhone(String phone) {
    String n = phone.replaceAll(RegExp(r'\D'), '');
    if (n.startsWith('0')) n = n.substring(1);
    return '964$n';
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri.parse('https://wa.me/${_formatPhone(phone)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatTimestamp(String? ts) {
    if (ts == null || ts.isEmpty) return '';
    try {
      final d = DateTime.parse(ts);
      return '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = feedback['name'] ?? '';
    final phone = feedback['phone_number'] ?? '';
    final msg = feedback['message'] ?? 'پەیام نادیارە';
    final ts = _formatTimestamp(feedback['timestamp']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primary.withOpacity(0.12),
                    child: Text(
                      name.isNotEmpty ? _initials(name) : '?',
                      style: const TextStyle(
                        fontFamily: 'NotoKufi',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : 'ناوی بەکارهێنەر',
                          style: const TextStyle(
                            fontFamily: 'NotoKufi',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _openWhatsApp(context, phone),
                          child: Row(children: [
                            const FaIcon(FontAwesomeIcons.whatsapp,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 5),
                            Text(
                              phone.isNotEmpty
                                  ? phone
                                  : 'ژمارەی مۆبایل نادیارە',
                              style: const TextStyle(
                                fontFamily: 'NotoKufi',
                                fontSize: 13,
                                color: Colors.blueAccent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 22),
                    onPressed: onDelete,
                    tooltip: 'سڕینەوەی فیدباک',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // ── Message ──────────────────────────────────
              Text(
                msg,
                style: const TextStyle(
                  fontFamily: 'NotoKufi',
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              if (ts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ts,
                    style: TextStyle(
                      fontFamily: 'NotoKufi',
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
