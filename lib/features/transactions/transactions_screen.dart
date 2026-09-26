import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/transaction_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../presentation/widgets/shared_widgets.dart';
import '../../presentation/widgets/transaction_widgets.dart';

/// Transactions Screen - Full history with search, type filters, and date grouping.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _searchQuery = '';
  TransactionType? _selectedTypeFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Transactions',
          style: AppTypography.titleLarge,
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search description, merchant...',
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('Expenses', TransactionType.expense),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('Income', TransactionType.income),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('Transfers', TransactionType.transfer),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Transactions List
          Expanded(
            child: transactionsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, __) => const ShimmerBox(width: double.infinity, height: 64),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading transactions: $err', style: AppTypography.bodySmall),
              ),
              data: (transactions) {
                // Apply filters
                final filtered = transactions.where((t) {
                  if (_selectedTypeFilter != null && t.type != _selectedTypeFilter) {
                    return false;
                  }
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final desc = t.description.toLowerCase();
                    final merch = (t.merchantName ?? '').toLowerCase();
                    return desc.contains(q) || merch.contains(q);
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _searchQuery.isEmpty ? 'No transactions yet' : 'No matching results',
                    subtitle: _searchQuery.isEmpty
                        ? 'Tap Quick Action + to add your first expense or income.'
                        : 'Try searching for something else.',
                  );
                }

                // Group transactions by formatted date string
                final Map<String, List<Transaction>> grouped = {};
                for (final tx in filtered) {
                  final dateKey = _formatDateKey(tx.date);
                  grouped.putIfAbsent(dateKey, () => []).add(tx);
                }

                // Calculate total income and expense for filtered list
                int totalIncomePaise = 0;
                int totalExpensePaise = 0;
                for (final tx in filtered) {
                  if (tx.type == TransactionType.income) totalIncomePaise += tx.amountPaise;
                  if (tx.type == TransactionType.expense) totalExpensePaise += tx.amountPaise;
                }

                return CustomScrollView(
                  slivers: [
                    // Summary Banner
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.borderSubtle),
                          boxShadow: AppColors.shadowSm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Inflow', style: AppTypography.caption),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(totalIncomePaise),
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.income,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(width: 1, height: 28, color: AppColors.borderSubtle),
                            Column(
                              children: [
                                const Text('Outflow', style: AppTypography.caption),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(totalExpensePaise),
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: AppColors.expense,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Date Grouped List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dateKey = grouped.keys.elementAt(index);
                          final items = grouped[dateKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TransactionDateHeader(dateLabel: dateKey),
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  border: Border.all(color: AppColors.borderSubtle),
                                  boxShadow: AppColors.shadowSm,
                                ),
                                child: ListView.separated(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.borderSubtle,
                                    indent: 56,
                                  ),
                                  itemBuilder: (context, i) {
                                    final tx = items[i];
                                    return TransactionRow(
                                      transaction: tx,
                                      onTap: () => context.push('/transaction-detail', extra: tx),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          );
                        },
                        childCount: grouped.keys.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TransactionType? type) {
    final isSelected = _selectedTypeFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.surface : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
