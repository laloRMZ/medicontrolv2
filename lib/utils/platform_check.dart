import 'package:flutter/material.dart';

bool isWearable(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  final shortestSide = mediaQuery.size.shortestSide;
  return shortestSide < 600;
}
