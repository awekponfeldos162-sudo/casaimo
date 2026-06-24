import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onFilter;

  const SearchBarWidget({
    super.key,
    this.hint = 'Rechercher un bien...',
    this.onTap,
    this.onChanged,
    this.controller,
    this.readOnly = false,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: readOnly
                  ? Text(hint, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textHint))
                  : TextField(
                      controller: controller,
                      onChanged: onChanged,
                      decoration: InputDecoration(
                        hintText: hint,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
            ),
            if (onFilter != null) ...[
              Container(width: 1, height: 24, color: AppColors.border),
              IconButton(
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              ),
            ] else
              const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}
