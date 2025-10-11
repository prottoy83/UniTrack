import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'editCourse.dart';

class CoursePage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CoursePage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  Map<String, dynamic>? _courseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final data = await DatabaseService.instance.getCourseDetails(widget.courseId);
      
      if (mounted) {
        setState(() {
          _courseData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading course data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAttendanceDialog() async {
    final attendance = _courseData?['attendance'];
    final daysAttendedController = TextEditingController(
      text: attendance?['daysAttended']?.toString() ?? '',
    );
    final totalDaysController = TextEditingController(
      text: attendance?['totalDays']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Attendance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysAttendedController,
              decoration: const InputDecoration(
                labelText: 'Days Attended',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalDaysController,
              decoration: const InputDecoration(
                labelText: 'Total Days',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final daysAttended = int.tryParse(daysAttendedController.text) ?? 0;
      final totalDays = int.tryParse(totalDaysController.text) ?? 0;

      if (totalDays > 0) {
        final success = await DatabaseService.instance.updateAttendance(
          widget.courseId,
          daysAttended,
          totalDays,
        );
        
        if (success) {
          _loadCourseData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance updated successfully')),
            );
          }
        }
      }
    }

    daysAttendedController.dispose();
    totalDaysController.dispose();
  }

  Future<void> _showAddScoreDialog() async {
    final titleController = TextEditingController();
    final gainedScoreController = TextEditingController();
    final totalScoreController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title (e.g., Quiz 1, Midterm)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: gainedScoreController,
              decoration: const InputDecoration(
                labelText: 'Gained Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalScoreController,
              decoration: const InputDecoration(
                labelText: 'Total Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final title = titleController.text.trim();
      final gainedScore = double.tryParse(gainedScoreController.text) ?? 0.0;
      final totalScore = double.tryParse(totalScoreController.text) ?? 0.0;

      if (title.isNotEmpty && totalScore > 0) {
        final success = await DatabaseService.instance.addScore(
          courseId: widget.courseId,
          title: title,
          gainedScore: gainedScore,
          totalScore: totalScore,
        );
        
        if (success) {
          _loadCourseData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Score added successfully')),
            );
          }
        }
      }
    }

    titleController.dispose();
    gainedScoreController.dispose();
    totalScoreController.dispose();
  }

  double _calculateAttendancePercentage() {
    final attendance = _courseData?['attendance'];
    if (attendance == null) return 0.0;
    
    final daysAttended = attendance['daysAttended'] as int? ?? 0;
    final totalDays = attendance['totalDays'] as int? ?? 1;
    
    return (daysAttended / totalDays) * 100;
  }

  Map<String, double> _calculateTotalScore() {
    final scores = _courseData?['scores'] as List<Map<String, dynamic>>? ?? [];
    
    double totalGained = 0.0;
    double totalPossible = 0.0;
    
    for (final score in scores) {
      totalGained += score['gainedScore'] as double? ?? 0.0;
      totalPossible += score['totalScore'] as double? ?? 0.0;
    }
    
    return {
      'gained': totalGained,
      'total': totalPossible,
    };
  }

  Color _getAttendanceColor() {
    final percentage = _calculateAttendancePercentage();
    final course = _courseData?['course'];
    final threshold = course?['attendanceThreshold'] as double? ?? 75.0;
    
    return percentage >= threshold ? Colors.green : Colors.red;
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.courseName),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_courseData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.courseName),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(
          child: Text('Course data not found'),
        ),
      );
    }

    final attendance = _courseData!['attendance'];
    final schedule = _courseData!['schedule'] as List<Map<String, dynamic>>;
    final scores = _courseData!['scores'] as List<Map<String, dynamic>>;
    final totalScore = _calculateTotalScore();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.courseName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCoursePage(
                    courseId: widget.courseId,
                    courseName: widget.courseName,
                  ),
                ),
              );
              
              // Reload data if course was updated
              if (result == true) {
                _loadCourseData();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _showAttendanceDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (attendance == null)
                      Text(
                        'Not added',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Text(
                            '${attendance['daysAttended']} / ${attendance['totalDays']} days',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getAttendanceColor(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_calculateAttendancePercentage().toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (schedule.isEmpty)
                      Column(
                        children: [
                          Text(
                            'No schedule added yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showScheduleModal(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Schedule'),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weekly schedule display
                          _buildWeeklyScheduleView(schedule),
                          
                          const SizedBox(height: 16),
                          
                          // Time display
                          _buildScheduleTimeDisplay(schedule),
                          
                          const SizedBox(height: 16),
                          
                          // Edit button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showScheduleModal(),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Schedule'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scores Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Scores',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddScoreDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Score'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Total Score Display
                    if (scores.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totalScore['gained']!.toStringAsFixed(1)} / ${totalScore['total']!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              '${((totalScore['gained']! / (totalScore['total']! > 0 ? totalScore['total']! : 1)) * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (scores.isNotEmpty) const SizedBox(height: 16),
                    
                    // Individual Scores
                    if (scores.isEmpty)
                      Text(
                        'Not added',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      )
                    else
                      ...scores.map((score) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(score['title'] as String),
                          subtitle: Text(
                            '${(score['gainedScore'] as double).toStringAsFixed(1)} / ${(score['totalScore'] as double).toStringAsFixed(1)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(((score['gainedScore'] as double) / (score['totalScore'] as double)) * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Edit score
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Edit score coming soon')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyScheduleView(List<Map<String, dynamic>> schedule) {
    const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    
    // Convert schedule to a set of days that have classes (using 0=Sunday format)
    final classDays = <int>{};
    for (var s in schedule) {
      // Convert day name string to integer (Monday=1, Sunday=7) then to Sunday=0 format
      String dayOfWeekString = s['dayOfWeek'] as String;
      int dayOfWeek = _convertDayNameToNumber(dayOfWeekString);
      int sundayBasedDay = dayOfWeek % 7; // Convert Monday=1 to Sunday=0 format
      classDays.add(sundayBasedDay);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: daysOfWeek.asMap().entries.map((entry) {
        int index = entry.key;
        String day = entry.value;
        bool hasClass = classDays.contains(index);

        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasClass 
                ? Colors.green.withOpacity(0.8)
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
            border: hasClass 
                ? Border.all(color: Colors.green, width: 2)
                : Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              day.substring(0, 1), // First letter only
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasClass 
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleTimeDisplay(List<Map<String, dynamic>> schedule) {
    if (schedule.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Times:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        ...schedule.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _getDayNameFromData(s['dayOfWeek']).substring(0, 3),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s['startTime'] ?? 'No start time'} - ${s['endTime'] ?? 'No end time'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (s['room'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${s['room']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getFullDayName(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek % 7];
  }

  void _showScheduleModal() {
    final currentSchedule = _courseData!['schedule'] as List<Map<String, dynamic>>;
    final semester = _courseData!['semester'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => _ScheduleModal(
        courseId: widget.courseId,
        courseName: widget.courseName,
        currentSchedule: currentSchedule,
        semester: semester,
        onScheduleUpdated: _loadCourseData,
      ),
    );
  }

  String _getDayNameFromData(dynamic dayOfWeek) {
    if (dayOfWeek is String) {
      return dayOfWeek; // Already a day name
    } else if (dayOfWeek is int) {
      return _getFullDayName(dayOfWeek); // Convert from integer
    }
    return 'Monday'; // Default fallback
  }

  int _convertDayNameToNumber(String dayName) {
    const dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return dayMap[dayName] ?? 1; // Default to Monday if not found
  }
}

class _ScheduleModal extends StatefulWidget {
  final int courseId;
  final String courseName;
  final List<Map<String, dynamic>> currentSchedule;
  final Map<String, dynamic>? semester;
  final VoidCallback onScheduleUpdated;

  const _ScheduleModal({
    required this.courseId,
    required this.courseName,
    required this.currentSchedule,
    required this.semester,
    required this.onScheduleUpdated,
  });

  @override
  State<_ScheduleModal> createState() => _ScheduleModalState();
}

class _ScheduleModalState extends State<_ScheduleModal> {
  List<Map<String, dynamic>> _scheduleEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scheduleEntries = List<Map<String, dynamic>>.from(
      widget.currentSchedule.map((schedule) => Map<String, dynamic>.from(schedule))
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime? semesterStart = widget.semester?['startDate'] != null 
        ? DateTime.parse(widget.semester!['startDate']) 
        : null;
    DateTime? semesterEnd = widget.semester?['endDate'] != null 
        ? DateTime.parse(widget.semester!['endDate']) 
        : null;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          widget.courseName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Semester date info (if available)
            if (semesterStart != null && semesterEnd != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semester: ${semesterStart.day}/${semesterStart.month}/${semesterStart.year} - ${semesterEnd.day}/${semesterEnd.month}/${semesterEnd.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Schedule entries
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_scheduleEntries.isEmpty) ...[
                      const SizedBox(height: 40),
                      Icon(
                        Icons.schedule_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No schedule entries yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first class schedule',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ] else ...[
                      const SizedBox(height: 16),
                      ..._scheduleEntries.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> schedule = entry.value;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getDayNameFromData(schedule['dayOfWeek']).substring(0, 3),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        schedule['startTime'] != null && schedule['endTime'] != null
                                            ? '${schedule['startTime']} - ${schedule['endTime']}'
                                            : 'No time set',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (schedule['room'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Room: ${schedule['room']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editScheduleEntry(index);
                                    } else if (value == 'delete') {
                                      _deleteScheduleEntry(index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 18),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addScheduleEntry,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Schedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveSchedule,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addScheduleEntry() {
    _showScheduleEntryDialog();
  }

  void _editScheduleEntry(int index) {
    _showScheduleEntryDialog(editingIndex: index);
  }

  void _deleteScheduleEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _scheduleEntries.removeAt(index);
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showScheduleEntryDialog({int? editingIndex}) {
    final isEditing = editingIndex != null;
    final existingEntry = isEditing ? _scheduleEntries[editingIndex] : null;

    // Handle both string and integer dayOfWeek values
    int selectedDay = 0; // Default to Monday
    if (existingEntry != null && existingEntry['dayOfWeek'] != null) {
      final dayOfWeek = existingEntry['dayOfWeek'];
      if (dayOfWeek is int) {
        selectedDay = dayOfWeek;
      } else if (dayOfWeek is String) {
        selectedDay = _convertDayNameToNumber(dayOfWeek) - 1; // Convert to 0-based index
      }
    }
    
    TimeOfDay startTime = existingEntry != null && existingEntry['startTime'] != null
        ? _parseTimeOfDay(existingEntry['startTime'])
        : existingEntry != null && existingEntry['time'] != null
        ? _parseTimeOfDay(existingEntry['time'])  // Fallback to old 'time' field
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = existingEntry != null && existingEntry['endTime'] != null
        ? _parseTimeOfDay(existingEntry['endTime'])
        : TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute); // Default to 1 hour after start
    String room = existingEntry?['room'] ?? '';

    final roomController = TextEditingController(text: room);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Schedule' : 'Add Schedule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Day selection
                DropdownButtonFormField<int>(
                  value: selectedDay,
                  decoration: const InputDecoration(
                    labelText: 'Day of Week',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Monday')),
                    DropdownMenuItem(value: 1, child: Text('Tuesday')),
                    DropdownMenuItem(value: 2, child: Text('Wednesday')),
                    DropdownMenuItem(value: 3, child: Text('Thursday')),
                    DropdownMenuItem(value: 4, child: Text('Friday')),
                    DropdownMenuItem(value: 5, child: Text('Saturday')),
                    DropdownMenuItem(value: 6, child: Text('Sunday')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDay = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Start time
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        startTime = time;
                        // Ensure end time is at least 30 minutes after start time
                        if (endTime.hour < startTime.hour || 
                            (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
                          endTime = TimeOfDay(
                            hour: startTime.hour + (startTime.minute >= 30 ? 1 : 0),
                            minute: (startTime.minute + 30) % 60,
                          );
                        }
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(startTime.format(context)),
                  ),
                ),

                const SizedBox(height: 16),

                // End time
                InkWell(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setDialogState(() {
                        endTime = time;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    child: Text(endTime.format(context)),
                  ),
                ),

                const SizedBox(height: 16),

                // Room
                TextFormField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Validate time
                if (endTime.hour < startTime.hour || 
                    (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time')),
                  );
                  return;
                }

                // Convert selectedDay to day name string
                const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                final dayOfWeekString = dayNames[selectedDay % 7];

                final entry = {
                  'id': existingEntry?['id'],
                  'courseId': widget.courseId,
                  'dayOfWeek': dayOfWeekString,
                  'startTime': _formatTimeOfDay(startTime),
                  'endTime': _formatTimeOfDay(endTime),
                  'room': roomController.text.trim().isEmpty ? null : roomController.text.trim(),
                };

                setState(() {
                  if (isEditing) {
                    _scheduleEntries[editingIndex] = entry;
                  } else {
                    _scheduleEntries.add(entry);
                  }
                });

                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSchedule() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete all existing schedule entries for this course
      await DatabaseService.instance.deleteSchedule(widget.courseId);

      // Add all new schedule entries
      for (final entry in _scheduleEntries) {
        await DatabaseService.instance.addSchedule(
          courseId: widget.courseId,
          dayOfWeek: entry['dayOfWeek'],
          startTime: entry['startTime'],
          endTime: entry['endTime'],
          room: entry['room'],
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onScheduleUpdated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Schedule updated successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getDayNameFromData(dynamic dayOfWeek) {
    if (dayOfWeek is String) {
      return dayOfWeek; // Already a day name
    } else if (dayOfWeek is int) {
      // Convert from integer (0=Monday format) to day name
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[dayOfWeek % 7];
    }
    return 'Monday'; // Default fallback
  }

  int _convertDayNameToNumber(String dayName) {
    const dayMap = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return dayMap[dayName] ?? 1; // Default to Monday if not found
  }
}
