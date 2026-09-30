import 'package:flutter/material.dart';

import '../app_design.dart';
import 'network_status.dart';

class NetworkBanner extends StatelessWidget {
  final NetworkStatus status;
  const NetworkBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status != NetworkStatus.offline) return const SizedBox.shrink();
    return Material(
      color: AppDesign.softSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Offline. Bereits geladene Inhalte bleiben verfügbar. Änderungen werden erst wieder gespeichert, wenn die Verbindung zurück ist.', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
