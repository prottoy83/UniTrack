import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import 'setupSemester.dart';
import 'profilePage.dart';
import 'CoursePage.dart';
import '../settingsPage.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with WidgetsBindingObserver {
  Map<String, dynamic>? _semesterData;
  bool _isLoading = true;
  List<Map<String, dynamic>> _todaysClasses = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshDashboardData();
    }
  }

  // Unified method to refresh all dashboard data
  Future<void> _refreshDashboardData() async {
    await _checkSemesterData();
    await _loadTodaysClasses();
  }

  Future<void> _checkSemesterData() async {
    try {
      final hasSemester = await DatabaseService.instance.hasSemesterData();
      
      if (!hasSemester) {
        // No semester data, navigate to setup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SetupSemesterPage()),
          );
        }
        return;
      }
      
      // Get latest semester data
      final semesterData = await DatabaseService.instance.getLatestSemesterData();
      
      if (mounted) {
        setState(() {
          _semesterData = semesterData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking semester data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showFullScreenMenu(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_semesterData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _showFullScreenMenu(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No semester data found',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SetupSemesterPage()),
                  );
                },
                child: const Text('Setup Semester'),
              ),
            ],
          ),
        ),
      );
    }

    final semester = _semesterData!['semester'] as Map<String, dynamic>;
    final courses = _semesterData!['courses'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _showFullScreenMenu(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SetupSemesterPage()),
              );
            },
            tooltip: 'Add New Semester',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Semester Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Semester ${semester['semesterNumber']}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _editSemester(semester),
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Edit Semester',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(semester['totalCredits'] as double).toStringAsFixed(1)} Credits',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${courses.length} Course${courses.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Today's Classes Panel
            _buildTodaysClassesPanel(),
            
            const SizedBox(height: 16),
            
            // Semester Dates Section
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
                          'Semester Dates',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showSemesterDatesModal(context, semester),
                          icon: Icon(
                            semester['startDate'] != null ? Icons.edit : Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: semester['startDate'] != null ? 'Edit Dates' : 'Add Dates',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                semester['startDate'] != null 
                                  ? (() {
                                      DateTime startDate = DateTime.parse(semester['startDate']);
                                      return '${startDate.day}/${startDate.month}/${startDate.year}';
                                    })()
                                  : 'Not set',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: semester['startDate'] != null 
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                semester['endDate'] != null 
                                  ? (() {
                                      DateTime endDate = DateTime.parse(semester['endDate']);
                                      return '${endDate.day}/${endDate.month}/${endDate.year}';
                                    })()
                                  : 'Not set',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: semester['endDate'] != null 
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (semester['startDate'] != null && semester['endDate'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          (() {
                            DateTime startDate = DateTime.parse(semester['startDate']);
                            DateTime endDate = DateTime.parse(semester['endDate']);
                            int duration = endDate.difference(startDate).inDays + 1;
                            return 'Duration: $duration days';
                          })(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Courses Section
            Text(
              'Courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Course List
            if (courses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No courses found',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              )
            else
              ...courses.map((course) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoursePage(
                            courseId: course['id'] as int,
                            courseName: course['courseName'] as String,
                          ),
                        ),
                      );
                      // Refresh dashboard data when returning from course page
                      _refreshDashboardData();
                    },
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        course['courseName'].toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      course['courseName'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(course['credits'] as double).toStringAsFixed(1)} cr',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            
            const SizedBox(height: 32),
          ],
        ),
      ), // End of SingleChildScrollView
    ), // End of RefreshIndicator body
    ); // End of Scaffold
  }

  void _showSemesterDatesModal(BuildContext context, Map<String, dynamic> semester) {
    DateTime? startDate = semester['startDate'] != null 
        ? DateTime.parse(semester['startDate']) 
        : null;
    DateTime? endDate = semester['endDate'] != null 
        ? DateTime.parse(semester['endDate']) 
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Semester Dates',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Date
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Start Date'),
                  subtitle: Text(
                    startDate != null 
                        ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                        : 'Select start date',
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                        // If end date is before start date, clear it
                        if (endDate != null && endDate!.isBefore(picked)) {
                          endDate = null;
                        }
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // End Date
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                child: ListTile(
                  leading: Icon(
                    Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('End Date'),
                  subtitle: Text(
                    endDate != null 
                        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                        : 'Select end date',
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
                      });
                    }
                  },
                ),
              ),
              
              if (startDate != null && endDate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duration: ${endDate!.difference(startDate!).inDays + 1} days',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await DatabaseService.instance.updateSemesterDates(
                  semesterId: semester['id'],
                  startDate: startDate?.toIso8601String(),
                  endDate: endDate?.toIso8601String(),
                );
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _checkSemesterData(); // Refresh the dashboard
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Semester dates updated successfully'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating dates: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTodaysClasses() async {
    try {
      final today = DateTime.now();
      final todayName = _getDayName(today.weekday);
      
      print('DEBUG: Loading today\'s classes for $todayName');

      // Get all schedules for today
      final database = await DatabaseService.instance.getDatabase();
      
      // Debug: Check what columns actually exist in the schedule table
      final scheduleSchema = await database.rawQuery('PRAGMA table_info(schedule)');
      print('DEBUG: Schedule table schema: $scheduleSchema');
      
      // Debug: Check what columns actually exist in the course table  
      final courseSchema = await database.rawQuery('PRAGMA table_info(course)');
      print('DEBUG: Course table schema: $courseSchema');
      
      final schedules = await database.rawQuery('''
        SELECT s.*, c.courseName as courseName 
        FROM schedule s
        JOIN course c ON s.courseId = c.id
        WHERE s.dayOfWeek = ?
        ORDER BY s.startTime
      ''', [todayName]);

      List<Map<String, dynamic>> classesWithAttendance = [];
      
      for (final schedule in schedules) {
        final hasAttendance = await _hasAttendanceForToday(schedule['id'] as int);
        
        classesWithAttendance.add({
          'courseId': schedule['courseId'],
          'courseName': schedule['courseName'],
          'startTime': schedule['startTime'],
          'endTime': schedule['endTime'],
          'room': schedule['room'],
          'hasAttendance': hasAttendance,
          'scheduleId': schedule['id'],
        });
      }
      
      if (mounted) {
        setState(() {
          _todaysClasses = classesWithAttendance;
        });
      }
    } catch (e) {
      print('Error loading today\'s classes: $e');
      if (mounted) {
        setState(() {
          _todaysClasses = [];
        });
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }

  Future<bool> _hasAttendanceForToday(int scheduleId) async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final status = await DatabaseService.instance.getClassAttendanceStatus(
        scheduleId: scheduleId,
        date: dateString,
      );
      
      return status != null;
    } catch (e) {
      print('Error checking attendance for today: $e');
      return false;
    }
  }

  Widget _buildTodaysClassesPanel() {
    final today = DateTime.now();
    final formattedDate = '${_getDayName(today.weekday)}, ${today.day}/${today.month}/${today.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Classes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_todaysClasses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.free_breakfast,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No classes today! Enjoy your free time.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...(_todaysClasses.map((classInfo) => _buildClassAttendanceCard(classInfo)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildClassAttendanceCard(Map<String, dynamic> classInfo) {
    final hasAttendance = classInfo['hasAttendance'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasAttendance 
          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3)
          : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAttendance
            ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
            : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classInfo['courseName'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: hasAttendance 
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            classInfo['startTime'] ?? 'No time set',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (classInfo['room'] != null && classInfo['room'].toString().isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.room,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              classInfo['room'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasAttendance)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Recorded',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (!hasAttendance) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markClassAttendance(classInfo, 'attended'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Attended'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markClassAttendance(classInfo, 'skipped'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Skipped'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markClassAttendance(classInfo, 'cancelled'),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancelled'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markClassAttendance(Map<String, dynamic> classInfo, String status) async {
    try {
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final success = await DatabaseService.instance.markClassAttendance(
        scheduleId: classInfo['scheduleId'],
        date: dateString,
        status: status,
      );
      
      if (success) {
        // If this was an attendance or skip (not cancelled), also update the old attendance system
        if (status == 'attended' || status == 'skipped') {
          await DatabaseService.instance.addAttendanceRecord(
            classInfo['courseId'], 
            today, 
            isPresent: status == 'attended'
          );
        }
        
        // Refresh today's classes to update UI
        await _loadTodaysClasses();
        
        // Show confirmation
        if (mounted) {
          String message;
          Color color;
          switch (status) {
            case 'attended':
              message = 'Marked as attended!';
              color = Colors.green;
              break;
            case 'skipped':
              message = 'Marked as skipped';
              color = Colors.orange;
              break;
            case 'cancelled':
              message = 'Marked as cancelled';
              color = Colors.grey;
              break;
            default:
              message = 'Attendance recorded';
              color = Colors.blue;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: color,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to record attendance'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error marking attendance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error recording attendance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editSemester(Map<String, dynamic> semester) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SetupSemesterPage(existingSemester: semester),
      ),
    );
    
    // Refresh dashboard if semester was updated
    if (result == true) {
      _refreshDashboardData();
    }
  }

  void _showFullScreenMenu(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _FullScreenMenu(),
        fullscreenDialog: true,
      ),
    );
    // Refresh dashboard data when returning from menu
    // (in case any navigation from menu affected data)
    _refreshDashboardData();
  }
}

class _FullScreenMenu extends StatelessWidget {
  const _FullScreenMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // Profile Section
                    _buildMenuCard(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'View and edit your profile information',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                        // Note: Profile changes don't typically affect semester data
                      },
                    ),

                    const SizedBox(height: 16),

                    // Settings Section
                    _buildMenuCard(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences and configuration',
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // About Section
                    _buildMenuCard(
                      context,
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App information and version details',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),

                    const Spacer(),

                    // Attribution section at bottom
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.code,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Made by Prottoy Roy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _launchGitHub(),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.link,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'github.com/prottoy83',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _launchGitHub(),
                            icon: Icon(
                              Icons.open_in_new,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'Visit GitHub Profile',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About UniTrack'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UniTrack - University Course Tracker',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A comprehensive Flutter application for tracking university courses, attendance, schedules, and academic progress.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.flutter_dash,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Built with Flutter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.developer_mode,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _launchGitHub();
            },
            child: const Text('View Source'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchGitHub() async {
    final uri = Uri.parse('https://github.com/prottoy83');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch $uri');
      }
    } catch (e) {
      print('Error launching URL: $e');
    }
  }
}
