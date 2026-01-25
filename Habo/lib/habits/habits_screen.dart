import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/notifications.dart';
import 'package:provider/provider.dart';
import 'package:habo/habits/calendar_column.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/settings/settings_manager.dart';
import 'package:habo/navigation/navigation.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class HabitsScreen extends StatefulWidget {
  static MaterialPage page() {
    return MaterialPage(
      name: Routes.habitsPath,
      key: ValueKey(Routes.habitsPath),
      child: const HabitsScreen(),
    );
  }

  const HabitsScreen({
    super.key,
  });

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  int _secretTapCount = 0;
  DateTime? _lastTapTime;
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _handleSecretLogoTap() async {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!).inMilliseconds > 1000) {
      _secretTapCount = 0;
    }
    _secretTapCount++;
    _lastTapTime = now;

    if (_secretTapCount == 3) {
      _secretTapCount = 0;
      bool authenticated = false;
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate =
            canAuthenticateWithBiometrics || await auth.isDeviceSupported();
            
        if (canAuthenticate) {
          authenticated = await auth.authenticate(
            localizedReason: 'Authenticate to access Secret Habits',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
        } else {
          // Fallback if no auth available (maybe just open it or show error?)
          // For now, let's assume if device supports it we use it, otherwise maybe just open?
          // Or better, show a dialog that secure lock is not set up.
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Device authentication not available')),
          );
          return;
        }
      } on PlatformException catch (e) {
        debugPrint("Error authenticating: $e");
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Authentication error: ${e.message}')),
          );
        return;
      }

      if (authenticated) {
        if (!mounted) return;
        Provider.of<AppStateManager>(context, listen: false).goSecretHabits(true);
      }
    }
  }
  @override
  void initState() {
    super.initState();
    if (platformSupportsNotifications()) {
      Future.delayed(const Duration(seconds: 0), () async {
        if (!mounted) return;
        showNotificationDialog(context);
      });
    }
  }

  void _showArchivedHabitsDialog(BuildContext context) {
    final habitsManager = Provider.of<HabitsManager>(context, listen: false);
    final archivedHabits = habitsManager.archivedHabits;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).archivedHabits),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: archivedHabits.isEmpty
                ? Center(
                    child: Text(
                      S.of(context).noArchivedHabits,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: archivedHabits.length,
                    itemBuilder: (context, index) {
                      final habit = archivedHabits[index];
                      return ListTile(
                        title: Text(habit.habitData.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.unarchive),
                          onPressed: () {
                            habitsManager.unarchiveHabit(habit.habitData.id!);
                            Navigator.of(context).pop();
                          },
                          tooltip: S.of(context).unarchiveHabit,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Provider.of<AppStateManager>(context, listen: false)
                              .goEditHabit(habit.habitData);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateManager>(
      builder: (
        context,
        appStateManager,
        child,
      ) {
        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _handleSecretLogoTap,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [HaboColors.primary, HaboColors.progress],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Mebo',
                  style: GoogleFonts.righteous(
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            actions: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.location_on,
                  semanticLabel: 'Location',
                ),
                color: Colors.amber,
                tooltip: 'Location',
                onPressed: () {
                  Provider.of<HabitsManager>(context, listen: false)
                      .hideSnackBar();
                  Provider.of<AppStateManager>(context, listen: false)
                      .goLocation(true);
                },
              ),


              IconButton(
                icon: Icon(
                  Icons.settings,
                  semanticLabel: S.of(context).settings,
                ),
                color: Colors.grey[400],
                tooltip: S.of(context).settings,
                onPressed: () {
                  Provider.of<AppStateManager>(context, listen: false)
                      .goSettings(true);
                  Provider.of<HabitsManager>(context, listen: false)
                      .hideSnackBar();
                },
              ),
            ],
          ),
          body: const CalendarColumn(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Provider.of<AppStateManager>(context, listen: false)
                  .goCreateHabit(true);
              Provider.of<HabitsManager>(context, listen: false).hideSnackBar();
            },
            child: Icon(
              Icons.add,
              color: Colors.white,
              semanticLabel: S.of(context).add,
              size: 35.0,
            ),
          ),
        );
      },
    );
  }

  void showNotificationDialog(BuildContext context) {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        if (!context.mounted) return;
        showRestoreDialog(context);
      } else {
        resetNotifications();
      }
    });
  }

  void showRestoreDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: S.of(context).notifications,
      desc: S.of(context).haboNeedsPermission,
      btnOkText: S.of(context).allow,
      btnCancelText: S.of(context).cancel,
      btnCancelColor: Colors.grey,
      btnOkColor: HaboColors.primary,
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        AwesomeNotifications()
            .requestPermissionToSendNotifications()
            .then((value) {
          resetNotifications();
        });
      },
    ).show();
  }

  void resetNotifications() {
    Provider.of<SettingsManager>(context, listen: false).resetAppNotification();
    Provider.of<HabitsManager>(context, listen: false)
        .resetHabitsNotifications();
  }
}
