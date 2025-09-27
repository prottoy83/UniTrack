import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';

class EditCoursePage extends StatefulWidget {
  final int courseId;
  final String courseName;

  const EditCoursePage({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _creditsController = TextEditingController();
  final _thresholdController = TextEditingController();
  
  Map<String, dynamic>? _courseData;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    try {
      final data = await DatabaseService.instance.getCourseDetails(widget.courseId);
      if (mounted && data != null) {
        final course = data['course'];
        setState(() {
          _courseData = data;
          _courseNameController.text = course['courseName'] ?? '';
          _creditsController.text = (course['credits'] as double?)?.toString() ?? '';
          _thresholdController.text = (course['attendanceThreshold'] as double?)?.toString() ?? '75.0';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final success = await DatabaseService.instance.updateCourse(
        courseId: widget.courseId,
        courseName: _courseNameController.text.trim(),
        credits: double.parse(_creditsController.text),
        attendanceThreshold: double.parse(_thresholdController.text),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course updated successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update course'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteAttendance() async {
    final confirmed = await _showDeleteConfirmation('attendance data');
    if (confirmed) {
      final success = await DatabaseService.instance.deleteAttendance(widget.courseId);
      if (success) {
        _loadCourseData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance data deleted')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllScores() async {
    final confirmed = await _showDeleteConfirmation('all scores');
    if (confirmed) {
      final success = await DatabaseService.instance.deleteAllScores(widget.courseId);
      if (success) {
        _loadCourseData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All scores deleted')),
          );
        }
      }
    }
  }

  Future<void> _deleteSchedule() async {
    final confirmed = await _showDeleteConfirmation('schedule');
    if (confirmed) {
      final success = await DatabaseService.instance.deleteSchedule(widget.courseId);
      if (success) {
        _loadCourseData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule deleted')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String itemType) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete $itemType? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _creditsController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Course'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _updateCourse,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Information Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _courseNameController,
                              decoration: const InputDecoration(
                                labelText: 'Course Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.book),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter course name';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _creditsController,
                              decoration: const InputDecoration(
                                labelText: 'Credits',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.grade),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter credits';
                                }
                                final credits = double.tryParse(value);
                                if (credits == null || credits <= 0) {
                                  return 'Please enter valid credits';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _thresholdController,
                              decoration: const InputDecoration(
                                labelText: 'Attendance Threshold (%)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                                helperText: 'Minimum attendance percentage required',
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter threshold percentage';
                                }
                                final threshold = double.tryParse(value);
                                if (threshold == null || threshold < 0 || threshold > 100) {
                                  return 'Please enter valid percentage (0-100)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Data Management Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Attendance Data
                            _buildDataRow(
                              icon: Icons.event_available,
                              title: 'Attendance Data',
                              hasData: _courseData?['attendance'] != null,
                              onDelete: _deleteAttendance,
                            ),
                            
                            const Divider(),
                            
                            // Schedule Data
                            _buildDataRow(
                              icon: Icons.schedule,
                              title: 'Schedule',
                              hasData: (_courseData?['schedule'] as List?)?.isNotEmpty ?? false,
                              onDelete: _deleteSchedule,
                            ),
                            
                            const Divider(),
                            
                            // Scores Data
                            _buildDataRow(
                              icon: Icons.assessment,
                              title: 'All Scores',
                              hasData: (_courseData?['scores'] as List?)?.isNotEmpty ?? false,
                              onDelete: _deleteAllScores,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required String title,
    required bool hasData,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  hasData ? 'Data available' : 'No data',
                  style: TextStyle(
                    color: hasData 
                        ? Colors.green 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasData)
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }
}
