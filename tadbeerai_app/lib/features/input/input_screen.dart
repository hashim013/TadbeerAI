// lib/features/input/input_screen.dart
// Screen 2: Manual Input — Text / PDF / URL + Urdu support

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../insight/insight_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  String _language = 'en';
  String? _pdfFileName;
  final bool _analysing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTextTab(),
                  _buildPdfTab(),
                  _buildUrlTab(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── TAB BAR ────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      height: 44,
      decoration: BoxDecoration(
        color: context.tSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.tBorder, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: context.tSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.tBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ],
        ),
        labelColor: context.tTextPrimary,
        unselectedLabelColor: context.tTextSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        tabs: const [
          Tab(icon: Icon(Icons.text_fields_rounded, size: 16), text: 'Text'),
          Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 16), text: 'PDF'),
          Tab(icon: Icon(Icons.link_rounded, size: 16), text: 'URL'),
        ],
      ),
    );
  }

  // ── TEXT TAB ───────────────────────────────
  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language selector
          _buildLanguageSelector(),
          SizedBox(height: 12),
          const TSectionLabel(label: 'Paste news or report'),
          SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: context.tSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.tBorder, width: 0.5),
            ),
            child: TextField(
              controller: _textController,
              maxLines: 8,
              style: TextStyle(
                  fontSize: 13, color: context.tTextPrimary, height: 1.6),
              decoration: const InputDecoration(
                hintText:
                    'Paste news article, report, or policy update here...\n\nAlso supports: اردو میں خبر یہاں لکھیں یا Roman Urdu mein likh saktay hain',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                filled: false,
              ),
            ),
          ),
          SizedBox(height: 14),
          // Sample scenarios
          const TSectionLabel(label: 'Try a sample'),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SampleChip(
                  label: '⛽ Petrol hike', onTap: () => _fillSample('petrol')),
              _SampleChip(
                  label: '💸 Rupee drop', onTap: () => _fillSample('rupee')),
              _SampleChip(
                  label: '📉 Sales decline', onTap: () => _fillSample('sales')),
              _SampleChip(
                  label: '🚢 Port delay', onTap: () => _fillSample('port')),
            ],
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  // ── PDF TAB ────────────────────────────────
  Widget _buildPdfTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const TSectionLabel(label: 'Upload report PDF'),
          SizedBox(height: 10),
          GestureDetector(
            onTap: _pickPdf,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: _pdfFileName != null
                    ? TColors.primaryLight
                    : context.tSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _pdfFileName != null ? TColors.primary : context.tBorder,
                  width: _pdfFileName != null ? 1.5 : 0.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _pdfFileName != null
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_rounded,
                    size: 40,
                    color: _pdfFileName != null
                        ? TColors.teal
                        : context.tTextTertiary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    _pdfFileName ?? 'Tap to upload PDF',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _pdfFileName != null
                            ? TColors.tealDark
                            : context.tTextSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _pdfFileName != null
                        ? 'Tap to change file'
                        : 'Max 10 MB · Sales, policy, logistics reports',
                    style: context.tCaption,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(),
          SizedBox(height: 16),
          const _InfoBox(
            icon: Icons.info_outline_rounded,
            text:
                'Supported: Sales reports, policy documents, logistics summaries, financial statements',
          ),
        ],
      ),
    );
  }

  // ── URL TAB ────────────────────────────────
  Widget _buildUrlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionLabel(label: 'Paste a specific article URL'),
          SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            style: TextStyle(fontSize: 13, color: context.tTextPrimary),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.link_rounded,
                  size: 18, color: context.tTextTertiary),
              hintText: 'https://dawn.com/news/1234567/article-title',
              suffixIcon: IconButton(
                icon: Icon(Icons.content_paste_rounded,
                    size: 18, color: TColors.primary),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste from clipboard',
              ),
            ),
          ),
          SizedBox(height: 14),
          const TSectionLabel(label: 'Browse news sources'),
          SizedBox(height: 4),
          Text(
            'Open a source, find an article, then copy & paste its URL above',
            style: TextStyle(
                fontSize: 11, color: context.tTextTertiary, height: 1.4),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SourcePill(
                  label: '🌐 Dawn.com',
                  onTap: () => _openSource('https://dawn.com')),
              _SourcePill(
                  label: '🌐 The News',
                  onTap: () => _openSource('https://thenews.com.pk')),
              _SourcePill(
                  label: '🌐 ARY News',
                  onTap: () => _openSource('https://arynews.tv')),
              _SourcePill(
                  label: '🌐 Geo News',
                  onTap: () => _openSource('https://geo.tv')),
              _SourcePill(
                  label: '🌐 Business Recorder',
                  onTap: () => _openSource('https://brecorder.com')),
            ],
          ),
          SizedBox(height: 16),
          const _InfoBox(
            icon: Icons.info_outline_rounded,
            text:
                'Paste the full URL of a specific news article — not a homepage. '
                'TadbeerAI will scrape and analyse the article content automatically.',
          ),
        ],
      ),
    );
  }

  // ── LANGUAGE SELECTOR ─────────────────────
  Widget _buildLanguageSelector() {
    return Row(
      children: [
        const TSectionLabel(label: 'Language'),
        SizedBox(width: 12),
        _LangChip(
            label: 'English',
            code: 'en',
            selected: _language == 'en',
            onTap: () => setState(() => _language = 'en')),
        SizedBox(width: 6),
        _LangChip(
            label: 'اردو',
            code: 'ur',
            selected: _language == 'ur',
            onTap: () => setState(() => _language = 'ur')),
        SizedBox(width: 6),
        _LangChip(
            label: 'Roman Urdu',
            code: 'roman_ur',
            selected: _language == 'roman_ur',
            onTap: () => setState(() => _language = 'roman_ur')),
      ],
    );
  }

  // ── BOTTOM BAR ────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: context.tSurface,
        border: Border(top: BorderSide(color: context.tBorder, width: 0.5)),
      ),
      child: TPrimaryButton(
        label: 'Analyse with TadbeerAI',
        icon: Icons.auto_awesome_rounded,
        isLoading: _analysing,
        onTap: _onAnalyse,
      ),
    );
  }

  // ── HANDLERS ──────────────────────────────
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) {
      setState(() => _pdfFileName = result.files.single.name);
      // Convert to base64 for API: _pdfBase64 = base64Encode(result.files.single.bytes!);
    }
  }

  void _fillSample(String key) {
    final samples = {
      'petrol':
          'Petrol prices in Pakistan have increased by Rs.15 per litre effective immediately, according to OGRA. The decision follows rising global crude prices. This is the third hike in six weeks, bringing the cumulative increase to Rs.38 per litre.',
      'rupee':
          'The Pakistani rupee fell to a record low of Rs.295 against the US dollar today as import payments pressured the interbank market. Analysts warn further depreciation is possible if the current account deficit widens.',
      'sales':
          'Q3 sales report shows a 25% decline in Lahore region. Customer orders dropped from 12,000 to 9,000 units compared to last quarter. Management attributes the decline to rising inflation and reduced consumer spending.',
      'port':
          'Karachi port congestion has worsened, with container clearance delays now reaching 5–7 business days. Importers are being advised to adjust inventory planning and explore alternative supply routes.',
    };
    setState(() {
      _textController.text = samples[key]!;
      _tabController.animateTo(0);
    });
  }

  /// Open a news source website in the browser so the user can find
  /// and copy a specific article URL.
  Future<void> _openSource(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Paste clipboard content into the URL field.
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() => _urlController.text = data.text!);
    }
  }

  Future<void> _onAnalyse() async {
    final tab = _tabController.index;
    String? text;
    String? url;

    if (tab == 0 && _textController.text.trim().isEmpty) {
      _showError('Please paste some text first');
      return;
    }
    if (tab == 1 && _pdfFileName == null) {
      _showError('Please upload a PDF first');
      return;
    }
    if (tab == 2 && _urlController.text.trim().isEmpty) {
      _showError('Please enter a URL first');
      return;
    }
    if (tab == 2) {
      final rawUrl = _urlController.text.trim();
      if (!rawUrl.startsWith('http://') && !rawUrl.startsWith('https://')) {
        _showError('URL must start with http:// or https://');
        return;
      }
      // Warn if it looks like a bare homepage (no path after domain)
      final uri = Uri.tryParse(rawUrl);
      if (uri != null &&
          (uri.path.isEmpty || uri.path == '/') &&
          uri.query.isEmpty) {
        _showError(
            'This looks like a homepage, not an article. Please paste a specific article URL.');
        return;
      }
    }

    if (tab == 0) text = _textController.text.trim();
    if (tab == 2) url = _urlController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InsightScreen(
          inputText: text,
          sourceUrl: url,
          language: _language,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: TColors.red,
        duration: const Duration(seconds: 2)));
  }
}

// ── REUSABLE SUB-WIDGETS ──────────────────────
class _SampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SampleChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: TColors.primaryLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: TColors.primary.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TColors.primaryDark)),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SourcePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: context.tSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.tBorder, width: 0.5),
        ),
        child: Text(label, style: context.tBodyMd),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label, code;
  final bool selected;
  final VoidCallback onTap;
  const _LangChip(
      {required this.label,
      required this.code,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? TColors.primary : context.tSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? TColors.primary : context.tBorder, width: 0.5),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : context.tTextSecondary)),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: TColors.primary.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TColors.primary),
          SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: TColors.primaryDark, height: 1.5))),
        ],
      ),
    );
  }
}
