import 'package:flutter/material.dart';

class DogStatusChips extends StatelessWidget {
  final Map<String, dynamic> dog;

  const DogStatusChips({super.key, required this.dog});

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];

    chips.add(_buildDesexedChip());

    final spaySecure = _buildSpaySecureChip();
    if (spaySecure != null) chips.add(spaySecure);

    final season = _buildSeasonChip();
    if (season != null) chips.add(season);

    final contract = _buildContractChip();
    if (contract != null) chips.add(contract);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 6, runSpacing: -8, children: chips),
    );
  }

  Widget _buildDesexedChip() {
    final status = (dog['desexed'] ?? 'Unknown').toString();

    Color color;
    IconData icon;

    switch (status) {
      case 'Yes':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;

      case 'Pending':
        color = Colors.green;
        icon = Icons.schedule;
        break;

      case 'Breeding':
        color = Colors.orange;
        icon = Icons.favorite;
        break;

      case 'No':
        color = Colors.red;
        icon = Icons.warning;
        break;

      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(status),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildSpaySecureChip() {
    if (dog['spaysecure_due'] == null) return null;

    final dueDate = DateTime.tryParse(dog['spaysecure_due']);

    if (dueDate == null) return null;

    final days = dueDate.difference(DateTime.now()).inDays;

    if (days > 30) return null;

    final color = days <= 7 ? Colors.red : Colors.orange;

    return Chip(
      avatar: Icon(Icons.lock_clock, size: 16, color: color),
      label: Text('SpaySecure $days d'),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildSeasonChip() {
    if (dog['next_season'] == null) return null;

    final seasonDate = DateTime.tryParse(dog['next_season']);

    if (seasonDate == null) return null;

    final days = seasonDate.difference(DateTime.now()).inDays;

    if (days > 30) return null;

    final color = days <= 7 ? Colors.red : Colors.purple;

    return Chip(
      avatar: Icon(Icons.calendar_month, size: 16, color: color),
      label: Text('Season $days d'),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget? _buildContractChip() {
    if (dog['contract_end'] == null) return null;

    final contractDate = DateTime.tryParse(dog['contract_end']);

    if (contractDate == null) return null;

    final days = contractDate.difference(DateTime.now()).inDays;

    if (days > 90) return null;

    final color = days <= 30 ? Colors.red : Colors.orange;

    return Chip(
      avatar: Icon(Icons.description, size: 16, color: color),
      label: Text('Contract $days d'),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      visualDensity: VisualDensity.compact,
    );
  }
}
