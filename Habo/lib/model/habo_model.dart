import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:habo/constants.dart';
import 'package:habo/habits/habit.dart';
import 'package:habo/helpers.dart';
import 'package:habo/model/habit_data.dart';
import 'package:habo/model/category.dart' as habo_category;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class HaboModel {
  static const _dbVersion = 15;
  Database? _db;

  Database get db {
    if (_db == null) {
      throw StateError(
          'Database has not been initialized. Call initDatabase() first.');
    }
    return _db!;
  }

  Future<void> deleteEvent(int id, DateTime dateTime) async {
    try {
      await db.delete('events',
          where: 'id = ? AND dateTime = ?',
          whereArgs: [id, dateTime.toString()]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> deleteHabit(int id) async {
    try {
      await db.delete('habits', where: 'id = ?', whereArgs: [id]);
      await db.delete('events', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> emptyTables() async {
    try {
      await db.delete('habits');
      await db.delete('events');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> useBackup(List<Habit> habits) async {
    try {
      await emptyTables();
      for (var element in habits) {
        insertHabit(element);
        element.habitData.events.forEach(
          (key, value) {
            insertEvent(element.habitData.id!, key, value);
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> editHabit(Habit habit) async {
    try {
      await db.update(
        'habits',
        habit.toMap(),
        where: 'id = ?',
        whereArgs: [habit.habitData.id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<Habit?> getHabitById(int id) async {
    final List<Map<String, dynamic>> habits =
        await db.query('habits', where: 'id = $id', limit: 1);
    if (habits.isEmpty) return null;

    final hab = habits.first;
    SplayTreeMap<DateTime, List> eventsMap = SplayTreeMap<DateTime, List>();
    final events = await db.query('events', where: 'id = $id');
    for (var event in events) {
      final dayType = DayType.values[event['dayType'] as int];
      final comment = event['comment'];
      final progressValue = event['progressValue'] as double?;

      // Handle progress data for numeric, meter and savings habits
      if ((dayType == DayType.progress ||
              dayType == DayType.meter ||
              dayType == DayType.savings) &&
          progressValue != null) {
        eventsMap[DateTime.parse(event['dateTime'] as String)] = [
          dayType,
          comment,
          progressValue
        ];
      } else {
        eventsMap[DateTime.parse(event['dateTime'] as String)] = [
          dayType,
          comment
        ];
      }
    }

    // Load categories for this habit
    final categories = await getCategoriesForHabit(id);

    return Habit(
      habitData: HabitData(
        id: id,
        position: hab['position'],
        title: hab['title'],
        twoDayRule: hab['twoDayRule'] == 0 ? false : true,
        cue: hab['cue'] ?? '',
        routine: hab['routine'] ?? '',
        reward: hab['reward'] ?? '',
        showReward: hab['showReward'] == 0 ? false : true,
        advanced: hab['advanced'] == 0 ? false : true,
        notification: hab['notification'] == 0 ? false : true,
        notTime: parseTimeOfDay(hab['notTime']),
        events: eventsMap,
        sanction: hab['sanction'] ?? '',
        showSanction: (hab['showSanction'] ?? 0) == 0 ? false : true,
        accountant: hab['accountant'] ?? '',
        habitType: HabitType.values[hab['habitType'] ?? 0],
        targetValue: (hab['targetValue'] ?? 1.0).toDouble(),
        partialValue: (hab['partialValue'] ?? 1.0).toDouble(),
        unit: hab['unit'] ?? '',
        categories: categories,
        questions: (hab['questions'] != null &&
                hab['questions'].toString().isNotEmpty)
            ? List<String>.from(jsonDecode(hab['questions']))
            : [],
        meterMin: (hab['meterMin'] ?? 0.0).toDouble(),
        meterMax: (hab['meterMax'] ?? 10.0).toDouble(),
        meterLabels: (hab['meterLabels'] != null &&
                hab['meterLabels'].toString().isNotEmpty)
            ? List<String>.from(jsonDecode(hab['meterLabels']))
            : [],
        archived: hab['archived'] == 0 ? false : true,
        is24Hour: (hab['is24Hour'] ?? 0) == 0 ? false : true,
        createdAt:
            hab['createdAt'] != null && hab['createdAt'].toString().isNotEmpty
                ? DateTime.parse(hab['createdAt'])
                : DateTime.now(),
        color: hab['color'] ?? 0,
        reminders:
            (hab['reminders'] != null && hab['reminders'].toString().isNotEmpty)
                ? (jsonDecode(hab['reminders']) as List)
                    .map((e) => parseTimeOfDay(e))
                    .toList()
                : [],
        isSecret: (hab['isSecret'] ?? 0) == 0 ? false : true,
      ),
    );
  }

  Future<List<Habit>> getAllHabits() async {
    final List<Map<String, dynamic>> habits =
        await db.query('habits', orderBy: 'position');
    List<Habit> result = [];

    await Future.forEach(
      habits,
      (hab) async {
        int id = hab['id'];
        SplayTreeMap<DateTime, List> eventsMap = SplayTreeMap<DateTime, List>();
        final events = await db.query('events', where: 'id = $id');
        for (var event in events) {
          final dayType = DayType.values[event['dayType'] as int];
          final comment = event['comment'];
          final progressValue = event['progressValue'] as double?;

          // Handle progress data for numeric, meter and savings habits
          if ((dayType == DayType.progress || dayType == DayType.meter || dayType == DayType.savings) && progressValue != null) {
            eventsMap[DateTime.parse(event['dateTime'] as String)] = [
              dayType,
              comment,
              progressValue
            ];
          } else {
            eventsMap[DateTime.parse(event['dateTime'] as String)] = [
              dayType,
              comment
            ];
          }
        }

        // Load categories for this habit
        final categories = await getCategoriesForHabit(id);

        result.add(
          Habit(
            habitData: HabitData(
              id: id,
              position: hab['position'],
              title: hab['title'],
              twoDayRule: hab['twoDayRule'] == 0 ? false : true,
              cue: hab['cue'] ?? '',
              routine: hab['routine'] ?? '',
              reward: hab['reward'] ?? '',
              showReward: hab['showReward'] == 0 ? false : true,
              advanced: hab['advanced'] == 0 ? false : true,
              notification: hab['notification'] == 0 ? false : true,
              notTime: parseTimeOfDay(hab['notTime']),
              events: eventsMap,
              sanction: hab['sanction'] ?? '',
              showSanction: (hab['showSanction'] ?? 0) == 0 ? false : true,
              accountant: hab['accountant'] ?? '',
              habitType: HabitType.values[hab['habitType'] ?? 0],
              targetValue: (hab['targetValue'] ?? 1.0).toDouble(),
              partialValue: (hab['partialValue'] ?? 1.0).toDouble(),
              unit: hab['unit'] ?? '',
              categories: categories,
              questions: (hab['questions'] != null && hab['questions'].toString().isNotEmpty)
                  ? List<String>.from(jsonDecode(hab['questions']))
                  : [],
              meterMin: (hab['meterMin'] ?? 0.0).toDouble(),
              meterMax: (hab['meterMax'] ?? 10.0).toDouble(),
              meterLabels: (hab['meterLabels'] != null && hab['meterLabels'].toString().isNotEmpty)
                  ? List<String>.from(jsonDecode(hab['meterLabels']))
                  : [],
              archived: hab['archived'] == 0 ? false : true,
              is24Hour: (hab['is24Hour'] ?? 0) == 0 ? false : true,
              createdAt: hab['createdAt'] != null && hab['createdAt'].toString().isNotEmpty
                  ? DateTime.parse(hab['createdAt'])
                  : DateTime.now(),
              color: hab['color'] ?? 0,
              reminders: (hab['reminders'] != null && hab['reminders'].toString().isNotEmpty)
                  ? (jsonDecode(hab['reminders']) as List).map((e) => parseTimeOfDay(e)).toList()
                  : [],
              isSecret: (hab['isSecret'] ?? 0) == 0 ? false : true,
            ),
          ),
        );
      },
    );
    return result;
  }

  void _updateTableEventsV1toV2(Batch batch) {
    batch.execute('ALTER TABLE Events ADD comment TEXT DEFAULT ""');
  }

  void _updateTableHabitsV2toV3(Batch batch) {
    batch.execute('ALTER TABLE habits ADD sanction TEXT DEFAULT "" NOT NULL');
    batch.execute(
        'ALTER TABLE habits ADD showSanction INTEGER DEFAULT 0 NOT NULL');
    batch.execute('ALTER TABLE habits ADD accountant TEXT DEFAULT "" NOT NULL');
  }

  void _updateTableHabitsV3toV4(Batch batch) {
    batch
        .execute('ALTER TABLE habits ADD habitType INTEGER DEFAULT 0 NOT NULL');
    batch.execute(
        'ALTER TABLE habits ADD targetValue REAL DEFAULT 1.0 NOT NULL');
    batch.execute(
        'ALTER TABLE habits ADD partialValue REAL DEFAULT 1.0 NOT NULL');
    batch.execute('ALTER TABLE habits ADD unit TEXT DEFAULT "" NOT NULL');
  }

  void _updateTableEventsV3toV4(Batch batch) {
    batch.execute('ALTER TABLE events ADD progressValue REAL DEFAULT 0.0');
  }

  // void _createTableEventsV3(Batch batch) {
  //   batch.execute('DROP TABLE IF EXISTS events');
  //   batch.execute('''CREATE TABLE events (
  //   id INTEGER,
  //   dateTime TEXT,
  //   dayType INTEGER,
  //   comment TEXT,
  //   PRIMARY KEY(id, dateTime),
  //   FOREIGN KEY (id) REFERENCES habits(id) ON DELETE CASCADE
  //   )''');
  // }

  void _createTableEventsV4(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS events');
    batch.execute('''CREATE TABLE events (
    id INTEGER,
    dateTime TEXT,
    dayType INTEGER,
    comment TEXT,
    progressValue REAL DEFAULT 0.0,
    PRIMARY KEY(id, dateTime),
    FOREIGN KEY (id) REFERENCES habits(id) ON DELETE CASCADE
    )''');
  }

  // void _createTableHabitsV3(Batch batch) {
  //   batch.execute('DROP TABLE IF EXISTS habits');
  //   batch.execute('''CREATE TABLE habits (
  //   id INTEGER PRIMARY KEY AUTOINCREMENT,
  //   position INTEGER,
  //   title TEXT,
  //   twoDayRule INTEGER,
  //   cue TEXT,
  //   routine TEXT,
  //   reward TEXT,
  //   showReward INTEGER,
  //   advanced INTEGER,
  //   notification INTEGER,
  //   notTime TEXT,
  //   sanction TEXT,
  //   showSanction INTEGER,
  //   accountant TEXT
  //   )''');
  // }

  void _createTableHabitsV6(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS habits');
    batch.execute('''CREATE TABLE habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER,
    title TEXT,
    twoDayRule INTEGER,
    cue TEXT,
    routine TEXT,
    reward TEXT,
    showReward INTEGER,
    advanced INTEGER,
    notification INTEGER,
    notTime TEXT,
    sanction TEXT,
    showSanction INTEGER,
    accountant TEXT,
    habitType INTEGER DEFAULT 0,
    targetValue REAL DEFAULT 1.0,
    partialValue REAL DEFAULT 1.0,
    unit TEXT DEFAULT '',
    archived INTEGER DEFAULT 0
    )''');
  }

  void _updateTableHabitsV5toV6(Batch batch) {
    batch.execute('ALTER TABLE habits ADD COLUMN archived INTEGER DEFAULT 0');
  }

  void _createTableHabitsV10(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS habits');
    batch.execute('''CREATE TABLE habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER,
    title TEXT,
    twoDayRule INTEGER,
    cue TEXT,
    routine TEXT,
    reward TEXT,
    showReward INTEGER,
    advanced INTEGER,
    notification INTEGER,
    notTime TEXT,
    sanction TEXT,
    showSanction INTEGER,
    accountant TEXT,
    habitType INTEGER DEFAULT 0,
    targetValue REAL DEFAULT 1.0,
    partialValue REAL DEFAULT 1.0,
    unit TEXT DEFAULT '',
    archived INTEGER DEFAULT 0,
    questions TEXT DEFAULT '',
    meterMin REAL DEFAULT 0.0,
    meterMax REAL DEFAULT 10.0,
    meterLabels TEXT DEFAULT ''
    )''');
  }

  Future<void> _updateTableHabitsAddMeterFields(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasMeterMin = result.any((column) => column['name'] == 'meterMin');
      final hasMeterMax = result.any((column) => column['name'] == 'meterMax');
      final hasMeterLabels = result.any((column) => column['name'] == 'meterLabels');
      
      if (!hasMeterMin) {
        await db.execute("ALTER TABLE habits ADD COLUMN meterMin REAL DEFAULT 0.0");
      }
      if (!hasMeterMax) {
        await db.execute("ALTER TABLE habits ADD COLUMN meterMax REAL DEFAULT 10.0");
      }
      if (!hasMeterLabels) {
        await db.execute("ALTER TABLE habits ADD COLUMN meterLabels TEXT DEFAULT ''");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding meter columns: $e');
      }
    }
  }

  void _createTableHabitsV13(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS habits');
    batch.execute('''CREATE TABLE habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER,
    title TEXT,
    twoDayRule INTEGER,
    cue TEXT,
    routine TEXT,
    reward TEXT,
    showReward INTEGER,
    advanced INTEGER,
    notification INTEGER,
    notTime TEXT,
    sanction TEXT,
    showSanction INTEGER,
    accountant TEXT,
    habitType INTEGER DEFAULT 0,
    targetValue REAL DEFAULT 1.0,
    partialValue REAL DEFAULT 1.0,
    unit TEXT DEFAULT '',
    archived INTEGER DEFAULT 0,
    questions TEXT DEFAULT '',
    meterMin REAL DEFAULT 0.0,
    meterMax REAL DEFAULT 10.0,
    meterLabels TEXT DEFAULT '',
    is24Hour INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT '',
    color INTEGER DEFAULT 0,
    reminders TEXT DEFAULT ''
    )''');
  }

  void _createTableHabitsV14(Batch batch) {
    batch.execute('DROP TABLE IF EXISTS habits');
    batch.execute('''CREATE TABLE habits (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    position INTEGER,
    title TEXT,
    twoDayRule INTEGER,
    cue TEXT,
    routine TEXT,
    reward TEXT,
    showReward INTEGER,
    advanced INTEGER,
    notification INTEGER,
    notTime TEXT,
    sanction TEXT,
    showSanction INTEGER,
    accountant TEXT,
    habitType INTEGER DEFAULT 0,
    targetValue REAL DEFAULT 1.0,
    partialValue REAL DEFAULT 1.0,
    unit TEXT DEFAULT '',
    archived INTEGER DEFAULT 0,
    questions TEXT DEFAULT '',
    meterMin REAL DEFAULT 0.0,
    meterMax REAL DEFAULT 10.0,
    meterLabels TEXT DEFAULT '',
    is24Hour INTEGER DEFAULT 0,
    createdAt TEXT DEFAULT '',
    color INTEGER DEFAULT 0,
    reminders TEXT DEFAULT '',
    isSecret INTEGER DEFAULT 0
    )''');
  }

  Future<void> _updateTableHabitsAddReminders(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasColumn = result.any((column) => column['name'] == 'reminders');
      if (!hasColumn) {
        await db.execute("ALTER TABLE habits ADD COLUMN reminders TEXT DEFAULT ''");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding reminders column: $e');
      }
    }
  }

  Future<void> _updateTableHabitsAdd24HourFields(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasIs24Hour = result.any((column) => column['name'] == 'is24Hour');
      final hasCreatedAt = result.any((column) => column['name'] == 'createdAt');
      
      if (!hasIs24Hour) {
        await db.execute("ALTER TABLE habits ADD COLUMN is24Hour INTEGER DEFAULT 0");
      }
      if (!hasCreatedAt) {
        await db.execute("ALTER TABLE habits ADD COLUMN createdAt TEXT DEFAULT ''");
        // Set current time for existing habits
        await db.execute("UPDATE habits SET createdAt = '${DateTime.now().toIso8601String()}' WHERE createdAt = ''");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding 24-hour columns: $e');
      }
    }
  }

  Future<void> _updateTableHabitsAddColor(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasColor = result.any((column) => column['name'] == 'color');
      
      if (!hasColor) {
        await db.execute("ALTER TABLE habits ADD COLUMN color INTEGER DEFAULT 0");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding color column: $e');
      }
    }
  }

  Future<void> _updateTableHabitsAddIsSecret(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasColumn = result.any((column) => column['name'] == 'isSecret');
      
      if (!hasColumn) {
        await db.execute("ALTER TABLE habits ADD COLUMN isSecret INTEGER DEFAULT 0");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding isSecret column: $e');
      }
    }
  }


  Future<void> _updateTableCategoriesAddFontFamily(Database db) async {
    // Check if fontFamily column already exists before adding it
    final result = await db.rawQuery("PRAGMA table_info(categories)");
    final hasColumn = result.any((column) => column['name'] == 'fontFamily');

    if (!hasColumn) {
      await db.execute('ALTER TABLE categories ADD COLUMN fontFamily TEXT');
    }
  }

  void _createTableCategoriesV5(Batch batch) {
    batch.execute('''CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    iconCodePoint INTEGER NOT NULL
    )''');
  }

  void _createTableCategoriesV7(Batch batch) {
    batch.execute('''CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    iconCodePoint INTEGER NOT NULL,
    fontFamily TEXT
    )''');
  }

  void _createTableHabitCategoriesV5(Batch batch) {
    batch.execute('''CREATE TABLE IF NOT EXISTS habit_categories (
    habit_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    PRIMARY KEY (habit_id, category_id),
    FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
    )''');
  }

  Future onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> initDatabase() async {
    final databasesPath = (Platform.isLinux || Platform.isWindows)
        ? (await getApplicationSupportDirectory()).path
        : await getDatabasesPath();

    if (kDebugMode) {
      print(databasesPath);
    }

    final databaseFilePath = join(databasesPath, 'habo_db0.db');

    if (Platform.isLinux || Platform.isWindows) {
      ffi.sqfliteFfiInit();
      _db = await ffi.databaseFactoryFfi.openDatabase(databaseFilePath,
          options: OpenDatabaseOptions(
            version: _dbVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          ));
    } else {
      _db = await openDatabase(
        databaseFilePath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  void _onCreate(Database db, int version) {
    var batch = db.batch();
    _createTableHabitsV14(batch);
    _createTableEventsV4(batch);
    _createTableCategoriesV7(batch); // Use V7 with fontFamily column
    _createTableHabitCategoriesV5(batch);
    _createTableVaultFoldersV15(batch);
    _createTableVaultFilesV15(batch);
    batch.commit();
  }

  void _createTableVaultFoldersV15(Batch batch) {
    batch.execute('''CREATE TABLE IF NOT EXISTS vault_folders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    iconCode INTEGER
    )''');
  }

  void _createTableVaultFilesV15(Batch batch) {
    batch.execute('''CREATE TABLE IF NOT EXISTS vault_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    folder_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    localPath TEXT NOT NULL,
    fileType TEXT NOT NULL,
    sizeInBytes INTEGER NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (folder_id) REFERENCES vault_folders(id) ON DELETE CASCADE
    )''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    var batch = db.batch();
    if (oldVersion == 1) {
      _updateTableEventsV1toV2(batch);
      _updateTableHabitsV2toV3(batch);
      _updateTableHabitsV3toV4(batch);
      _updateTableEventsV3toV4(batch);
      _createTableCategoriesV5(batch);
      _createTableHabitCategoriesV5(batch);
      _updateTableHabitsV5toV6(batch);
    }
    if (oldVersion == 2) {
      _updateTableHabitsV2toV3(batch);
      _updateTableHabitsV3toV4(batch);
      _updateTableEventsV3toV4(batch);
      _createTableCategoriesV5(batch);
      _createTableHabitCategoriesV5(batch);
      _updateTableHabitsV5toV6(batch);
    }
    if (oldVersion == 3) {
      _updateTableHabitsV3toV4(batch);
      _updateTableEventsV3toV4(batch);
      _createTableCategoriesV5(batch);
      _createTableHabitCategoriesV5(batch);
      _updateTableHabitsV5toV6(batch);
    }
    if (oldVersion == 4) {
      _createTableCategoriesV5(batch);
      _createTableHabitCategoriesV5(batch);
      _updateTableHabitsV5toV6(batch);
    }
    if (oldVersion == 5) {
      _updateTableHabitsV5toV6(batch);
    }

    // Commit batch operations first
    await batch.commit();

    // Then handle column additions separately (requires async check)
    if (oldVersion <= 7) {
      await _updateTableCategoriesAddFontFamily(db);
    }
    
    // Handle questions column addition safely
    if (oldVersion < 9) {
      await _updateTableHabitsAddQuestions(db);
    }
    
    // Handle meter columns addition safely
    if (oldVersion < 10) {
      await _updateTableHabitsAddMeterFields(db);
    }
    
    // Handle 24-hour task columns addition
    if (oldVersion < 11) {
      await _updateTableHabitsAdd24HourFields(db);
    }
    
    // Handle color column addition
    if (oldVersion < 12) {
      await _updateTableHabitsAddColor(db);
    }
    
    // Handle multiple reminders
    if (oldVersion < 13) {
      await _updateTableHabitsAddReminders(db);
    }
    
    // Handle isSecret field
    if (oldVersion < 14) {
      await _updateTableHabitsAddIsSecret(db);
    }

    // Handle vault tables addition (v15)
    if (oldVersion < 15) {
      var vaultBatch = db.batch();
      _createTableVaultFoldersV15(vaultBatch);
      _createTableVaultFilesV15(vaultBatch);
      await vaultBatch.commit();
    }
  }

  Future<void> _updateTableHabitsAddQuestions(Database db) async {
    try {
      final result = await db.rawQuery("PRAGMA table_info(habits)");
      final hasColumn = result.any((column) => column['name'] == 'questions');
      if (!hasColumn) {
        await db.execute("ALTER TABLE habits ADD COLUMN questions TEXT DEFAULT ''");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding questions column: $e');
      }
    }
  }

  Future<void> insertEvent(int id, DateTime date, List event) async {
    try {
      final eventData = {
        'id': id,
        'dateTime': date.toString(),
        'dayType': event[0].index,
        'comment': event[1],
      };

      // Add progress value for numeric, meter and savings habits
      if (event.length > 2 && (event[0] == DayType.progress || event[0] == DayType.meter || event[0] == DayType.savings)) {
        eventData['progressValue'] = event[2] as double;
      } else {
        eventData['progressValue'] = 0.0;
      }

      db.insert('events', eventData,
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<int> insertHabit(Habit habit) async {
    try {
      var id = await db.insert('habits', habit.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
    return 0;
  }

  Future<void> updateOrder(List<Habit> habits) async {
    try {
      for (var habit in habits) {
        db.update(
          'habits',
          habit.toMap(),
          where: 'id = ?',
          whereArgs: [habit.habitData.id],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  // Category management methods
  Future<int> insertCategory(habo_category.Category category) async {
    try {
      var id = await db.insert('categories', category.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      return id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
    return 0;
  }

  Future<void> updateCategory(habo_category.Category category) async {
    try {
      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<int> insertVaultFolder(Map<String, dynamic> folder) async {
    return await db.insert('vault_folders', folder);
  }

  Future<void> deleteVaultFolder(int id) async {
    await db.delete('vault_folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllVaultFolders() async {
    return await db.query('vault_folders', orderBy: 'name');
  }

  Future<int> insertVaultFile(Map<String, dynamic> file) async {
    return await db.insert('vault_files', file);
  }

  Future<void> deleteVaultFile(int id) async {
    await db.delete('vault_files', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getVaultFilesForFolder(int folderId) async {
    return await db.query('vault_files',
        where: 'folder_id = ?', whereArgs: [folderId], orderBy: 'createdAt DESC');
  }

  Future<void> deleteCategory(int id) async {
    try {
      // Delete category-habit associations first
      await db.delete('habit_categories',
          where: 'category_id = ?', whereArgs: [id]);
      // Then delete the category itself
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<List<habo_category.Category>> getAllCategories() async {
    try {
      final List<Map<String, dynamic>> categories =
          await db.query('categories', orderBy: 'title');
      return categories
          .map((cat) => habo_category.Category.fromMap(cat))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
    return [];
  }

  // Habit-Category relationship methods
  Future<void> addHabitToCategory(int habitId, int categoryId) async {
    try {
      await db.insert(
          'habit_categories',
          {
            'habit_id': habitId,
            'category_id': categoryId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<void> removeHabitFromCategory(int habitId, int categoryId) async {
    try {
      await db.delete('habit_categories',
          where: 'habit_id = ? AND category_id = ?',
          whereArgs: [habitId, categoryId]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }

  Future<List<habo_category.Category>> getCategoriesForHabit(
      int habitId) async {
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT c.* FROM categories c
        INNER JOIN habit_categories hc ON c.id = hc.category_id
        WHERE hc.habit_id = ?
        ORDER BY c.title
      ''', [habitId]);
      return result.map((cat) => habo_category.Category.fromMap(cat)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
    return [];
  }

  Future<void> updateHabitCategories(
      int habitId, List<habo_category.Category> categories) async {
    try {
      // Remove all existing category associations for this habit
      await db.delete('habit_categories',
          where: 'habit_id = ?', whereArgs: [habitId]);

      // Add new category associations
      for (var category in categories) {
        if (category.id != null) {
          await addHabitToCategory(habitId, category.id!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(e.toString());
      }
    }
  }
}
