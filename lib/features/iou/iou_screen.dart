import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/iou_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/iou.dart';
import '../../presentation/widgets/shared_widgets.dart';
import 'add_iou_dialog.dart';

class IouScreen extends ConsumerStatefulWidget {
  const IouScreen({super.key});

  @override
  ConsumerState<IouScreen> createState() => _IouScreenState();
}

class _IouScreenState extends ConsumerState<IouScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAddIou(BuildContext context, [IouType type = IouType.lent]) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => AddIouDialog(defaultType: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(iouSummaryProvider);
    final lentAsync = ref.watch(lentIousProvider);
    final borrowedAsync = ref.watch(borrowedIousProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Lending & Borrowing', style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            onPressed: () => _openAddIou(context, _tabController.index == 0 ? IouType.lent : IouType.borrowed),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textDisabled,
          indicatorColor: AppColors.textPrimary,
          tabs: const [
            Tab(text: "You're Owed"),
            Tab(text: "You Owe"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Summary Banner
          Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.borderSubtle),
              boxShadow: AppColors.shadowSm,
            ),
            child: summaryAsync.when(
              loading: () => const ShimmerBox(width: double.infinity, height: 48),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('YOU ARE OWED', style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(summary.totalLentPaise),
                        style: AppTypography.titleMedium.copyWith(color: AppColors.lent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 32, color: AppColors.borderSubtle),
                  Column(
                    children: [
                      const Text('YOU OWE', style: AppTypography.caption),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(summary.totalBorrowedPaise),
                        style: AppTypography.titleMedium.copyWith(color: AppColors.borrowed, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lists
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIouList(lentAsync, IouType.lent),
                _buildIouList(borrowedAsync, IouType.borrowed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIouList(AsyncValue<List<IouRecord>> asyncList, IouType type) {
    return asyncList.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 68),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: type == IouType.lent ? Icons.arrow_outward_rounded : Icons.call_received_rounded,
            title: type == IouType.lent ? 'No money lent' : 'No money borrowed',
            subtitle: type == IouType.lent
                ? 'Keep track of money you lend to friends or family.'
                : 'Track loans or money you borrowed from others.',
            actionText: type == IouType.lent ? '+ Record Money Lent' : '+ Record Money Borrowed',
            onActionTap: () => _openAddIou(context, type),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final record = items[index];
            final color = type == IouType.lent ? AppColors.lent : AppColors.borrowed;
            final bgColor = type == IouType.lent ? AppColors.lentLight : AppColors.borrowedLight;
            final isSettled = record.status == IouStatus.settled;

            return ApplePressable(
              onTap: () => context.push('/iou-detail', extra: record),
              pressedScale: 0.98,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        record.personName?.isNotEmpty == true ? record.personName!.substring(0, 1).toUpperCase() : '?',
                        style: AppTypography.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.personName ?? 'Unknown', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            isSettled ? 'Settled • ${DateFormatter.formatDate(record.createdAt)}' : 'Remaining • Due ${record.dueDate != null ? DateFormatter.formatDate(record.dueDate!) : "N/A"}',
                            style: AppTypography.caption.copyWith(color: isSettled ? AppColors.income : AppColors.textDisabled),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(record.remainingAmountPaise),
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSettled ? AppColors.textDisabled : color,
                            decoration: isSettled ? TextDecoration.lineThrough : null,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (!isSettled && record.paidAmountPaise > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.incomeLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Repaid: ${CurrencyFormatter.format(record.paidAmountPaise)}',
                              style: AppTypography.caption.copyWith(color: AppColors.income, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

