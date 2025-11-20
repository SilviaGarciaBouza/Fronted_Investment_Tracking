import 'package:flutter/material.dart';

class ItemFieldWidget extends StatelessWidget {
  const ItemFieldWidget({
    super.key,
    required this.numFlex,
    required this.childText,
    this.textAlign = TextAlign.start,
    this.isProfitLoss = false,
  });

  final int numFlex;
  final String childText;
  final TextAlign textAlign;
  final bool isProfitLoss;

  @override
  Widget build(BuildContext context) {
    Color textColor = Colors.black;

    return Expanded(
      flex: numFlex,
      child: Text(
        childText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
          color: textColor,
        ),
      ),
    );
  }
}
