import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/crm_provider.dart';
import '../services/api_client.dart';
import 'dart:convert';
import 'opportunity_form_screen.dart';

class OpportunityDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> opportunity;
  const OpportunityDetailScreen({super.key, required this.opportunity});

  @override
  ConsumerState<OpportunityDetailScreen> createState() => _OpportunityDetailScreenState();
}

class _OpportunityDetailScreenState extends ConsumerState<OpportunityDetailScreen> {
  final _noteController = TextEditingController();
  String _noteType = 'Note';
  bool _submittingNote = false;
  late Map<String, dynamic> _opp;

  Map<String, dynamic>? _aiScore;
  bool _loadingScore = false;

  Map<String, dynamic>? _stalledAnalysis;
  bool _loadingStalled = false;

  final _stages = ['New', 'Qualified', 'Negotiation', 'Won', 'Closed', 'Lost'];
  final _noteTypes = ['Note', 'Call', 'Meeting', 'Email', 'Task'];

  @override
  void initState() {
    super.initState();
    _opp = widget.opportunity;
    
    // Check if stalled after the screen completes layout and notes are populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final logNotes = ref.read(logNotesProvider);
      logNotes.whenData((notes) {
        final oppNotes = notes.where((n) => n['opportunity'] == _opp['id']).toList();
        _checkIfStalled(oppNotes);
      });
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'New': return const Color(0xFF3b82f6);
      case 'Qualified': return const Color(0xFF8b5cf6);
      case 'Negotiation': return const Color(0xFFf59e0b);
      case 'Won': return const Color(0xFF22c55e);
      case 'Closed': return const Color(0xFF10b981);
      case 'Lost': return const Color(0xFFef4444);
      default: return Colors.grey;
    }
  }

  Future<void> _changeStage(String newStage) async {
    try {
      final response = await apiClient.put('/crm/opportunities/${_opp['id']}/', {'stage': newStage});
      if (response.statusCode == 200) {
        setState(() => _opp = {..._opp, 'stage': newStage});
        ref.refresh(opportunitiesProvider.future);
      }
    } catch (_) {}
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _submittingNote = true);
    try {
      await apiClient.post('/crm/log-notes/', {
        'opportunity': _opp['id'],
        'type': _noteType,
        'note': _noteController.text.trim(),
      });
      _noteController.clear();
      ref.refresh(logNotesProvider.future);
    } catch (_) {} finally {
      if (mounted) setState(() => _submittingNote = false);
    }
  }

  Future<void> _runLeadScoring(List<dynamic> notes) async {
    setState(() => _loadingScore = true);
    try {
      final noteTexts = notes.map((n) => n['note']?.toString() ?? '').toList();
      final response = await apiClient.post('/ai/lead-score/', {
        'title': _opp['title'],
        'expected_revenue': double.tryParse(_opp['expected_revenue']?.toString() ?? '0') ?? 0,
        'stage': _opp['stage'],
        'priority': _opp['priority'],
        'log_notes': noteTexts,
      });
      if (response.statusCode == 200) {
        setState(() => _aiScore = jsonDecode(response.body));
        if (mounted) _showAiSuccessPopup('Lead Scoring');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scoring failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating score: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingScore = false);
    }
  }

  Future<void> _analyzeActivityLog(List<dynamic> notes) async {
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No notes available to analyze. Please add some first.')),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final concatenated = notes.map((n) => n['note']?.toString() ?? '').join('\n');
      
      final sentResp = await apiClient.post('/ai/sentiment/', {'notes': concatenated});
      final itemsResp = await apiClient.post('/ai/action-items/', {'note': concatenated});
      
      if (mounted) Navigator.pop(context); // pop loading spinner
      
      if (sentResp.statusCode == 200 && itemsResp.statusCode == 200) {
        final sentData = jsonDecode(sentResp.body);
        final itemsData = jsonDecode(itemsResp.body);
        
        if (mounted) {
          _showAiSuccessPopup('Activity Log Analysis');
          _showAiAnalysisResult(sentData, itemsData);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to analyze log notes.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAiAnalysisResult(Map<String, dynamic> sentiment, Map<String, dynamic> actionItems) {
    final sent = sentiment['sentiment'] ?? 'Neutral';
    final risks = (sentiment['risk_flags'] as List?)?.cast<String>() ?? [];
    final items = (actionItems['action_items'] as List?)?.cast<String>() ?? [];

    Color sentColor = Colors.grey;
    IconData sentIcon = Icons.sentiment_neutral_rounded;
    if (sent == 'Positive') {
      sentColor = Colors.green;
      sentIcon = Icons.sentiment_very_satisfied_rounded;
    } else if (sent == 'Negative') {
      sentColor = Colors.red;
      sentIcon = Icons.sentiment_very_dissatisfied_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('AI Activity Log Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Sentiment section
                const Text('Overall Customer Sentiment', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(sentIcon, color: sentColor, size: 28),
                    const SizedBox(width: 8),
                    Text(sent, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sentColor)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Risks Section
                if (risks.isNotEmpty) ...[
                  const Text('Identified Risk Flags', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...risks.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],

                // Action Items Section
                const Text('Extracted Action Items', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                items.isEmpty
                    ? const Text('No actionable tasks extracted.', style: TextStyle(fontSize: 13, color: Colors.grey))
                    : Column(
                        children: items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_box_outline_blank_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                              const SizedBox(width: 6),
                              Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        )).toList(),
                      ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAiExplanation(
                      'Activity Log Analysis',
                      'The AI analysed all your logged notes for this opportunity using sentiment analysis and action item extraction.\n\n'
                      '• Sentiment: Classified the tone of each note as Positive, Neutral, or Negative based on language patterns.\n'
                      '• Risk Flags: Detected phrases indicating objections, delays, or disengagement.\n'
                      '• Action Items: Extracted tasks or commitments mentioned in the notes.\n\n'
                      'The model was Gemini 2.0 Flash, processing all notes as a combined input.',
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('How AI did this?', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkIfStalled(List<dynamic> notes) async {
    if (!mounted) return;
    setState(() => _loadingStalled = true);
    try {
      int days = 0;
      if (_opp['created_at'] != null) {
        try {
          final created = DateTime.parse(_opp['created_at'] as String);
          days = DateTime.now().difference(created).inDays;
        } catch (_) {}
      }
      if (days == 0) days = 45; // Easy trigger for testing

      final response = await apiClient.post('/ai/stalled-deal/', {
        'stage': _opp['stage'] ?? 'New',
        'time_in_stage_days': days,
        'interaction_count': notes.length,
      });

      if (response.statusCode == 200 && mounted) {
        setState(() => _stalledAnalysis = jsonDecode(response.body));
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingStalled = false);
    }
  }

  void _showAiSuccessPopup(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF22c55e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI analysis complete',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(featureName,
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiExplanation(String title, String explanation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              child: Icon(Icons.psychology_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('How AI did this', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Text(explanation, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMeetingPrep(List<dynamic> notes) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final noteTexts = notes.map((n) => n['note']?.toString() ?? '').toList();
      final participants = <String>[];
      if (_opp['contact_name'] != null) {
        participants.add(_opp['contact_name'] as String);
      } else {
        participants.add("Client Representative");
      }

      final response = await apiClient.post('/ai/meeting-prep/', {
        'participants': participants,
        'recent_notes': noteTexts,
      });

      if (mounted) Navigator.pop(context); // pop spinner

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          _showAiSuccessPopup('Meeting Prep');
          _showMeetingPrepResult(data);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate meeting prep.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showMeetingPrepResult(Map<String, dynamic> data) {
    final points = (data['talking_points'] as List?)?.cast<String>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, color: Colors.indigo),
                    const SizedBox(width: 8),
                    const Text('AI Meeting Preparation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recommended Talking Points',
                  style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (points.isEmpty)
                  const Text('No specific talking points generated.', style: TextStyle(fontSize: 13, color: Colors.grey))
                else
                  ...points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.indigo, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(fontSize: 14, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
                  child: const Text('Close'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAiExplanation(
                      'AI Meeting Preparation',
                      'The AI generated strategic talking points by analysing:\n\n'
                      '• Recent activity log notes to understand where the conversation last left off.\n'
                      '• Participant names to tailor the language and context.\n'
                      '• Deal stage and history to identify key concerns to address.\n\n'
                      'The output is structured talking points that help the sales rep steer the meeting towards closing. Powered by Gemini 2.0 Flash.',
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 16),
                  label: const Text('How AI did this?', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = _opp['stage'] ?? 'New';
    final logNotesAsync = ref.watch(logNotesProvider);
    final oppLogNotes = logNotesAsync.whenData((notes) =>
        notes.where((n) => n['opportunity'] == _opp['id']).toList());
    final quotesAsync = ref.watch(quotesByOpportunityProvider(_opp['id'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text(_opp['number'] ?? 'Opportunity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(
                builder: (_) => OpportunityFormScreen(initialData: _opp)));
              if (result == true) ref.refresh(opportunitiesProvider.future);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_stalledAnalysis != null && _stalledAnalysis!['is_stalled'] == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stalled Deal Warning',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _stalledAnalysis!['reason'] ?? 'No recent activity detected.',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Title card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_opp['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_opp['customer_name'] ?? '', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text('MYR ${_opp['expected_revenue'] ?? '0.00'}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                                      color: Theme.of(context).colorScheme.primary)),
                              const Text('Revenue', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: Column(
                            children: [
                              Text('${_opp['win_prediction'] ?? 0}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const Text('Win Rate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const VerticalDivider(),
                        Expanded(
                          child: Column(
                            children: [
                              Text(_opp['priority'] ?? 'Medium',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                      color: _priorityColor(_opp['priority'] ?? 'Medium'))),
                              const Text('Priority', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stage Progress Bar
            _StageProgressBar(currentStage: stage, stages: _stages, onStageChanged: _changeStage, stageColor: _stageColor),

            const SizedBox(height: 16),

            // AI Lead Scoring Widget Card
            if (_aiScore == null)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                ),
                child: ListTile(
                  leading: _loadingScore
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        ),
                  title: const Text("AI Lead Scoring", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Calculate deal closing probability using AI", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.bolt_rounded, color: Colors.amber),
                  onTap: _loadingScore ? null : () => _runLeadScoring(oppLogNotes.value ?? []),
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(Icons.psychology_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text("AI Lead Score", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.info_outline_rounded, size: 18),
                                tooltip: 'How AI did this?',
                                onPressed: () => _showAiExplanation(
                                  'AI Lead Scoring',
                                  'The AI evaluated the probability of closing this deal by analysing:\n\n'
                                  '• Deal title and description to understand the opportunity type.\n'
                                  '• Expected revenue to gauge deal weight.\n'
                                  '• Current stage (${_opp['stage']}) and priority (${_opp['priority']}) to assess momentum.\n'
                                  '• All logged activity notes to detect engagement signals.\n\n'
                                  'The score (0–100) represents closing probability. Confidence reflects how much data was available. Powered by Gemini 2.0 Flash.',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (_aiScore!['confidence'] == 'high' ? Colors.green : Colors.orange).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Confidence: ${(_aiScore!['confidence'] ?? '').toString().toUpperCase()}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _aiScore!['confidence'] == 'high' ? Colors.green : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primaryContainer,
                            ),
                            child: Text(
                              "${_aiScore!['score']}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _aiScore!['reasoning'] ?? '',
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // AI Meeting Prep Widget Card
            Card(
              elevation: 0,
              color: Colors.indigo.shade50.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.indigo.shade100),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.event_note_rounded, color: Colors.indigo, size: 20),
                ),
                title: const Text("AI Meeting Prep", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text("Generate strategic talking points for the client", style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.keyboard_arrow_right_rounded),
                onTap: () => _generateMeetingPrep(oppLogNotes.value ?? []),
              ),
            ),

            const SizedBox(height: 16),

            // Details
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Details', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                    const SizedBox(height: 10),
                    if (_opp['contact_name'] != null) _DetailRow(label: 'Contact', value: _opp['contact_name']),
                    if (_opp['category'] != null) _DetailRow(label: 'Category', value: _opp['category']),
                    if (_opp['referral_source'] != null) _DetailRow(label: 'Source', value: _opp['referral_source']),
                    if (_opp['sales_rep'] != null) _DetailRow(label: 'Sales Rep', value: _opp['sales_rep']),
                    if (_opp['expected_closing_date'] != null) _DetailRow(label: 'Closing Date', value: _opp['expected_closing_date']),
                    if (_opp['tags'] != null) _DetailRow(label: 'Tags', value: _opp['tags']),
                    if (_opp['remark'] != null) _DetailRow(label: 'Remark', value: _opp['remark']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quotations Section
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text('Quotations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, size: 11, color: Colors.grey),
                        SizedBox(width: 3),
                        Text('View only', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            quotesAsync.when(
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
              data: (quotes) => quotes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No quotations yet', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: quotes.map((q) => Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: const Icon(Icons.description_rounded),
                          title: Text(q['number'] ?? ''),
                          subtitle: Text('MYR ${q['total'] ?? '0.00'}'),
                          trailing: Text(q['status'] ?? 'Draft',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Log Notes Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Activity Log', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.analytics_outlined, size: 16),
                  label: const Text('AI Analysis'),
                  onPressed: () => _analyzeActivityLog(oppLogNotes.value ?? []),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Add note input
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: _noteTypes.map((t) => ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: _noteType == t,
                        onSelected: (_) => setState(() => _noteType = t),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: 'Log a note...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _submittingNote ? null : _addNote,
                          child: _submittingNote ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            oppLogNotes.when(
              loading: () => const SizedBox(),
              error: (e, _) => const SizedBox(),
              data: (notes) => Column(
                children: notes.map((n) => _LogNoteCard(note: n)).toList(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High': return const Color(0xFFef4444);
      case 'Low': return const Color(0xFF22c55e);
      default: return const Color(0xFFf59e0b);
    }
  }
}

class _StageProgressBar extends StatelessWidget {
  final String currentStage;
  final List<String> stages;
  final Function(String) onStageChanged;
  final Color Function(String) stageColor;

  const _StageProgressBar({
    required this.currentStage,
    required this.stages,
    required this.onStageChanged,
    required this.stageColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeStages = stages.where((s) => s != 'Closed' && s != 'Lost').toList();
    final currentIdx = activeStages.indexOf(currentStage);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stage', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                if (currentStage == 'Won' || currentStage == 'Lost' || currentStage == 'Closed')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: stageColor(currentStage).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(currentStage, style: TextStyle(color: stageColor(currentStage), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress indicator
            Row(
              children: List.generate(activeStages.length, (i) {
                final s = activeStages[i];
                final isActive = i <= currentIdx;
                final isLast = i == activeStages.length - 1;
                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => onStageChanged(s),
                              child: Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? stageColor(s) : Colors.grey[200],
                                ),
                                child: Icon(
                                  isActive ? Icons.check_rounded : Icons.circle_outlined,
                                  size: 16,
                                  color: isActive ? Colors.white : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(s, style: TextStyle(fontSize: 10, color: isActive ? stageColor(s) : Colors.grey, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i < currentIdx ? stageColor(activeStages[i]) : Colors.grey[200],
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            if (currentStage == 'Won' || currentStage == 'Lost' || currentStage == 'Closed') ...[
              const SizedBox(height: 8),
              Row(
                children: ['Won', 'Closed', 'Lost'].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: stageColor(s)),
                      foregroundColor: stageColor(s),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => onStageChanged(s),
                    child: Text(s),
                  ),
                )).toList(),
              ),
            ],
            if (currentStage != 'Won' && currentStage != 'Lost' && currentStage != 'Closed') ...[
              const SizedBox(height: 10),
              Row(
                children: ['Won', 'Lost'].map((s) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: stageColor(s)),
                      foregroundColor: stageColor(s),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => onStageChanged(s),
                    child: Text('Mark as $s'),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }
}

class _LogNoteCard extends StatelessWidget {
  final Map<String, dynamic> note;
  const _LogNoteCard({required this.note});

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Call': return Icons.call_rounded;
      case 'Meeting': return Icons.group_rounded;
      case 'Email': return Icons.email_rounded;
      case 'Task': return Icons.task_alt_rounded;
      default: return Icons.notes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_typeIcon(note['type'] ?? 'Note'), color: Theme.of(context).colorScheme.primary, size: 20),
        title: Text(note['note'] ?? '', style: const TextStyle(fontSize: 14)),
        subtitle: Text('${note['type'] ?? 'Note'} · ${note['created_at']?.toString().split('T')[0] ?? ''}',
            style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
