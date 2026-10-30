import 'package:flutter/material.dart';

import '../../../models/service_model.dart';

class ServiceItem extends StatelessWidget {
  const ServiceItem({
    super.key,
    required this.service,
    this.onTap,
  });

  final ServiceModel service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final currency = service.price.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: service.imageUrl != null && service.imageUrl!.isNotEmpty
              ? NetworkImage(service.imageUrl!)
              : null,
          child: service.imageUrl == null || service.imageUrl!.isEmpty
              ? Icon(Icons.content_cut_outlined, color: primaryColor, size: 20)
              : null,
        ),
        title: Text(
          service.serviceName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('${service.durationMinutes} min', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ],
              ),
              if (service.request)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Request required',
                    style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹$currency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
