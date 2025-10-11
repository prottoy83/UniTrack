import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import 'dashboard.dart';

class Course {
  String name;
  double credit;

  Course({required this.name, required this.credit});
}

class SetupSemesterPage extends StatefulWidget {
  final Map<String, dynamic>? existingSemester;
  
  const SetupSemesterPage({super.key, this.existingSemester});

  @override
  State<SetupSemesterPage> createState() => _SetupSemesterPageState();
}

class _SetupSemesterPageState extends State<SetupSemesterPage> {
  final TextEditingController _semesterController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  int _numberOfCourses = 1;
  final List<Course> _courses = [];
  final List<TextEditingController> _courseNameControllers = [];
  final List<TextEditingController> _courseCreditControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingSemester != null) {
      _isLoading = true;
      _initializeCourses(); // Initialize with default first
      _loadExistingSemesterData();
    } else {
      _initializeCourses();
    }
  }

  Future<void> _loadExistingSemesterData() async {
    try {
      final semester = widget.existingSemester!;
      
      // Set semester number
      _semesterController.text = semester['semesterNumber'].toString();
      
      // Get courses for this semester directly from database
      final database = await DatabaseService.instance.getDatabase();
      final coursesResult = await database.query(
        'course',
        where: 'semesterId = ?',
        whereArgs: [semester['id']],
      );
      
      setState(() {
        _numberOfCourses = coursesResult.length > 0 ? coursesResult.length : 1;
        _initializeCourses(); // Reinitialize with correct count
        
        // Populate course data
        for (int i = 0; i < coursesResult.length && i < _courseNameControllers.length; i++) {
          final courseName = coursesResult[i]['courseName'] as String?;
          final courseCredit = coursesResult[i]['credits'] as double?;
          
          _courseNameControllers[i].text = courseName ?? '';
          _courseCreditControllers[i].text = courseCredit?.toString() ?? '';
          _courses[i].name = courseName ?? '';
          _courses[i].credit = courseCredit ?? 0.0;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading existing semester data: $e');
      setState(() {
        _isLoading = false;
        _initializeCourses();
      });
    }
  }

  void _initializeCourses() {
    _courses.clear();
    _courseNameControllers.clear();
    _courseCreditControllers.clear();
    
    for (int i = 0; i < _numberOfCourses; i++) {
      _courses.add(Course(name: '', credit: 0.0));
      _courseNameControllers.add(TextEditingController());
      _courseCreditControllers.add(TextEditingController());
    }
  }

  void _updateNumberOfCourses(int newCount) {
    setState(() {
      _numberOfCourses = newCount;
      _initializeCourses();
    });
  }

  double _getTotalCredits() {
    double total = 0.0;
    for (int i = 0; i < _courseNameControllers.length; i++) {
      if (_courseCreditControllers[i].text.isNotEmpty) {
        total += double.tryParse(_courseCreditControllers[i].text) ?? 0.0;
      }
    }
    return total;
  }

  void _showConfirmationDialog() {
    // Update courses with current input values
    for (int i = 0; i < _courseNameControllers.length; i++) {
      _courses[i].name = _courseNameControllers[i].text.trim();
      _courses[i].credit = double.tryParse(_courseCreditControllers[i].text) ?? 0.0;
    }

    // Filter out empty courses
    List<Course> validCourses = _courses.where((course) => 
      course.name.isNotEmpty && course.credit > 0).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Semester ${_semesterController.text} Summary',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (validCourses.isEmpty)
                  const Text('No valid courses added.')
                else ...[
                  const Text(
                    'Courses:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...validCourses.map((course) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${course.credit.toStringAsFixed(1)} credits',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Credits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getTotalCredits().toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _saveSemesterData();
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSemesterData() async {
    try {
      // Prepare course data for database
      List<Map<String, dynamic>> courseData = [];
      
      for (int i = 0; i < _courseNameControllers.length; i++) {
        final courseName = _courseNameControllers[i].text.trim();
        final creditText = _courseCreditControllers[i].text.trim();
        
        if (courseName.isNotEmpty && creditText.isNotEmpty) {
          final credits = double.tryParse(creditText) ?? 0.0;
          if (credits > 0) {
            courseData.add({
              'name': courseName,
              'credits': credits,
            });
          }
        }
      }
      
      if (courseData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one valid course'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final semesterNumber = int.tryParse(_semesterController.text) ?? 1;
      bool success = false;
      
      if (widget.existingSemester != null) {
        // Update existing semester
        success = await _updateExistingSemester(widget.existingSemester!, semesterNumber, courseData);
      } else {
        // Create new semester
        success = await DatabaseService.instance.insertSemester(
          semesterNumber: semesterNumber,
          courses: courseData,
        );
      }
      
      if (!mounted) return;
      
      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingSemester != null 
              ? 'Semester $semesterNumber updated successfully!'
              : 'Semester $semesterNumber saved successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Navigate to dashboard after successful setup
        if (widget.existingSemester != null) {
          // If editing existing semester, go back to previous page
          Navigator.of(context).pop(true);
        } else {
          // If this is initial setup, navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardPage()),
          );
        }
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingSemester != null 
              ? 'Failed to update semester data'
              : 'Failed to save semester data'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving semester: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _updateExistingSemester(
    Map<String, dynamic> semester, 
    int semesterNumber, 
    List<Map<String, dynamic>> courseData
  ) async {
    try {
      final database = await DatabaseService.instance.getDatabase();
      final semesterId = semester['id'] as int;
      
      // Update semester number
      await database.update(
        'semester',
        {'semesterNumber': semesterNumber},
        where: 'id = ?',
        whereArgs: [semesterId],
      );
      
      // Delete existing courses for this semester
      await database.delete(
        'course',
        where: 'semesterId = ?',
        whereArgs: [semesterId],
      );
      
      // Insert updated courses
      for (final course in courseData) {
        await database.insert('course', {
          'semesterId': semesterId,
          'courseName': course['name'],
          'credits': course['credits'],
        });
      }
      
      return true;
    } catch (e) {
      print('Error updating semester: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _semesterController.dispose();
    for (var controller in _courseNameControllers) {
      controller.dispose();
    }
    for (var controller in _courseCreditControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSemester != null ? 'Edit Semester' : 'Setup Semester'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading 
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Semester Number Input
              Text(
                'Semester Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _semesterController,
                decoration: InputDecoration(
                  labelText: 'Semester Number',
                  hintText: 'Enter semester number (e.g., 1, 2, 3...)',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter semester number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Number of Courses Selection
              Text(
                'Number of Courses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _numberOfCourses,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: List.generate(20, (index) => index + 1)
                        .map((number) => DropdownMenuItem<int>(
                              value: number,
                              child: Text('$number course${number > 1 ? 's' : ''}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateNumberOfCourses(value);
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Courses Input Section
              Text(
                'Course Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              
              ...List.generate(_numberOfCourses, (index) {
                // Safety check to ensure controllers exist
                if (index >= _courseNameControllers.length || index >= _courseCreditControllers.length) {
                  return const SizedBox.shrink();
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course ${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _courseNameControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Course Name',
                                    hintText: 'e.g., Mathematics',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _courseCreditControllers[index],
                                  decoration: InputDecoration(
                                    labelText: 'Credits',
                                    hintText: '3.0',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24),
              
              // Total Credits Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Credits:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      _getTotalCredits().toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Done Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _showConfirmationDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
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
}
