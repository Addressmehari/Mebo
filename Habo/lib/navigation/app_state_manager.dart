import 'package:flutter/material.dart';
import 'package:habo/model/habit_data.dart';

class AppStateManager extends ChangeNotifier {
  bool _statistics = false;
  bool _settings = false;
  bool _onboarding = false;
  bool _whatsNew = false;
  bool _createHabit = false;
  HabitData? _editHabit;

  bool get getStatistics => _statistics;
  bool get getSettings => _settings;
  bool get getOnboarding => _onboarding;
  bool get getWhatsNew => _whatsNew;
  bool get getCreateHabit => _createHabit;
  HabitData? get getEditHabit => _editHabit;

  void goStatistics(bool state) {
    _statistics = state;
    notifyListeners();
  }

  void goSettings(bool state) {
    _settings = state;
    notifyListeners();
  }

  void goOnboarding(bool state) {
    _onboarding = state;
    notifyListeners();
  }

  void goWhatsNew(bool state) {
    _whatsNew = state;
    notifyListeners();
  }

  void goCreateHabit(bool state) {
    _createHabit = state;
    notifyListeners();
  }

  void goEditHabit(HabitData? habitData) {
    _editHabit = habitData;
    notifyListeners();
  }

  bool _location = false;
  bool get getLocation => _location;

  void goLocation(bool state) {
    _location = state;
    notifyListeners();
  }

  // The following static String declarations are typically found in a separate 'Routes' class.
  // As per the instruction to incorporate the change and ensure syntactic correctness,
  // and given the context of 'Update Routes class' in the instruction,
  // these lines are placed here as class-level constants within AppStateManager,
  // assuming they are intended to be accessible from this class or are part of a
  // broader refactoring not fully visible in the provided document.
  static const String locationPath = '/location';
  static const String secretHabitsPath = '/secretHabits';
  static const String vaultPath = '/vault';
  static const String folderPath = '/folder';

  bool _secretHabits = false;
  bool get getSecretHabits => _secretHabits;

  void goSecretHabits(bool state) {
    _secretHabits = state;
    notifyListeners();
  }

  bool _vault = false;
  bool get getVault => _vault;

  void goVault(bool state) {
    _vault = state;
    notifyListeners();
  }

  int? _vaultFolderId;
  int? get getVaultFolderId => _vaultFolderId;

  void goVaultFolder(int? folderId) {
    _vaultFolderId = folderId;
    notifyListeners();
  }
}
