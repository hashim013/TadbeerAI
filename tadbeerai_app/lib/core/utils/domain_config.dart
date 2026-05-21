import 'package:flutter/material.dart';

class DomainConfig {
  static const domainConfig = {
    'Energy': {
      'icon': Icons.local_gas_station,
      'color': Color(0xFFE24B4A),
    },
    'Currency': {
      'icon': Icons.currency_exchange,
      'color': Color(0xFF534AB7),
    },
    'Stock Market': {
      'icon': Icons.candlestick_chart,
      'color': Color(0xFF1D9E75),
    },
    'Gold': {
      'icon': Icons.diamond_outlined,
      'color': Color(0xFFEF9F27),
    },
    'Logistics': {
      'icon': Icons.local_shipping,
      'color': Color(0xFF712B13),
    },
    'Finance': {
      'icon': Icons.account_balance,
      'color': Color(0xFF085041),
    },
    'Policy': {
      'icon': Icons.gavel,
      'color': Color(0xFF3C3489),
    },
    'Trade': {
      'icon': Icons.import_export,
      'color': Color(0xFF633806),
    },
    'Business Operations': {
      'icon': Icons.trending_down,
      'color': Color(0xFF534AB7),
    },
  };

  static IconData iconFor(String domain) =>
      domainConfig[domain]?['icon'] as IconData? ?? Icons.article_outlined;

  static Color colorFor(String domain) =>
      domainConfig[domain]?['color'] as Color? ?? const Color(0xFF534AB7);
}
