import 'package:spin_craze/extension/ext_context.dart';
import 'package:spin_craze/features/wallet_module/provider/wallet_provider.dart';
import 'package:spin_craze/utils/anaytics_manager.dart';
import 'package:spin_craze/utils/navigation_helper.dart';
import 'package:spin_craze/widgets/common_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class WalletHistoryScreen extends StatelessWidget {
  const WalletHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AnalyticsManager.instance.logScreenView(
      screenName: 'wallet_history',
      screenClass: 'WalletHistoryScreen',
    );
    return ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: const _WalletHistoryContent(),
    );
  }
}

class _WalletHistoryContent extends StatelessWidget {
  const _WalletHistoryContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        NavigationHelper().handleBackPress(context);
      },
      child: Scaffold(
        backgroundColor: context.themeColors.background,
        appBar: CommonAppBar(
          title: context.l10n.withdrawHistory,
          showBack: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: provider.getWithdrawStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.themeColors.primary,
                ),
              );
            }
            if (snapshot.hasError) {
              return _buildEmptyState(
                context,
                icon: Icons.error_outline_rounded,
                title: context.l10n.somethingWentWrong,
                subtitle: context.l10n.pleaseTryAgainLater,
                iconColor: context.themeColors.error,
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _buildEmptyState(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: context.l10n.noWithdrawalsYet,
                subtitle: context.l10n.withdrawalRequestsWillAppear,
                iconColor: context.themeColors.primary,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _WithdrawCard(data: data, index: index);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: iconColor.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: context.themeTextColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: context.themeTextColors.secondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int index;

  const _WithdrawCard({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final amount = data['amount'] ?? 0;
    final type = data['withdraw_type'] ?? '';
    final subType = data['withdraw_sub_type'] ?? '';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final createdAt = data['created_at'];
    final reason = data['reason'] as String?;

    DateTime? date;
    if (createdAt != null) {
      date = (createdAt as Timestamp).toDate();
    }

    final cfg = _StatusConfig.from(status, context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.themeColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // -- Left accent bar --
                Container(width: 4, color: cfg.accentColor),

                // -- Card content --
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount + badge row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Amount
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '\$ ',
                                    style: TextStyle(
                                      color: context.themeTextColors.secondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _formatAmount(amount),
                                    style: TextStyle(
                                      color: context.themeTextColors.primary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Status badge
                            _StatusBadge(cfg: cfg),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Divider
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: context.themeColors.divider,
                        ),

                        const SizedBox(height: 14),

                        // Meta rows
                        _MetaRow(
                          icon: Icons.account_balance_rounded,
                          label: context.l10n.method,
                          value: type.isNotEmpty ? type : '-',
                        ),
                        const SizedBox(height: 10),
                        _MetaRow(
                          icon: Icons.receipt_long_rounded,
                          label: context.l10n.type,
                          value: subType.isNotEmpty ? subType : '-',
                        ),
                        const SizedBox(height: 10),
                        _MetaRow(
                          icon: Icons.schedule_rounded,
                          label: context.l10n.date,
                          value: date != null ? _formatDate(date) : '-',
                        ),

                        // Reason row (only for rejected)
                        if (status == 'rejected' && reason != null) ...[
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.info_outline_rounded,
                            label: context.l10n.reason,
                            value: reason,
                            valueColor: const Color(0xFFE05252),
                          ),
                        ],

                        // Processing time row (approved)
                        if (status == 'approved') ...[
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: context.l10n.processed,
                            value: context.l10n.businessDays,
                            valueColor: const Color(0xFF4CAF82),
                          ),
                        ],

                        // Pending note
                        if (status == 'pending') ...[
                          const SizedBox(height: 10),
                          _MetaRow(
                            icon: Icons.hourglass_top_rounded,
                            label: context.l10n.statusNote,
                            value: context.l10n.underReview,
                            valueColor: const Color(0xFFE6A817),
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
    if (val >= 100000) {
      return '${(val / 100000).toStringAsFixed(1)}L';
    } else if (val >= 1000) {
      final parts = val.toStringAsFixed(0).split('');
      final reversed = parts.reversed.toList();
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

// ---------------------------------------------------------------------------
//  META ROW
// ---------------------------------------------------------------------------

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MetaRow({
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: context.themeColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.themeColors.border),
          ),
          child: Icon(icon, size: 13, color: context.themeTextColors.muted),
        ),
        const SizedBox(width: 10),

        Text(
          label,
          style: TextStyle(
            color: context.themeTextColors.muted,
            fontSize: 12.5,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  valueColor ??
                  context.themeTextColors.primary.withValues(alpha: 0.88),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  STATUS BADGE
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final _StatusConfig cfg;
  const _StatusBadge({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: cfg.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),

          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              cfg.label,
              style: TextStyle(
                color: cfg.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  STATUS CONFIG HELPER
// ---------------------------------------------------------------------------

class _StatusConfig {
  final Color accentColor;
  final String label;

  const _StatusConfig({required this.accentColor, required this.label});

  factory _StatusConfig.from(String status, BuildContext context) {
    switch (status) {
      case 'approved':
        return _StatusConfig(
          accentColor: const Color(0xFF4CAF82),
          label: context.l10n.approved,
        );
      case 'completed':
        return _StatusConfig(
          accentColor: const Color(0xFF4CAF82),
          label: context.l10n.approved,
        );
      case 'rejected':
        return _StatusConfig(
          accentColor: const Color(0xFFE05252),
          label: context.l10n.rejected,
        );
      default:
        return _StatusConfig(
          accentColor: const Color(0xFFE6A817),
          label: context.l10n.pending,
        );
    }
  }
}
