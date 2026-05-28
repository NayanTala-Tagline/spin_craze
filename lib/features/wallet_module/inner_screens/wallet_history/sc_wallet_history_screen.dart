import 'package:spin_craze/features/wallet_module/provider/sc_wallet_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/app_size.dart';
import 'package:spin_craze/utils/logger.dart';
import 'package:spin_craze/extension/ext_localization.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const Color _kBg = Color(0xFFEEF2F9);
const Color _kSurface = Colors.white;
const Color _kBorder = Color(0xFFD9E2F0);
const Color _kPrimary = Color(0xFF1164FF);
const Color _kTextPrimary = Color(0xFF0E1A2B);
const Color _kTextMuted = Color(0xFF6B7A92);
const Color _kSuccess = Color(0xFF22C55E);
const Color _kError = Color(0xFFE05252);
const Color _kWarning = Color(0xFFE6A817);
const Color _kDivider = Color(0xFFE2E8F2);

class ScWalletHistoryScreen extends StatelessWidget {
  const ScWalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'wallet_history',
      screenClass: 'ScWalletHistoryScreen',
    );
    return ChangeNotifierProvider(
      create: (_) => ScWalletProvider(),
      child: const _ScWalletHistoryContent(),
    );
  }
}

class _ScWalletHistoryContent extends StatelessWidget {
  const _ScWalletHistoryContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScWalletProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: CommonAppBar(title: context.l10n.withdrawHistory, showBack: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: provider.getWithdrawStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _kPrimary),
              );
            }
            if (snapshot.hasError) {
              'wallet_history stream error: ${snapshot.error}'.logD;
              return _buildEmptyState(
                icon: Icons.error_outline_rounded,
                title: context.l10n.somethingWentWrong,
                subtitle: context.l10n.tryAgainLater,
                iconColor: _kError,
              );
            }

            final docs = [...?snapshot.data?.docs]..sort((a, b) {
              final ad = (a.data() as Map<String, dynamic>)['created_at'];
              final bd = (b.data() as Map<String, dynamic>)['created_at'];
              if (ad is Timestamp && bd is Timestamp) return bd.compareTo(ad);
              if (ad is Timestamp) return -1;
              if (bd is Timestamp) return 1;
              return 0;
            });

            if (docs.isEmpty) {
              return _buildEmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: context.l10n.noWithdrawalsYet,
                subtitle: context.l10n.withdrawalsAppearHere,
                iconColor: _kPrimary,
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(
                AppSize.w20,
                AppSize.h16,
                AppSize.w20,
                AppSize.h32,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _ScWithdrawCard(data: data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppSize.sp72,
            height: AppSize.sp72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSize.r20),
              border: Border.all(color: iconColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: iconColor, size: AppSize.sp32),
          ),
          SizedBox(height: AppSize.h16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: _kTextPrimary,
              fontSize: AppSize.sp16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSize.h6),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: _kTextMuted,
              fontSize: AppSize.sp13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScWithdrawCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ScWithdrawCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = data['amount'] ?? 0;
    final type = data['withdraw_type'] ?? '';
    final subType = data['withdraw_sub_type'] ?? '';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final createdAt = data['created_at'];
    final reason = data['reason'] as String?;

    DateTime? date;
    if (createdAt is Timestamp) date = createdAt.toDate();

    final cfg = _ScStatusConfig.from(status, context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.h12),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(AppSize.r16),
          border: Border.all(color: _kBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSize.r16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: cfg.accentColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppSize.w14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '\$ ',
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      color: _kTextMuted,
                                      fontSize: AppSize.sp14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatAmount(amount),
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      color: _kTextPrimary,
                                      fontSize: AppSize.sp22,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            _ScStatusBadge(cfg: cfg),
                          ],
                        ),
                        SizedBox(height: AppSize.h12),
                        Container(height: 1, color: _kDivider),
                        SizedBox(height: AppSize.h12),
                        _ScMetaRow(
                          icon: Icons.account_balance_rounded,
                          label: context.l10n.withdrawMethod,
                          value: type.isNotEmpty ? type : '-',
                        ),
                        SizedBox(height: AppSize.h10),
                        _ScMetaRow(
                          icon: Icons.receipt_long_rounded,
                          label: context.l10n.withdrawType,
                          value: subType.isNotEmpty ? subType : '-',
                        ),
                        SizedBox(height: AppSize.h10),
                        _ScMetaRow(
                          icon: Icons.schedule_rounded,
                          label: context.l10n.withdrawDate,
                          value: date != null ? _formatDate(date) : '-',
                        ),
                        if (status == 'rejected' && reason != null) ...[
                          SizedBox(height: AppSize.h10),
                          _ScMetaRow(
                            icon: Icons.info_outline_rounded,
                            label: context.l10n.withdrawReason,
                            value: reason,
                            valueColor: _kError,
                          ),
                        ],
                        if (status == 'approved' || status == 'completed') ...[
                          SizedBox(height: AppSize.h10),
                          _ScMetaRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: context.l10n.withdrawProcessed,
                            value: context.l10n.processingDays,
                            valueColor: _kSuccess,
                          ),
                        ],
                        if (status == 'pending') ...[
                          SizedBox(height: AppSize.h10),
                          _ScMetaRow(
                            icon: Icons.hourglass_top_rounded,
                            label: context.l10n.statusNote,
                            value: context.l10n.underReview,
                            valueColor: _kWarning,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    final num val = (amount is num) ? amount : num.tryParse('$amount') ?? 0;
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) {
      final reversed = val.toStringAsFixed(0).split('').reversed.toList();
      final result = <String>[];
      for (int i = 0; i < reversed.length; i++) {
        if (i > 0 && i % 3 == 0) result.add(',');
        result.add(reversed[i]);
      }
      return result.reversed.join();
    }
    return '$val';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final min = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$min $period';
  }
}

class _ScMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ScMetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSize.sp28,
          height: AppSize.sp28,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FD),
            borderRadius: BorderRadius.circular(AppSize.r8),
            border: Border.all(color: _kBorder),
          ),
          child: Icon(icon, size: AppSize.sp14, color: _kTextMuted),
        ),
        SizedBox(width: AppSize.w10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SFPro',
            color: _kTextMuted,
            fontSize: AppSize.sp12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: AppSize.w8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: valueColor ?? _kTextPrimary,
              fontSize: AppSize.sp12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScStatusBadge extends StatelessWidget {
  final _ScStatusConfig cfg;
  const _ScStatusBadge({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.w10,
        vertical: AppSize.h4,
      ),
      decoration: BoxDecoration(
        color: cfg.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.r100),
        border: Border.all(color: cfg.accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: AppSize.sp6,
            height: AppSize.sp6,
            decoration: BoxDecoration(
              color: cfg.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppSize.w6),
          Text(
            cfg.label,
            style: TextStyle(
              fontFamily: 'SFPro',
              color: cfg.accentColor,
              fontSize: AppSize.sp11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScStatusConfig {
  final Color accentColor;
  final String label;

  const _ScStatusConfig({required this.accentColor, required this.label});

  factory _ScStatusConfig.from(String status, BuildContext context) {
    switch (status) {
      case 'approved':
      case 'completed':
        return _ScStatusConfig(accentColor: _kSuccess, label: context.l10n.statusApproved);
      case 'rejected':
        return _ScStatusConfig(accentColor: _kError, label: context.l10n.statusRejected);
      default:
        return _ScStatusConfig(accentColor: _kWarning, label: context.l10n.statusPending);
    }
  }
}
