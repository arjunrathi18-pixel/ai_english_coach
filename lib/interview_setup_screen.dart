import 'package:flutter/material.dart';
import 'interview_models.dart';
import 'interview_service.dart';
import 'interview_screen.dart';
import 'profile_store.dart';

class InterviewSetupScreen extends StatefulWidget {
  const InterviewSetupScreen({super.key});

  @override
  State<InterviewSetupScreen> createState() => _InterviewSetupScreenState();
}

class _InterviewSetupScreenState extends State<InterviewSetupScreen> {
  final _jobTitleController = TextEditingController();
  final _companyController = TextEditingController();
  final _industryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _resumeController = TextEditingController();
  final _jdController = TextEditingController();

  InterviewType _type = InterviewType.general;
  InterviewMode _mode = InterviewMode.practice;
  double _difficulty = 3;
  bool _generating = false;
  String _level = 'unknown';

  @override
  void initState() {
    super.initState();
    ProfileStore.load().then((p) {
      if (p != null) setState(() => _level = p.overallLevel);
    });
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _industryController.dispose();
    _experienceController.dispose();
    _responsibilitiesController.dispose();
    _resumeController.dispose();
    _jdController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_jobTitleController.text.trim().isEmpty ||
        _industryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in at least job title and industry.')),
      );
      return;
    }

    final profile = JobProfile(
      jobTitle: _jobTitleController.text.trim(),
      company: _companyController.text.trim(),
      industry: _industryController.text.trim(),
      experienceLevel: _experienceController.text.trim().isEmpty
          ? 'not specified'
          : _experienceController.text.trim(),
      keyResponsibilities: _responsibilitiesController.text.trim(),
      resumeText: _resumeController.text.trim(),
      jobDescriptionText: _jdController.text.trim(),
    );

    setState(() => _generating = true);
    final setup = await InterviewService().generateSetup(
      profile: profile,
      type: _type,
      mode: _mode,
      difficultyLevel: _difficulty.round(),
      level: _level,
    );
    setState(() => _generating = false);

    if (setup == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not set up the interview — try again.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewScreen(
          profile: profile,
          setup: setup,
          type: _type,
          mode: _mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_generating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your interview…'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Interview Practice')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Job details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _jobTitleController,
            decoration: const InputDecoration(labelText: 'Job title *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _companyController,
            decoration: const InputDecoration(labelText: 'Company (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _industryController,
            decoration: const InputDecoration(labelText: 'Industry *', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _experienceController,
            decoration: const InputDecoration(labelText: 'Experience level (e.g. "3 years", "fresher")', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _responsibilitiesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Key responsibilities (optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: const Text('Paste resume / job description (optional)'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _resumeController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Resume text', border: OutlineInputBorder()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _jdController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Job description text', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Interview type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InterviewType.values.map((t) {
              return ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: InterviewMode.values.map((m) {
              return ChoiceChip(
                label: Text(m.label),
                selected: _mode == m,
                onSelected: (_) => setState(() => _mode = m),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text('Difficulty: ${_difficulty.round()} / 6', style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _difficulty,
            min: 1,
            max: 6,
            divisions: 5,
            label: '${_difficulty.round()}',
            onChanged: (v) => setState(() => _difficulty = v),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Interview'),
          ),
        ],
      ),
    );
  }
}
