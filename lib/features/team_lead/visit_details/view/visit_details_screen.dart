import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/add_visit_screen.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/date_selector_widget.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/visit_card_widget.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/visit_details_bottomsheet.dart';
import 'package:lifenity_connect/utils/animated_shimmer/visit_card_shimmer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../constants/app_strings.dart';
import '../model/visit_model.dart';
import '../provider/visit_providers.dart';

class VisitDetailsScreen extends ConsumerWidget {
  const VisitDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitDataAsync = ref.watch(visitDataProvider);
    final selectedVisit = ref.watch(selectedVisitProvider);

    return Scaffold(
      appBar: CustomAppBar(
       title: AppStrings.visitDetails,
        actions: [
          // text add visit

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProviderScope(child: AddVisitScreen())),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),

              ),
              child: const Text('Add Visit', style: TextStyle(color: Colors.white),),
            ),
          )

        ]
      ),
      body: Column(
        children: [
          const DateSelectorWidget(),
          ////////////////
          Expanded(
            child: visitDataAsync.when(

              data: (visitResponse) {
                if (visitResponse.output.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No visits found for selected date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(visitDataProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: visitResponse.output.length,
                    itemBuilder: (context, index) {
                      // Access items from the end
                      final visit = visitResponse.output[visitResponse.output.length - 1 - index];

                      return VisitCardWidget(
                        visit: visit,
                        onTap: () {
                          ref.read(selectedVisitProvider.notifier).state = visit;
                          _showVisitDetailsDialog(context, visit);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: VisitCardShimmerWidget(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading visits',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                       'Something went wrong. Please try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(visitDataProvider);
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showVisitDetailsDialog(BuildContext context, VisitData visit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => VisitDetailsBottomSheet(visit: visit),
    );
  }
}