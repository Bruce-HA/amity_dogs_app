import 'package:flutter/material.dart';

class DogStatusChips extends StatelessWidget {
  final Map<String, dynamic> dog;

  const DogStatusChips({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];

    chips.add(_buildDesexedChip());

    final season = _buildSeasonChip();
    if (season != null) chips.add(season);

    final contract = _buildContractChip();
    if (contract != null) chips.add(contract);

    return Wrap(spacing: 6, runSpacing: -8, children: chips);
  }

  Widget _buildDesexedChip() {
    final status = dog['desexed']?.toString() ?? 'Unknown';

    Color color;

    switch (status) {
      case 'Yes':
        color = Colors.blue;
        break;

      case 'Pending':
        color = Colors.green;
        break;

      case 'Breeding':
        color = Colors.orange;
        break;

      case 'No':
        color = Colors.red;
        break;

      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildSeasonChip() {
    final dateStr = dog['next_season'];
    if (dateStr == null) return null;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    final days = date.difference(DateTime.now()).inDays;

    if (days > 30) return null;

    return Chip(
      label: Text('Season $days d'),
      backgroundColor: Colors.purple.withOpacity(0.15),
      labelStyle: const TextStyle(
        color: Colors.purple,
        fontWeight: FontWeight.bold,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildContractChip() {
    final dateStr = dog['contract_end'];
    if (dateStr == null) return null;

    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;

    final days = date.difference(DateTime.now()).inDays;

    if (days > 90) return null;

    return Chip(
      label: Text('Contract $days d'),
      backgroundColor: Colors.orange.withOpacity(0.15),
      labelStyle: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
