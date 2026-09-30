import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants.dart';
import '../../core/error_text.dart';
import '../../data/repositories/food_repository.dart';

class AddFoodDialog extends StatefulWidget {
  final String? initialCategory;
  const AddFoodDialog({super.key, this.initialCategory});

  @override
  State<AddFoodDialog> createState() => _AddFoodDialogState();
}

class _AddFoodDialogState extends State<AddFoodDialog> {
  final name = TextEditingController();
  final unit = TextEditingController(text: 'Stück');
  late String category;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    category = foodCategories.contains(widget.initialCategory)
        ? widget.initialCategory!
        : 'Sonstiges';
  }

  @override
  void dispose() {
    name.dispose();
    unit.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = name.text.trim();
    if (value.isEmpty) return;
    setState(() => saving = true);
    try {
      final food = await FoodRepository().addFoodModel(
        name: value,
        category: category,
        defaultUnit: unit.text,
      );
      if (mounted) Navigator.pop(context, food);
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.code == '23505'
              ? 'Dieses Lebensmittel gibt es bereits.'
              : 'Speichern fehlgeschlagen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Eigenes Lebensmittel hinzufügen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Lebensmittel',
                  hintText: 'z. B. Halloumi',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Kategorie'),
                items: foodCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: saving ? null : (v) => setState(() => category = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unit,
                decoration: const InputDecoration(
                  labelText: 'Standardeinheit',
                  hintText: 'g, ml, Stück',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Speichern …' : 'Hinzufügen'),
          ),
        ],
      );
}
