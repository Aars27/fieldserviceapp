import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/job_visuals.dart';
import '../../domain/entities/job_priority.dart';
import '../../domain/entities/job_status.dart';
import '../../domain/repositories/job_repository.dart';

class FilterBottomSheet extends StatefulWidget {
  final JobsFilter current;

  const FilterBottomSheet({super.key, required this.current});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<JobStatus> _statuses;
  late Set<JobPriority> _priorities;
  DateTime? _from;
  DateTime? _to;
  late bool _overdueOnly;

  @override
  void initState() {
    super.initState();
    _statuses = Set.from(widget.current.statuses);
    _priorities = Set.from(widget.current.priorities);
    _from = widget.current.from;
    _to = widget.current.to;
    _overdueOnly = widget.current.overdueOnly;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Jobs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (_statuses.isNotEmpty || _priorities.isNotEmpty || _from != null || _to != null)
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'STATUS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: JobStatus.values.map((s) {
                final selected = _statuses.contains(s);
                final color = JobVisuals.statusColor(context, s);
                return FilterChip(
                  avatar: Icon(
                    JobVisuals.statusIcon(s),
                    size: 16,
                    color: selected ? color : cs.outline,
                  ),
                  label: Text(s.label),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.15),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    color: selected ? color : cs.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  onSelected: (v) => setState(
                    () => v ? _statuses.add(s) : _statuses.remove(s),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'PRIORITY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: JobPriority.values.map((p) {
                final selected = _priorities.contains(p);
                final color = JobVisuals.priorityColor(context, p);
                return FilterChip(
                  avatar: Icon(
                    JobVisuals.priorityIcon(p),
                    size: 16,
                    color: selected ? color : cs.outline,
                  ),
                  label: Text(p.label),
                  selected: selected,
                  selectedColor: color.withValues(alpha: 0.15),
                  checkmarkColor: color,
                  labelStyle: TextStyle(
                    color: selected ? color : cs.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  onSelected: (v) => setState(
                    () => v ? _priorities.add(p) : _priorities.remove(p),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'DATE RANGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: 'From',
                    value: _from,
                    onPick: (d) => setState(() => _from = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateButton(
                    label: 'To',
                    value: _to,
                    onPick: (d) => setState(() => _to = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _statuses = {};
      _priorities = {};
      _from = null;
      _to = null;
      _overdueOnly = false;
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      JobsFilter(
        search: widget.current.search,
        statuses: _statuses,
        priorities: _priorities,
        from: _from,
        to: _to,
        overdueOnly: _overdueOnly,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? value;
  final void Function(DateTime?) onPick;

  const _DateButton({required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today_rounded, size: 16),
      label: Text(
        value != null ? DateFormat('MMM d, y').format(value!) : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        onPick(picked);
      },
    );
  }
}
