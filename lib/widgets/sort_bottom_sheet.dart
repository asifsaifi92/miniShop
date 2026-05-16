import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contracts/products_contract.dart';
import '../presenters/products_presenter.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProductsPresenter>(),
        child: const SortBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductsPresenter>();
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sort By',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...SortOption.values.map((option) {
              final selected = provider.sortOption == option;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? colorScheme.primary : null,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.check_circle, color: colorScheme.primary)
                    : const Icon(Icons.radio_button_unchecked,
                        color: Colors.grey),
                onTap: () {
                  provider.setSort(option);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
