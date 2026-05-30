import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/services/api_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';

class TaxDeskScreen extends StatefulWidget {
  const TaxDeskScreen({super.key});

  @override
  State<TaxDeskScreen> createState() => _TaxDeskScreenState();
}

class _TaxDeskScreenState extends State<TaxDeskScreen> {
  // Current values loaded from backend
  double _fbrRate = 18.0;
  double _sbrRate = 13.0;
  bool _loadingState = true;
  bool _updatingState = false;

  // Calculator inputs
  final _amountController = TextEditingController(text: '10000');
  String _selectedAuthority = 'FBR'; // 'FBR' or 'SBR'
  String _sbrCategory = 'Standard (13%)'; // For SBR options
  double _customRate = 13.0; // Custom rate if SBR custom is selected

  // Rates configuration controller
  final _fbrConfigController = TextEditingController();
  final _sbrConfigController = TextEditingController();

  final List<String> _sbrCategories = [
    'Standard (13%)',
    'Telecom (15%)',
    'Specialized (8%)',
    'Reduced (5%)',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
    _amountController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _fbrConfigController.dispose();
    _sbrConfigController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    setState(() => _loadingState = true);
    try {
      final state = await ApiService.getState();
      if (mounted) {
        setState(() {
          _fbrRate = (state['fbr_tax_rate'] as num?)?.toDouble() ?? 18.0;
          _sbrRate = (state['sbr_tax_rate'] as num?)?.toDouble() ?? 13.0;
          _fbrConfigController.text = _fbrRate.toString();
          _sbrConfigController.text = _sbrRate.toString();
          _loadingState = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fbrConfigController.text = _fbrRate.toString();
          _sbrConfigController.text = _sbrRate.toString();
          _loadingState = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch tax rates: $e'),
            backgroundColor: TColors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateState() async {
    final fbrInput = double.tryParse(_fbrConfigController.text);
    final sbrInput = double.tryParse(_sbrConfigController.text);

    if (fbrInput == null || sbrInput == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numerical rates.'),
          backgroundColor: TColors.red,
        ),
      );
      return;
    }

    setState(() => _updatingState = true);
    try {
      final updates = {
        'fbr_tax_rate': fbrInput,
        'sbr_tax_rate': sbrInput,
      };
      await ApiService.updateState(updates);
      if (mounted) {
        setState(() {
          _fbrRate = fbrInput;
          _sbrRate = sbrInput;
          _updatingState = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tax rates successfully updated on backend!'),
            backgroundColor: TColors.teal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _updatingState = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update rates: $e'),
            backgroundColor: TColors.red,
          ),
        );
      }
    }
  }

  void _recalculate() {
    setState(() {});
  }

  double get _currentRate {
    if (_selectedAuthority == 'FBR') {
      return _fbrRate;
    } else {
      switch (_sbrCategory) {
        case 'Standard (13%)':
          return _sbrRate;
        case 'Telecom (15%)':
          return 15.0;
        case 'Specialized (8%)':
          return 8.0;
        case 'Reduced (5%)':
          return 5.0;
        case 'Custom':
          return _customRate;
        default:
          return _sbrRate;
      }
    }
  }

  Map<String, double> get _calculations {
    final base = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final rate = _currentRate;
    final tax = base * (rate / 100.0);
    final total = base + tax;
    return {
      'base': base,
      'rate': rate,
      'tax': tax,
      'total': total,
    };
  }

  final _currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final cal = _calculations;

    return Scaffold(
      backgroundColor: context.tBg,
      body: _loadingState
          ? const Center(
              child: CircularProgressIndicator(color: TColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadState,
              color: TColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Header Banner
                    _buildBanner().animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),
                    const SizedBox(height: 16),

                    // Interactive Calculator Section
                    _buildCalculatorSection(cal),
                    const SizedBox(height: 16),

                    // Calculations Result Card
                    _buildResultCard(cal).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),

                    // Settings & Configuration Section
                    _buildSettingsSection().animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TColors.primaryDark, TColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TadbeerAI Tax Desk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Pakistan Fiscal & Provincial Taxes',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBannerRateCard('FBR TAX (Goods)', '${_fbrRate.toStringAsFixed(1)}%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBannerRateCard('SBR TAX (Services)', '${_sbrRate.toStringAsFixed(1)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerRateCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorSection(Map<String, double> cal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.tCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionLabel(label: 'Tax Calculator'),
          const SizedBox(height: 12),

          // Base Amount Input
          Text(
            'Base Amount (PKR)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.tTextSecondary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              hintText: 'Enter transaction amount',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () => _amountController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Authority Segment Toggle
          Text(
            'Taxing Authority / Jurisdiction',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.tTextSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAuthorityButton('FBR', 'Federal (Goods)'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAuthorityButton('SBR', 'Sindh (Services)'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SBR Categories Dropdown (if SBR selected)
          if (_selectedAuthority == 'SBR') ...[
            Text(
              'SST Service Category',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.tTextSecondary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.tSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.tBorder, width: 0.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sbrCategory,
                  isExpanded: true,
                  dropdownColor: context.tSurface,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: _sbrCategories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(fontSize: 13, color: context.tTextPrimary, fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sbrCategory = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            if (_sbrCategory == 'Custom') ...[
              const SizedBox(height: 12),
              Text(
                'Enter Custom Rate (%)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.tTextSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                decoration: const InputDecoration(
                  suffixText: '%',
                  hintText: 'Enter rate, e.g. 13',
                ),
                onChanged: (val) {
                  setState(() {
                    _customRate = double.tryParse(val) ?? 13.0;
                  });
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorityButton(String authority, String subtitle) {
    final isSelected = _selectedAuthority == authority;
    final color = isSelected ? TColors.primary : context.tSurfaceAlt;
    final textColor = isSelected ? Colors.white : context.tTextPrimary;
    final subColor = isSelected ? Colors.white70 : context.tTextTertiary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAuthority = authority;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? TColors.primary : context.tBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              authority,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: subColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, double> cal) {
    return Container(
      width: double.infinity,
      decoration: context.tCard,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TColors.tealLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: context.tBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calculate_rounded, color: TColors.tealDark, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tax Imposed: ${cal['rate']?.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: TColors.tealDark,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildResultRow('Transaction Amount', _currencyFormat.format(cal['base'])),
                const Divider(height: 24, thickness: 0.5),
                _buildResultRow('Tax Rate Applied', '${cal['rate']?.toStringAsFixed(2)}%'),
                const Divider(height: 24, thickness: 0.5),
                _buildResultRow('Tax Imposed (GST/SST)', _currencyFormat.format(cal['tax']), highlightValueColor: TColors.amberDark),
                const Divider(height: 24, thickness: 0.5),
                _buildResultRow('Total Payable Amount', _currencyFormat.format(cal['total']), isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false, Color? highlightValueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? context.tTextPrimary : context.tTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: FontWeight.bold,
            color: highlightValueColor ?? (isTotal ? TColors.primary : context.tTextPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: context.tCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionLabel(label: 'Simulate Rate Change'),
          const SizedBox(height: 6),
          Text(
            'Adjust standard FBR/SBR rates in database to simulate national policy updates.',
            style: context.tCaption,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TTextField(
                  controller: _fbrConfigController,
                  label: 'FBR rate (%)',
                  icon: Icons.percent_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TTextField(
                  controller: _sbrConfigController,
                  label: 'SBR rate (%)',
                  icon: Icons.percent_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TPrimaryButton(
            label: 'Save & update rates',
            icon: Icons.sync_rounded,
            isLoading: _updatingState,
            onTap: _updateState,
          ),
        ],
      ),
    );
  }
}
