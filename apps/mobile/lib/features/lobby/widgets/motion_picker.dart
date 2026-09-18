import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MotionPicker extends StatelessWidget {
  final List<String> sampleMotions;
  final String selectedMotion;
  final String selectedFormat;
  final String selectedStance;
  final ValueChanged<String> onMotionSelected;
  final ValueChanged<String> onFormatSelected;
  final ValueChanged<String> onStanceSelected;

  const MotionPicker({
    super.key,
    required this.sampleMotions,
    required this.selectedMotion,
    required this.selectedFormat,
    required this.selectedStance,
    required this.onMotionSelected,
    required this.onFormatSelected,
    required this.onStanceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Format & Stance Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Format Debat',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedFormat,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                        items: ['KDMI', 'WUDC', 'OXFORD', 'ASIAN_PARL']
                            .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) onFormatSelected(val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Posisi Anda',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onStanceSelected('PRO'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedStance == 'PRO'
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedStance == 'PRO'
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selectedStance == 'PRO'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onStanceSelected('CONTRA'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedStance == 'CONTRA'
                                  ? AppColors.accent
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedStance == 'CONTRA'
                                    ? AppColors.accent
                                    : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'KONTRA',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: selectedStance == 'CONTRA'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Motion Selection
        const Text(
          'Pilih Topik / Mosi Debat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ...sampleMotions.map((motion) {
          final isSelected = selectedMotion == motion;
          return GestureDetector(
            onTap: () => onMotionSelected(motion),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      motion,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
