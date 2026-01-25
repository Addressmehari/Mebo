import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habo/constants.dart';
import 'package:habo/generated/l10n.dart';
import 'package:habo/habits/calendar_column.dart';
import 'package:habo/habits/habits_manager.dart';
import 'package:habo/navigation/app_state_manager.dart';
import 'package:habo/navigation/routes.dart';
import 'package:provider/provider.dart';

class SecretHabitsScreen extends StatelessWidget {
  static MaterialPage page() {
    return MaterialPage(
      name: Routes.secretHabitsPath,
      key: ValueKey(Routes.secretHabitsPath),
      child: const SecretHabitsScreen(),
    );
  }

  const SecretHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background for secret mode
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber),
            const SizedBox(width: 10),
            Text(
              'Secret Habits',
              style: GoogleFonts.righteous(
                fontWeight: FontWeight.w700,
                fontSize: 24,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Provider.of<AppStateManager>(context, listen: false)
                .goSecretHabits(false);
          },
        ),
      ),
      body: const CalendarColumn(isSecret: true),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber[800],
        onPressed: () {
          // Temporarily set a flag somewhere or just goCreateHabit 
          // But wait, if we use standard create habit, how do we make it secret by default?
          // The user can toggle "Secret" in the edit screen.
          Provider.of<AppStateManager>(context, listen: false)
              .goCreateHabit(true);
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 35.0,
        ),
      ),
    );
  }
}
