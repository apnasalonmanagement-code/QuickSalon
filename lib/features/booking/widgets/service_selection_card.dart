import 'package:flutter/material.dart';

import '../../../models/service_model.dart';

class ServiceSelectionCard extends StatelessWidget {
  const ServiceSelectionCard({
    super.key,
    required this.service,
    required this.selected,
    required this.onChanged,
  });

  final ServiceModel service;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: selected ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        value: selected,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          service.serviceName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                avatar: const Icon(Icons.timer_outlined, size: 16),
                label: Text('${service.durationMinutes} min'),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: const Icon(Icons.currency_rupee, size: 16),
                label: Text(service.price.toStringAsFixed(2)),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                avatar: Icon(
                  service.request
                      ? Icons.pending_actions_outlined
                      : Icons.check_circle_outline,
                  size: 16,
                ),
                label: Text(service.request ? 'Request required' : 'Direct'),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}