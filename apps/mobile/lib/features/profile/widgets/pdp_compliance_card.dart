import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PDPComplianceCard extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onDeleteAccount;

  const PDPComplianceCard({
    super.key,
    required this.onExportData,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.privacy_tip_outlined,
                  size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Privasi & Kepatuhan UU PDP (No. 27/2022)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Sesuai UU Perlindungan Data Pribadi RI, Anda berhak mengunduh seluruh data riwayat debat, log audio, dan profil Anda atau menghapusnya secara permanen.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportData,
                  icon: const Icon(Icons.download, size: 14),
                  label: const Text('Export Data (JSON/ZIP)',
                      style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onDeleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Hapus Akun',
                    style: TextStyle(fontSize: 11, color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
