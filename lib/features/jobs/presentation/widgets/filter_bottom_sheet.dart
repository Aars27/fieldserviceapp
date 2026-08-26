import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _statuses = Set.from(widget.current.statuses);
    _priorities = Set.from(widget.current.priorities);
    _from = widget.current.from;
    _to = widget.current.to;
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Jobs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Status', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: JobStatus.values.map((s) {
                final selected = _statuses.contains(s);
                return FilterChip(
                  label: Text(s.label),
                  selected: selected,
                  onSelected: (v) => setState(
                    () => v ? _statuses.add(s) : _statuses.remove(s),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Priority', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: JobPriority.values.map((p) {
                final selected = _priorities.contains(p);
                return FilterChip(
                  label: Text(p.label),
                  selected: selected,
                  onSelected: (v) => setState(
                    () => v ? _priorities.add(p) : _priorities.remove(p),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Date Range', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _DateButton(label: 'From', value: _from, onPick: (d) => setState(() => _from = d))),
                const SizedBox(width: 12),
                Expanded(child: _DateButton(label: 'To', value: _to, onPick: (d) => setState(() => _to = d))),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
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
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(value != null ? DateFormat('MMM d').format(value!) : label),
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
