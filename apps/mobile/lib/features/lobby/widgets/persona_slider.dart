import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PersonaSlider extends StatelessWidget {
  final List<Map<String, String>> personas;
  final String selectedPersona;
  final ValueChanged<String> onPersonaSelected;

  const PersonaSlider({
    super.key,
    required this.personas,
    required this.selectedPersona,
    required this.onPersonaSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Lawan Debat (Persona AI)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: personas.length,
            itemBuilder: (context, index) {
              final p = personas[index];
              final isSelected = selectedPersona == p['name'];
              return GestureDetector(
                onTap: () => onPersonaSelected(p['name']!),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            child: const Icon(Icons.smart_toy,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              p['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        p['desc']!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
