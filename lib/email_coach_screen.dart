import 'package:flutter/material.dart';
import 'business_service.dart';
import 'business_models.dart';
import 'design_tokens.dart';
import 'ui_components.dart';
import 'gamification_service.dart';

class EmailCoachScreen extends StatefulWidget {
  const EmailCoachScreen({super.key});

  @override
  State<EmailCoachScreen> createState() => _EmailCoachScreenState();
}

class _EmailCoachScreenState extends State<EmailCoachScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final BusinessService _service = BusinessService();

  final _purposeController = TextEditingController();
  final _pointsController = TextEditingController();
  String _register = 'professional';
  EmailDraft? _draft;
  bool _draftLoading = false;

  final _critiqueController = TextEditingController();
  EmailCritique? _critique;
  bool _critiqueLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purposeController.dispose();
    _pointsController.dispose();
    _critiqueController.dispose();
    super.dispose();
  }

  Future<void> _generateDraft() async {
    if (_purposeController.text.trim().isEmpty) return;
    setState(() => _draftLoading = true);
    final draft = await _service.draftEmail(
      purpose: _purposeController.text.trim(),
      keyPoints: _pointsController.text.trim(),
      register: _register,
    );
    setState(() {
      _draft = draft;
      _draftLoading = false;
    });
    if (draft != null) await GamificationService.recordCompletion(xp: 10);
  }

  Future<void> _getCritique() async {
    if (_critiqueController.text.trim().isEmpty) return;
    setState(() => _critiqueLoading = true);
    final critique = await _service.critiqueEmail(_critiqueController.text.trim());
    setState(() {
      _critique = critique;
      _critiqueLoading = false;
    });
    if (critique != null) await GamificationService.recordCompletion(xp: 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Coach'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Draft New'),
          Tab(text: 'Improve Mine'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDraftTab(), _buildCritiqueTab()],
      ),
    );
  }

  Widget _buildDraftTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        TextField(
          controller: _purposeController,
          decoration: const InputDecoration(labelText: 'Purpose', hintText: 'e.g. "Follow up on a proposal"', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _pointsController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Key points (your real facts)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 8,
          children: ['casual', 'neutral', 'professional', 'formal'].map((r) => ChoiceChip(
                label: Text(r),
                selected: _register == r,
                onSelected: (_) => setState(() => _register = r),
              )).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Draft Email', onPressed: _generateDraft, loading: _draftLoading),
        if (_draft != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Subject: ${_draft!.subject}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(AppRadius.medium)),
            child: Text(_draft!.body),
          ),
          const SizedBox(height: 8),
          Text(_draft!.tips, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildCritiqueTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        TextField(
          controller: _critiqueController,
          maxLines: 8,
          decoration: const InputDecoration(labelText: 'Paste your email draft', border: OutlineInputBorder()),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Improve This', onPressed: _getCritique, loading: _critiqueLoading),
        if (_critique != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _card('Strength', _critique!.strength, AppColors.success),
          const SizedBox(height: 8),
          _card('Main Issue', _critique!.mainIssue, AppColors.warning),
          const SizedBox(height: 8),
          _card('Improved Version', _critique!.improvedVersion, AppColors.accentPrimary),
          const SizedBox(height: 8),
          Text(_critique!.explanation, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _card(String title, String body, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}
