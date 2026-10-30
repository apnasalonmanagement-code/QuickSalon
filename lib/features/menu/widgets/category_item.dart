import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.categoryName,
    required this.serviceCount,
    required this.onRename,
    required this.child,
  });

  final String categoryName;
  final int serviceCount;
  final VoidCallback onRename;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.category_outlined, color: primaryColor),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '$serviceCount ${serviceCount == 1 ? 'service' : 'services'}',
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          tooltip: 'Manage category',
          onPressed: onRename,
          icon: Icon(Icons.more_vert, color: primaryColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}
