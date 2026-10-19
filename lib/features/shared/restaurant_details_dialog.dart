import 'package:flutter/material.dart';

import '../../core/app_feedback.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_design.dart';

Future<bool?> showRestaurantDetailsDialog(
  BuildContext context,
  Map<String, dynamic> restaurant, {
  String? extraActionLabel,
  Future<bool> Function()? onCompleteVisit,
  bool isFavorite = false,
  Future<bool> Function(bool currentlyFavorite)? onToggleFavorite,
}) {
  final name = restaurant['name']?.toString().trim() ?? 'Restaurant';
  final cuisine = restaurant['cuisine']?.toString();
  final address = restaurant['address']?.toString();
  final phone = restaurant['phone']?.toString();
  final website = restaurant['website']?.toString();
  final hours = restaurant['opening_hours']?.toString();
  var isCompletingVisit = false;

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: SizedBox(
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 42),
                child: Text(name, textAlign: TextAlign.center),
              ),
              if (onToggleFavorite != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: isFavorite ? 'Aus Lieblingsrestaurants entfernen' : 'Als Lieblingsrestaurant speichern',
                    onPressed: () async {
                      final updated = await onToggleFavorite(isFavorite);
                      if (dialogContext.mounted) {
                        setDialogState(() => isFavorite = updated);
                      }
                    },
                    icon: Icon(
                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_has(cuisine)) _detailRow(Icons.restaurant_menu_rounded, 'Küche', cuisine!),
              if (_has(address))
                _detailRow(Icons.location_on_outlined, 'Adresse', _formatAddress(address!), onTap: () {
                  final uri = Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': address});
                  _launch(context, uri);
                }),
              if (_has(phone))
                _detailRow(Icons.phone_outlined, 'Telefon', phone!, onTap: () {
                  _launch(context, Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+*#,;]'), '')));
                }),
              if (_has(website))
                _detailRow(Icons.language_rounded, 'Webseite', website!, onTap: () {
                  final uri = Uri.tryParse(website);
                  if (uri != null && uri.hasAuthority && {'http', 'https'}.contains(uri.scheme)) {
                    _launch(context, uri);
                  }
                }),
              if (_has(hours)) _detailRow(Icons.schedule_rounded, 'Öffnungszeiten', hours!),
              if (![cuisine, address, phone, website, hours].any(_has))
                const Text('Für dieses Restaurant sind keine weiteren Angaben gespeichert.'),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          if (onCompleteVisit != null)
            TextButton.icon(
              onPressed: isCompletingVisit
                  ? null
                  : () async {
                      setDialogState(() => isCompletingVisit = true);
                      try {
                        final completed = await onCompleteVisit();
                        if (completed && dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isCompletingVisit = false);
                        }
                      }
                    },
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('Erledigt'),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Schließen')),
          if (extraActionLabel != null)
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(extraActionLabel)),
        ],
      ),
    ),
  );
}

bool _has(String? value) => value != null && value.trim().isNotEmpty;

String _formatAddress(String address) {
  final parts = address.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
  if (parts.length >= 2) return '${parts.first}\n${parts.skip(1).join(', ')}';
  return address;
}

Future<void> _launch(BuildContext context, Uri uri) async {
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppFeedback.showSnackBar(context, const SnackBar(content: Text('Die Verknüpfung konnte nicht geöffnet werden.')));
    }
  } catch (_) {
    if (context.mounted) {
      AppFeedback.showSnackBar(context, const SnackBar(content: Text('Die Verknüpfung konnte nicht geöffnet werden.')));
    }
  }
}

Widget _detailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppDesign.primaryDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(
                    color: onTap == null ? AppDesign.text : AppDesign.primaryDark,
                    decoration: onTap == null ? TextDecoration.none : TextDecoration.underline,
                  )),
                ],
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 2),
                child: Icon(Icons.open_in_new_rounded, size: 16, color: AppDesign.primaryDark),
              ),
          ],
        ),
      ),
    ),
  );
}
