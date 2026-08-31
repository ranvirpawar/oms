import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/dashboard/dashboard_controller/dashboard_controller.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/dashboard_tile_card.dart';
import 'package:lifenity_connect/utils/widgets/app_drawer.dart';

import '../../../constants/app_strings.dart';
import '../../../utils/widgets/custom_appbar.dart';


class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});
  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF5F6FA),
      appBar: const CustomAppBar(
        title: AppStrings.dashboard,
        showBackButton: false,
        showDrawerButton: true,
      ),
      drawer: CustomDrawer(controller: controller),

      body: RefreshIndicator(
        onRefresh: () async {
          controller.refreshBagCount();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(), // important
          ),
          slivers: [
            // ── Welcome Card ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _WelcomeCard(
                  controller: controller,
                  isDark: isDark,
                  cs: cs,
                ),
              ),
            ),

            // ── Section Label ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 24, 18, 14),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 18,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : cs.onSurface,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Cards ──────────────────────────────────────────────────────
            Obx(() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                controller.onDashboardBuild();
              });

              if (controller.userRole.value == null) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverToBoxAdapter(
                    child: _ShimmerGrid(isDark: isDark, cs: cs),
                  ),
                );
              }

              final cards = controller.getRoleBasedStatCards();
              final isGrid = cards.length > 3;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: isGrid
                    ? _GridSliver(cards: cards, controller: controller)
                    : _ListSliver(cards: cards),
              );
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid sliver — uses Obx per-card for banner reactivity
// ─────────────────────────────────────────────────────────────────────────────

class _GridSliver extends StatelessWidget {
  final List<DashboardTileCard> cards;
  final DashboardController controller;

  const _GridSliver({required this.cards, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final card = cards[index];
          final isBagCard = card.title == AppStrings.collectedSampleBags ||
              card.title == 'Collected Sample Bags';

          if (isBagCard) {
            return Obx(() {
              final count = controller.collectedBagsCount.value;
              final banner = count > 0
                  ? '🧪  $count ${count == 1 ? 'bag' : 'bags'} with you  •  Submit to lab or hand over          '
                  : null;

              return DashboardTileCard(
                title: card.title,
                icon: card.icon,
                onTap: card.onTap,
                isGridMode: true,
                bannerText: banner,
              );
            });
          }

          return DashboardTileCard(
            title: card.title,
            icon: card.icon,
            onTap: card.onTap,
            isGridMode: true,
          );
        },
        childCount: cards.length,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// List sliver
// ─────────────────────────────────────────────────────────────────────────────

class _ListSliver extends StatelessWidget {
  final List<DashboardTileCard> cards;

  const _ListSliver({required this.cards});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 13),
          child: DashboardTileCard(
            title: cards[index].title,
            icon: cards[index].icon,
            onTap: cards[index].onTap,
            isGridMode: false,
          ),
        ),
        childCount: cards.length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Card — name only, no designation
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  final DashboardController controller;
  final bool isDark;
  final ColorScheme cs;

  const _WelcomeCard({
    required this.controller,
    required this.isDark,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    // ── Neumorphic palette (same as tile cards for consistency) ──────────────
    final neuBase  = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFECEFF4);
    final neuLight = isDark ? const Color(0xFF2C2C40) : Colors.white;
    final neuDark  = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFC8CBD6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: neuBase,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Top-left highlight
          BoxShadow(
            color: neuLight.withOpacity(isDark ? 0.12 : 1.0),
            offset: const Offset(-6, -6),
            blurRadius: 12,
          ),
          // Bottom-right shadow
          BoxShadow(
            color: neuDark.withOpacity(isDark ? 0.75 : 0.55),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Neumorphic avatar ──────────────────────────────────────────────
          Container(
            width: 32,
            height:32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cs.primary.withOpacity(0.85),
                  cs.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.35),
                  offset: const Offset(3, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Obx(() {
                final name = controller.userName.value;
                final initials = name.trim().isNotEmpty
                    ? name.trim().split(' ')
                    .where((p) => p.isNotEmpty)
                    .take(2)
                    .map((p) => p[0].toUpperCase())
                    .join()
                    : '?';
                return Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                );
              }),
            ),
          ),

          const SizedBox(width: 14),

          // ── Text ──────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final name = controller.userName.value;
              final first = name.isNotEmpty ? name.trim().split(' ').first : '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    first.isNotEmpty ? 'Hello, $first!' : AppStrings.welcomeToLifenity,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF2D3142),
                      height: 1.2,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.welcomeToLifenity,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.38)
                          : const Color(0xFF2D3142).withOpacity(0.45),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),

          const SizedBox(width: 12),


        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neumorphic pulsing online dot — inset ring + raised center dot
// ─────────────────────────────────────────────────────────────────────────────




// ─────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerGrid extends StatefulWidget {
  final bool isDark;
  final ColorScheme cs;

  const _ShimmerGrid({required this.isDark, required this.cs});

  @override
  State<_ShimmerGrid> createState() => _ShimmerGridState();
}

class _ShimmerGridState extends State<_ShimmerGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -1.5, end: 1.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? Colors.white.withOpacity(0.05)
        : widget.cs.surfaceContainerHighest.withOpacity(0.4);
    final shine = widget.isDark
        ? Colors.white.withOpacity(0.1)
        : widget.cs.surfaceContainerHighest.withOpacity(0.75);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.0,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [base, shine, base],
            ),
          ),
        ),
      ),
    );
  }
}
/*class DashboardScreen extends StatelessWidget {
    DashboardScreen({super.key});
  DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;


    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.dashboard,
        showBackButton: false,
        showDrawerButton: true,
      ),
      drawer: CustomDrawer(controller: controller,),
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(

                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  AppStrings.welcomeToLifenity,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions Title
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 16),

              // listView for stat cards
              Obx(() {
                if (controller.userRole.value == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final statCards = controller.getRoleBasedStatCards();
                final isGridMode = statCards.length > 3;

                if (isGridMode) {
                  return _buildGridView(statCards);
                } else {
                  return _buildListView(statCards);
                }

              }),
              // Bottom spacing
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
   Widget _buildListView(List<DashboardTileCard> statCards) {
     return ListView.separated(
       shrinkWrap: true,
       physics: const NeverScrollableScrollPhysics(),
       itemCount: statCards.length,
       separatorBuilder: (_, __) => const SizedBox(height: 16),
       itemBuilder: (context, index) => DashboardTileCard(
         title: statCards[index].title,
         icon: statCards[index].icon,
         onTap: statCards[index].onTap,
         isGridMode: false,
       ),
     );
   }

    Widget _buildGridView(List<DashboardTileCard> statCards) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: statCards.length,
        itemBuilder: (context, index) {
          final card = statCards[index];

          // ✅ Intercept only the Collected Bags card
          if (card.title == AppStrings.collectedSampleBags) {
            return CollectedBagsTileWithBanner(
              onTap: card.onTap,
              isGridMode: true,
            );
          }

          return DashboardTileCard(
            title: card.title,
            icon: card.icon,
            onTap: card.onTap,
            isGridMode: true,
          );
        },
      );
    }



}*/
