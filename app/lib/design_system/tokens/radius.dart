import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 8; // rounded-lg
  static const double md = 12; // rounded-xl
  static const double lg = 16; // rounded-2xl
  static const double xl = 24; // rounded-3xl
  static const double full = 999; // rounded-full

  // Pre-built BorderRadius
  static final smAll = BorderRadius.circular(sm);
  static final mdAll = BorderRadius.circular(md);
  static final lgAll = BorderRadius.circular(lg);
  static final xlAll = BorderRadius.circular(xl);
  static final fullAll = BorderRadius.circular(full);

  // Bottom sheet top radius
  static final sheetTop = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}
