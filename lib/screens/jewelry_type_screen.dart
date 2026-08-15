import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/jewelry_type.dart';
import '../services/try_on_state_manager.dart';
import '../widgets/jewelry_type_card.dart';
import '../widgets/luxury_app_bar.dart';
import '../widgets/primary_button.dart';
import 'generating_screen.dart';

class JewelryTypeScreen extends StatelessWidget {
  const JewelryTypeScreen({super.key});

  void _startGeneration(BuildContext context, TryOnStateManager stateManager) {
    // Initiate background generation task in state manager
    stateManager.runTryOnGeneration();

    // Navigate to Generating Screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GeneratingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = Provider.of<TryOnStateManager>(context);
    final selectedType = stateManager.selectedJewelryType;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const LuxuryAppBar(title: 'Select Jewelry Type'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What Are You Trying On?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select category to tune AI anatomical placement.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),

              // Jewelry Selection Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: JewelryType.values.length,
                  itemBuilder: (context, index) {
                    final type = JewelryType.values[index];
                    final isSelected = selectedType == type;

                    return JewelryTypeCard(
                      jewelryType: type,
                      isSelected: isSelected,
                      onTap: () => stateManager.setSelectedJewelryType(type),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Target Anchor Info Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.goldLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.center_focus_strong, color: AppColors.burgundy, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedType.displayName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.burgundy,
                            ),
                          ),
                          Text(
                            selectedType.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Primary Action Button
              PrimaryButton(
                text: 'Generate ✨',
                icon: Icons.auto_awesome,
                onPressed: () => _startGeneration(context, stateManager),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
