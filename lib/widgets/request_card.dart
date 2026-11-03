import 'package:flutter/material.dart';

import '../models/request_model.dart';
import 'status_badge.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
  });

  final RequestModel request;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date = request.createdAt;
    final dateLabel = date == null
        ? 'Recently submitted'
        : '${date.month}/${date.day}/${date.year}';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${request.facilityId}  |  Floor ${request.floor ?? '?'}  |  '
                '${request.issueType}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(dateLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}