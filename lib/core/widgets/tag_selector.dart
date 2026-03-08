import 'package:flutter/material.dart';

class TagSelector extends StatelessWidget {
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final String? label;
  final bool allowMultiple;
  final List<String>? selectedValues;

  const TagSelector({
    super.key,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.label,
    this.allowMultiple = false,
    this.selectedValues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = allowMultiple
                ? (selectedValues?.contains(option) ?? false)
                : selectedValue == option;

            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (allowMultiple) {
                  final newList = List<String>.from(selectedValues ?? []);
                  if (selected) {
                    newList.add(option);
                  } else {
                    newList.remove(option);
                  }
                  onChanged(null);
                } else {
                  onChanged(selected ? option : null);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }
}
