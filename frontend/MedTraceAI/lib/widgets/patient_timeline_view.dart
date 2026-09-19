import 'package:flutter/material.dart';
import '../models/med_document.dart';
import '../models/patient_profile.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class PatientTimelineView extends StatefulWidget {
  final PatientTimeline? timeline;
  final PatientProfile? currentPatient;
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback? onUpload;
  final VoidCallback? onAddManualEvent;
  final Function(String documentId)? onInspectDocument;
  final Function(String documentId, String documentName)? onAskCopilot;

  const PatientTimelineView({
    super.key,
    required this.timeline,
    this.currentPatient,
    required this.isLoading,
    required this.onRefresh,
    this.onUpload,
    this.onAddManualEvent,
    this.onInspectDocument,
    this.onAskCopilot,
  });

  @override
  State<PatientTimelineView> createState() => _PatientTimelineViewState();
}

class _PatientTimelineViewState extends State<PatientTimelineView> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TimelineEvent> get _filteredEvents {
    if (widget.timeline == null) return [];
    var list = widget.timeline!.events;
    if (_selectedCategory != 'ALL') {
      list = list.where((e) => e.category.toUpperCase() == _selectedCategory.toUpperCase()).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((e) {
        return e.title.toLowerCase().contains(q) ||
            e.date.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            e.documentName.toLowerCase().contains(q) ||
            e.items.any((item) => item.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }


  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.timeline == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    final timeline = widget.timeline;
    final events = _filteredEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Timeline Control Bar
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'PATIENT TIMELINE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          '${events.length} Events',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141418),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          widget.currentPatient != null
                              ? 'Patient: ${widget.currentPatient!.name} (${widget.currentPatient!.patientId}) • ${widget.currentPatient!.bloodGroup}'
                              : (timeline?.patientName.isNotEmpty == true
                                  ? 'Patient: ${timeline!.patientName}'
                                  : 'Patient: Arun Kumar (PAT-0001) • B+'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chronological longitudinal trajectory synthesized from ingested medical records.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),


            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white70),
              tooltip: 'Refresh Timeline',
              onPressed: widget.onRefresh,
            ),
          ],
        ),

        const SizedBox(height: 16),



        const SizedBox(height: 8),

        // Controls Row: Filter chips + In-timeline Search
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Events'),
                  const SizedBox(width: 8),
                  _buildFilterChip('LABORATORY', '🧪 Labs'),
                  const SizedBox(width: 8),
                  _buildFilterChip('CLINICAL_VISIT', '🩺 Visits'),
                  const SizedBox(width: 8),
                  _buildFilterChip('PRESCRIPTION', '💊 Prescriptions'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IMAGING', '🩻 Imaging'),
                  const SizedBox(width: 8),
                  _buildFilterChip('FOLLOW_UP', '🩺 Follow-up'),
                ],
              ),
            ),

            // Fast In-Timeline Search Box
            Container(
              width: 220,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search timeline items...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white70),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Timeline Events List
        if (events.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.timeline_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  const Text(
                    'No Timeline Events Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload clinical reports or load the patient dataset to synthesize the trajectory.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Load Demo Patient Trajectory'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF090A0D),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final ev = events[index];
              final isLast = index == events.length - 1;
              return _buildTimelineNode(ev, isLast);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String catKey, String label) {
    final isSelected = _selectedCategory == catKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: isSelected,
      checkmarkColor: const Color(0xFF090A0E),
      onSelected: (_) {
        setState(() {
          _selectedCategory = catKey;
        });
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? const Color(0xFF090A0E) : AppColors.textSecondary,
      ),
      selectedColor: Colors.white,
      backgroundColor: const Color(0xFF141418),
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildTimelineNode(TimelineEvent ev, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date column on the left
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    ev.date,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Vertical line with connector icon
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141418),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  ev.icon,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 70 + (ev.items.length * 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.35),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(width: 16),

        // Event Content Card on the right
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: GlassCard(
              enableHover: true,
              padding: const EdgeInsets.all(16),
              borderColor: Colors.white.withValues(alpha: 0.18),
              backgroundColor: const Color(0xFF0D0D11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header with Category Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          ev.category.replaceAll('_', ' '),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${ev.icon} ${ev.title}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.onAskCopilot != null && ev.documentId.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.forum_outlined, size: 16, color: Colors.white70),
                          tooltip: 'Ask MedBot about this event',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: () => widget.onAskCopilot!(ev.documentId, ev.documentName),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Key items with intelligent badge highlighting
                  ...ev.items.map(
                    (item) {
                      final isAlert = item.contains('Elevated') ||
                          item.contains('High') ||
                          item.contains('Critical') ||
                          item.contains('Abnormal');

                       return Padding(
                         padding: const EdgeInsets.symmetric(vertical: 3),
                         child: Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Container(
                               margin: const EdgeInsets.only(top: 6, right: 8),
                               width: 6,
                               height: 6,
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: isAlert ? Colors.white : const Color(0xFFA1A1AA),
                               ),
                             ),
                             Expanded(
                               child: Text(
                                 item,
                                 style: TextStyle(
                                   fontSize: 13,
                                   color: isAlert ? Colors.white : const Color(0xFFD4D4D8),
                                   fontWeight: isAlert ? FontWeight.w700 : FontWeight.w400,
                                   height: 1.35,
                                 ),
                               ),
                             ),
                           ],
                         ),
                       );
                    },
                  ),

                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  const SizedBox(height: 8),

                  // Source Document Link
                  InkWell(
                    onTap: (widget.onInspectDocument != null && ev.documentId.isNotEmpty)
                        ? () => widget.onInspectDocument!(ev.documentId)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              ev.documentName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

  }

}
