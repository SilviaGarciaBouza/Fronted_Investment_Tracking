import 'package:flutter/material.dart';

class Headerwidget extends StatelessWidget {
  const Headerwidget({super.key});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12.0,
      color: Colors.black87,
    );

    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),

      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),

      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "Category",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: Text(
              "Current %",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: Text(
              "Name",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.start,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 1,
            child: Text(
              "Id",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: Text(
              "Share Price",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 1,
            child: Text(
              "Stocks",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: Text(
              "Value (€)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: Text(
              "NPL (€)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),

          Expanded(
            flex: 2,
            child: Text(
              "NPL %",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
