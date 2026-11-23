import 'package:flutter/material.dart';

import '../models/user_medical_data.dart';

class MedicalSummaryCard extends StatelessWidget {
  final UserMedicalData medicalData;
  final VoidCallback? onEditPressed;

  const MedicalSummaryCard({
    super.key,
    required this.medicalData,
    this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (medicalData.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Completa tu perfil médico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Agrega tu información médica para un mejor seguimiento de tu salud.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            if (onEditPressed != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onEditPressed,
                icon: const Icon(Icons.edit),
                label: const Text('Completar ahora'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tu Información Médica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (onEditPressed != null)
              TextButton.icon(
                onPressed: onEditPressed,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (medicalData.bloodType.isNotEmpty) ...[
          _buildHighlightCard(
            '🩸 Tipo de Sangre',
            medicalData.bloodType,
            Colors.red,
          ),
          const SizedBox(height: 12),
        ],
        if (medicalData.allergies.isNotEmpty) ...[
          _buildHighlightCard(
            '⚠️ Alergias',
            medicalData.allergies,
            Colors.orange,
          ),
          const SizedBox(height: 12),
        ],
        if (medicalData.emergencyContactName.isNotEmpty ||
            medicalData.emergencyContactPhone.isNotEmpty) ...[
          _buildHighlightCard(
            '📞 Contacto de Emergencia',
            [
              if (medicalData.emergencyContactName.isNotEmpty)
                medicalData.emergencyContactName,
              if (medicalData.emergencyContactPhone.isNotEmpty)
                medicalData.emergencyContactPhone,
            ].join('\n'),
            Colors.red,
          ),
          const SizedBox(height: 12),
        ],
        if (medicalData.notes.isNotEmpty)
          _buildHighlightCard(
            '📋 Notas Médicas',
            medicalData.notes,
            Colors.blue,
          ),
      ],
    );
  }

  Widget _buildHighlightCard(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
