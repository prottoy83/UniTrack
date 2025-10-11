import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._constructor();
  
  DatabaseService._constructor();
  
  static DatabaseService get instance => _instance;

  Future<void> initializeDatabase() async {
    try {
      final db = await getDatabase();
      
      // Debug: Check current database version
      final version = await db.getVersion();
      print('DEBUG: Current database version: $version');
      
      await _ensureTablesExist(db);
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
    }
  }
  
  Future<Database> getDatabase() async{
    final databaseDir = await getDatabasesPath();

    final databasePath = join(databaseDir, 'unitrack.db');

    final database = await openDatabase(
      databasePath,
      version: 5, // Updated version for separate time fields and attendance tracking
      onCreate: (db, version) async {
        print('DEBUG: onCreate called with version $version');
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        print('DEBUG: onUpgrade called from version $oldVersion to $newVersion');
        print('Upgrading database from version $oldVersion to $newVersion');
        if (oldVersion < 2) {
          // Add new tables for version 2
          await _addNewTables(db);
        }
        if (oldVersion < 3) {
          // Add semester dates for version 3
          await _addSemesterDates(db);
        }
        if (oldVersion < 4) {
          // Update schedule table schema for version 4
          await _updateScheduleTableSchema(db);
        }
        if (oldVersion < 5) {
          // Add separate start/end times and attendance tracking for version 5
          print('DEBUG: Calling _addTimeFieldsAndAttendanceTracking');
          await _addTimeFieldsAndAttendanceTracking(db);
        }
      },
      onOpen: (db) async {
        print('DEBUG: onOpen called');
        // Ensure tables exist even if onCreate wasn't called
        await _ensureTablesExist(db);
      },
    );

    return database;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        universityName TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS semester (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semesterNumber INTEGER NOT NULL,
        totalCredits REAL NOT NULL,
        createdAt TEXT NOT NULL,
        startDate TEXT,
        endDate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS course (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        semesterId INTEGER NOT NULL,
        courseName TEXT NOT NULL,
        credits REAL NOT NULL,
        attendanceThreshold REAL DEFAULT 75.0,
        FOREIGN KEY (semesterId) REFERENCES semester (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        daysAttended INTEGER NOT NULL,
        totalDays INTEGER NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        dayOfWeek TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        room TEXT,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('attended', 'skipped', 'cancelled')),
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (scheduleId) REFERENCES schedule (id) ON DELETE CASCADE,
        UNIQUE(scheduleId, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS score (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        title TEXT NOT NULL,
        gainedScore REAL NOT NULL,
        totalScore REAL NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _addNewTables(Database db) async {
    // Add attendanceThreshold column to course table if it doesn't exist
    try {
      await db.execute('ALTER TABLE course ADD COLUMN attendanceThreshold REAL DEFAULT 75.0');
      print('Added attendanceThreshold column to course table');
    } catch (e) {
      // Column might already exist, ignore error
      print('attendanceThreshold column might already exist: $e');
    }

    // Create new tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        daysAttended INTEGER NOT NULL,
        totalDays INTEGER NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        dayOfWeek TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        room TEXT,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS class_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('attended', 'skipped', 'cancelled')),
        createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (scheduleId) REFERENCES schedule (id) ON DELETE CASCADE,
        UNIQUE(scheduleId, date)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS score (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        title TEXT NOT NULL,
        gainedScore REAL NOT NULL,
        totalScore REAL NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
      )
    ''');
    
    print('New tables created successfully');
  }

  Future<void> _addSemesterDates(Database db) async {
    try {
      // Add startDate and endDate columns to semester table
      await db.execute('ALTER TABLE semester ADD COLUMN startDate TEXT');
      await db.execute('ALTER TABLE semester ADD COLUMN endDate TEXT');
      print('Added semester date columns');
    } catch (e) {
      // Columns might already exist, ignore error
      print('Semester date columns might already exist: $e');
    }
  }

  Future<void> _updateScheduleTableSchema(Database db) async {
    try {
      // First, rename the old table
      await db.execute('ALTER TABLE schedule RENAME TO schedule_old');
      
      // Create new schedule table with updated schema
      await db.execute('''
        CREATE TABLE schedule (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          courseId INTEGER NOT NULL,
          dayOfWeek TEXT NOT NULL,
          time TEXT NOT NULL,
          room TEXT,
          FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
        )
      ''');
      
      // Migrate data from old table to new table
      final oldSchedules = await db.query('schedule_old');
      for (final schedule in oldSchedules) {
        final dayOfWeekInt = schedule['dayOfWeek'] as int;
        final dayOfWeekString = _convertDayOfWeekToString(dayOfWeekInt);
        final startTime = schedule['startTime'] as String;
        
        await db.insert('schedule', {
          'id': schedule['id'],
          'courseId': schedule['courseId'],
          'dayOfWeek': dayOfWeekString,
          'time': startTime, // Use startTime as the notification time
          'room': schedule['room'],
        });
      }
      
      // Drop the old table
      await db.execute('DROP TABLE schedule_old');
      print('Updated schedule table schema successfully');
    } catch (e) {
      print('Error updating schedule table schema: $e');
    }
  }

  Future<void> _addTimeFieldsAndAttendanceTracking(Database db) async {
    try {
      print('DEBUG: Migration method called - _addTimeFieldsAndAttendanceTracking');
      print('Starting migration to add separate time fields and attendance tracking...');
      
      // Step 1: Backup existing schedule data
      final existingSchedules = await db.query('schedule');
      print('Found ${existingSchedules.length} existing schedules to migrate');
      
      // Step 2: Drop and recreate schedule table with new schema
      await db.execute('DROP TABLE IF EXISTS schedule');
      await db.execute('''
        CREATE TABLE schedule (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          courseId INTEGER NOT NULL,
          dayOfWeek TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          room TEXT,
          FOREIGN KEY (courseId) REFERENCES course (id) ON DELETE CASCADE
        )
      ''');
      
      // Step 3: Migrate data - convert single time to startTime, add default endTime
      for (final schedule in existingSchedules) {
        final timeValue = schedule['time'] as String;
        // Assume the time is start time and add 1 hour for end time
        final startTime = timeValue;
        String endTime;
        
        // Try to parse time and add 1 hour
        try {
          final parts = timeValue.split(':');
          if (parts.length >= 2) {
            int hour = int.parse(parts[0]);
            int minute = int.parse(parts[1]);
            hour = (hour + 1) % 24; // Add 1 hour, wrap around at 24
            endTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          } else {
            endTime = timeValue; // Fallback to same time
          }
        } catch (e) {
          endTime = timeValue; // Fallback to same time if parsing fails
        }
        
        await db.insert('schedule', {
          'id': schedule['id'],
          'courseId': schedule['courseId'],
          'dayOfWeek': schedule['dayOfWeek'],
          'startTime': startTime,
          'endTime': endTime,
          'room': schedule['room'],
        });
      }
      
      // Step 4: Create attendance tracking table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_attendance (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          scheduleId INTEGER NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('attended', 'skipped', 'cancelled')),
          createdAt TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (scheduleId) REFERENCES schedule (id) ON DELETE CASCADE,
          UNIQUE(scheduleId, date)
        )
      ''');
      
      print('Successfully migrated schedule table and added attendance tracking');
    } catch (e) {
      print('Error during migration: $e');
      rethrow;
    }
  }

  String _convertDayOfWeekToString(int dayOfWeek) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dayOfWeek >= 1 && dayOfWeek <= 7) {
      return days[dayOfWeek - 1];
    }
    return 'Monday'; // Default fallback
  }

  Future<void> _ensureTablesExist(Database db) async {
    try {
      // List of all required tables
      final requiredTables = ['profile', 'semester', 'course', 'attendance', 'schedule', 'score'];
      
      for (String tableName in requiredTables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
        );
        
        if (result.isEmpty) {
          print('Table $tableName missing');
          if (tableName == 'attendance' || tableName == 'schedule' || tableName == 'score') {
            // These are new tables, add them specifically
            await _addNewTables(db);
            break; // _addNewTables creates all new tables at once
          } else {
            // Core tables missing, create all tables
            await _createTables(db);
            await _addNewTables(db); // Ensure new tables are also created
            break;
          }
        }
      }
      
      // Also ensure attendanceThreshold column exists in course table
      try {
        await db.rawQuery('SELECT attendanceThreshold FROM course LIMIT 1');
      } catch (e) {
        // Column doesn't exist, add it
        try {
          await db.execute('ALTER TABLE course ADD COLUMN attendanceThreshold REAL DEFAULT 75.0');
          print('Added attendanceThreshold column to course table');
        } catch (alterError) {
          print('Error adding attendanceThreshold column: $alterError');
        }
      }
      
      print('All tables verified successfully');
    } catch (e) {
      print('Error checking/creating tables: $e');
      // Try to create all tables anyway
      try {
        await _createTables(db);
        await _addNewTables(db);
      } catch (createError) {
        print('Error in fallback table creation: $createError');
      }
    }
  }

  Future<Map<String, String>?> getProfileData() async {
    try {
      final database = await getDatabase();
      final result = await database.query(
        'profile',
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        final profileData = result.first;
        return {
          'username': profileData['username'] as String,
          'universityName': profileData['universityName'] as String,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting profile data: $e');
      return null;
    }
  }

  Future<bool> insertProfile({
    required String username,
    required String universityName,
  }) async {
    try {
      final database = await getDatabase();
      
      // First check if a profile already exists
      final existingProfile = await database.query('profile', limit: 1);
      if (existingProfile.isNotEmpty) {
        print('Profile already exists. Use updateProfile instead.');
        return false;
      }
      
      // Insert the new profile
      final result = await database.insert(
        'profile',
        {
          'username': username.trim(),
          'universityName': universityName.trim(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return result > 0;
    } catch (e) {
      print('Error inserting profile: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    required String username,
    required String universityName,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.update(
        'profile',
        {
          'username': username.trim(),
          'universityName': universityName.trim(),
        },
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> deleteProfile() async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete('profile');
      
      return result > 0;
    } catch (e) {
      print('Error deleting profile: $e');
      return false;
    }
  }

  // Semester-related methods
  Future<bool> insertSemester({
    required int semesterNumber,
    required List<Map<String, dynamic>> courses,
  }) async {
    try {
      final database = await getDatabase();
      
      // Calculate total credits
      double totalCredits = 0.0;
      for (var course in courses) {
        totalCredits += course['credits'] as double;
      }
      
      // Insert semester
      final semesterId = await database.insert(
        'semester',
        {
          'semesterNumber': semesterNumber,
          'totalCredits': totalCredits,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Insert courses
      for (var course in courses) {
        await database.insert(
          'course',
          {
            'semesterId': semesterId,
            'courseName': course['name'],
            'credits': course['credits'],
          },
        );
      }
      
      return true;
    } catch (e) {
      print('Error inserting semester: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLatestSemesterData() async {
    try {
      final database = await getDatabase();
      
      // Get the latest semester
      final semesterResult = await database.query(
        'semester',
        orderBy: 'createdAt DESC',
        limit: 1,
      );
      
      if (semesterResult.isEmpty) {
        return null;
      }
      
      final semester = semesterResult.first;
      final semesterId = semester['id'] as int;
      
      // Get courses for this semester
      final coursesResult = await database.query(
        'course',
        where: 'semesterId = ?',
        whereArgs: [semesterId],
      );
      
      return {
        'semester': semester,
        'courses': coursesResult,
      };
    } catch (e) {
      print('Error getting latest semester data: $e');
      return null;
    }
  }

  Future<bool> hasSemesterData() async {
    try {
      final database = await getDatabase();
      final result = await database.query('semester', limit: 1);
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking semester data: $e');
      return false;
    }
  }

  // Course-specific data methods
  Future<Map<String, dynamic>?> getCourseDetails(int courseId) async {
    try {
      final database = await getDatabase();
      
      // Get course info
      final courseResult = await database.query(
        'course',
        where: 'id = ?',
        whereArgs: [courseId],
      );
      
      if (courseResult.isEmpty) return null;
      
      final course = courseResult.first;
      
      // Get semester info for the course
      final semesterResult = await database.query(
        'semester',
        where: 'id = ?',
        whereArgs: [course['semesterId']],
      );
      
      final semester = semesterResult.isNotEmpty ? semesterResult.first : null;
      
      // Get attendance
      final attendanceResult = await database.query(
        'attendance',
        where: 'courseId = ?',
        whereArgs: [courseId],
        orderBy: 'updatedAt DESC',
        limit: 1,
      );
      
      // Get schedule
      final scheduleResult = await database.query(
        'schedule',
        where: 'courseId = ?',
        whereArgs: [courseId],
        orderBy: 'dayOfWeek ASC',
      );
      
      // Get scores
      final scoresResult = await database.query(
        'score',
        where: 'courseId = ?',
        whereArgs: [courseId],
        orderBy: 'createdAt DESC',
      );
      
      return {
        'course': course,
        'semester': semester,
        'attendance': attendanceResult.isNotEmpty ? attendanceResult.first : null,
        'schedule': scheduleResult,
        'scores': scoresResult,
      };
    } catch (e) {
      print('Error getting course details: $e');
      return null;
    }
  }

  Future<bool> updateAttendance(int courseId, int daysAttended, int totalDays) async {
    try {
      final database = await getDatabase();
      
      // Check if attendance record exists
      final existing = await database.query(
        'attendance',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      if (existing.isNotEmpty) {
        // Update existing record
        final result = await database.update(
          'attendance',
          {
            'daysAttended': daysAttended,
            'totalDays': totalDays,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'courseId = ?',
          whereArgs: [courseId],
        );
        return result > 0;
      } else {
        // Insert new record
        final result = await database.insert(
          'attendance',
          {
            'courseId': courseId,
            'daysAttended': daysAttended,
            'totalDays': totalDays,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
        return result > 0;
      }
    } catch (e) {
      print('Error updating attendance: $e');
      return false;
    }
  }

  Future<bool> addScore({
    required int courseId,
    required String title,
    required double gainedScore,
    required double totalScore,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.insert(
        'score',
        {
          'courseId': courseId,
          'title': title,
          'gainedScore': gainedScore,
          'totalScore': totalScore,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      return result > 0;
    } catch (e) {
      print('Error adding score: $e');
      return false;
    }
  }

  Future<bool> updateScore({
    required int scoreId,
    required String title,
    required double gainedScore,
    required double totalScore,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.update(
        'score',
        {
          'title': title,
          'gainedScore': gainedScore,
          'totalScore': totalScore,
        },
        where: 'id = ?',
        whereArgs: [scoreId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating score: $e');
      return false;
    }
  }

  Future<bool> deleteScore(int scoreId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete(
        'score',
        where: 'id = ?',
        whereArgs: [scoreId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error deleting score: $e');
      return false;
    }
  }

  Future<bool> addSchedule({
    required int courseId,
    required dynamic dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    try {
      final database = await getDatabase();
      
      // Convert dayOfWeek to string format for database
      String dayOfWeekString;
      if (dayOfWeek is int) {
        const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        dayOfWeekString = days[dayOfWeek % 7];
      } else {
        dayOfWeekString = dayOfWeek.toString();
      }

      final result = await database.insert(
        'schedule',
        {
          'courseId': courseId,
          'dayOfWeek': dayOfWeekString,
          'startTime': startTime,
          'endTime': endTime,
          'room': room,
        },
      );
      
      return result > 0;
    } catch (e) {
      print('Error adding schedule: $e');
      return false;
    }
  }

  Future<bool> updateCourse({
    required int courseId,
    required String courseName,
    required double credits,
    required double attendanceThreshold,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.update(
        'course',
        {
          'courseName': courseName.trim(),
          'credits': credits,
          'attendanceThreshold': attendanceThreshold,
        },
        where: 'id = ?',
        whereArgs: [courseId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  Future<bool> deleteAttendance(int courseId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete(
        'attendance',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error deleting attendance: $e');
      return false;
    }
  }

  Future<bool> deleteAllScores(int courseId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete(
        'score',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error deleting all scores: $e');
      return false;
    }
  }

  Future<bool> updateSchedule({
    required int scheduleId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.update(
        'schedule',
        {
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          'room': room,
        },
        where: 'id = ?',
        whereArgs: [scheduleId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating schedule: $e');
      return false;
    }
  }

  Future<bool> deleteSchedule(int courseId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete(
        'schedule',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error deleting schedule: $e');
      return false;
    }
  }

  Future<bool> deleteScheduleEntry(int scheduleId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.delete(
        'schedule',
        where: 'id = ?',
        whereArgs: [scheduleId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error deleting schedule entry: $e');
      return false;
    }
  }

  Future<bool> updateSemesterDates({
    required int semesterId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.update(
        'semester',
        {
          'startDate': startDate,
          'endDate': endDate,
        },
        where: 'id = ?',
        whereArgs: [semesterId],
      );
      
      return result > 0;
    } catch (e) {
      print('Error updating semester dates: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSemesters() async {
    try {
      final database = await getDatabase();
      
      final result = await database.query(
        'semester',
        orderBy: 'semesterNumber ASC',
      );
      
      return result;
    } catch (e) {
      print('Error getting all semesters: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final database = await getDatabase();
      
      final result = await database.query(
        'course',
        orderBy: 'courseName ASC',
      );
      
      return result;
    } catch (e) {
      print('Error getting all courses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getScheduleForCourse(int courseId) async {
    try {
      final database = await getDatabase();
      
      final result = await database.query(
        'schedule',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      return result;
    } catch (e) {
      print('Error getting schedule for course: $e');
      return [];
    }
  }

  Future<bool> addAttendanceRecord(int courseId, DateTime date, {required bool isPresent}) async {
    try {
      final database = await getDatabase();
      
      // Get current attendance data
      final attendanceResult = await database.query(
        'attendance',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );

      int daysAttended = 0;
      int totalDays = 1; // This new record

      if (attendanceResult.isNotEmpty) {
        final existing = attendanceResult.first;
        daysAttended = existing['daysAttended'] as int;
        totalDays = (existing['totalDays'] as int) + 1;
      }

      if (isPresent) {
        daysAttended += 1;
      }

      // Update attendance record
      if (attendanceResult.isNotEmpty) {
        await database.update(
          'attendance',
          {
            'daysAttended': daysAttended,
            'totalDays': totalDays,
            'updatedAt': date.toIso8601String(),
          },
          where: 'courseId = ?',
          whereArgs: [courseId],
        );
      } else {
        await database.insert(
          'attendance',
          {
            'courseId': courseId,
            'daysAttended': daysAttended,
            'totalDays': totalDays,
            'updatedAt': date.toIso8601String(),
          },
        );
      }

      return true;
    } catch (e) {
      print('Error adding attendance record: $e');
      return false;
    }
  }

  // Class attendance tracking methods
  Future<bool> markClassAttendance({
    required int scheduleId,
    required String date,
    required String status, // 'attended', 'skipped', 'cancelled'
  }) async {
    try {
      final database = await getDatabase();
      
      await database.rawQuery('''
        INSERT OR REPLACE INTO class_attendance 
        (scheduleId, date, status, createdAt) 
        VALUES (?, ?, ?, ?)
      ''', [scheduleId, date, status, DateTime.now().toIso8601String()]);
      
      return true;
    } catch (e) {
      print('Error marking class attendance: $e');
      return false;
    }
  }

  Future<String?> getClassAttendanceStatus({
    required int scheduleId,
    required String date,
  }) async {
    try {
      final database = await getDatabase();
      
      final result = await database.query(
        'class_attendance',
        where: 'scheduleId = ? AND date = ?',
        whereArgs: [scheduleId, date],
        limit: 1,
      );
      
      return result.isNotEmpty ? result.first['status'] as String : null;
    } catch (e) {
      print('Error getting class attendance status: $e');
      return null;
    }
  }

  Future<Map<String, int>> getAttendanceStats(int courseId) async {
    try {
      final database = await getDatabase();
      
      // Get all schedules for this course
      final schedules = await database.query(
        'schedule',
        where: 'courseId = ?',
        whereArgs: [courseId],
      );
      
      if (schedules.isEmpty) {
        return {'attended': 0, 'skipped': 0, 'cancelled': 0, 'total': 0};
      }
      
      final scheduleIds = schedules.map((s) => s['id']).toList();
      final placeholders = scheduleIds.map((_) => '?').join(',');
      
      // Get attendance stats
      final result = await database.rawQuery('''
        SELECT status, COUNT(*) as count
        FROM class_attendance 
        WHERE scheduleId IN ($placeholders)
        GROUP BY status
      ''', scheduleIds);
      
      int attended = 0, skipped = 0, cancelled = 0;
      
      for (final row in result) {
        final status = row['status'] as String;
        final count = row['count'] as int;
        
        switch (status) {
          case 'attended':
            attended = count;
            break;
          case 'skipped':
            skipped = count;
            break;
          case 'cancelled':
            cancelled = count;
            break;
        }
      }
      
      // Total classes = attended + skipped (cancelled doesn't count towards total)
      final total = attended + skipped;
      
      return {
        'attended': attended,
        'skipped': skipped,
        'cancelled': cancelled,
        'total': total,
      };
    } catch (e) {
      print('Error getting attendance stats: $e');
      return {'attended': 0, 'skipped': 0, 'cancelled': 0, 'total': 0};
    }
  }
}