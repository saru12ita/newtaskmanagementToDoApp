

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management_todo/Settings/Setting_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    // List of dynamic settings
    final List<Map<String, dynamic>> settingsOptions = [
      {
        "title": settings.isDarkMode ? "Switch to Bright Mode" : "Switch to Dark Mode",
        "icon": Icons.dark_mode,
        "type": "toggle",
        "value": settings.isDarkMode,
        "action": () => settings.toggleDarkMode(!settings.isDarkMode),
      },
      {
        "title": "Enable Notifications",
        "icon": Icons.notifications,
        "type": "toggle",
        "value": settings.isNotificationsEnabled,
        "action": () => settings.toggleNotifications(!settings.isNotificationsEnabled),
      },
      {
        "title": "Clear All Tasks",
        "icon": Icons.delete_forever,
        "type": "button",
        "action": () => settings.clearAllTasks(),
      },
      {
        "title": "Sync with Cloud",
        "icon": Icons.cloud_sync,
        "type": "toggle",
        "value": settings.isCloudSyncEnabled,
        "action": () => settings.toggleCloudSync(!settings.isCloudSyncEnabled),
      },
      {
        "title": "Language",
        "icon": Icons.language,
        "type": "dropdown",
        "value": settings.selectedLanguage,
        "options": ["English", "Spanish", "Nepali"],
        "action": (val) => settings.changeLanguage(val),
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          final option = settingsOptions[index];

          switch (option["type"]) {
            case "toggle":
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: Text(option["title"]),
                  secondary: Icon(option["icon"]),
                  value: option["value"],
                  onChanged: (_) => option["action"](),
                ),
              );
            case "button":
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(option["icon"]),
                  title: Text(option["title"]),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: option["action"],
                ),
              );
            case "dropdown":
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(option["icon"]),
                  title: Text(option["title"]),
                  trailing: DropdownButton<String>(
                    value: option["value"],
                    items: (option["options"] as List<String>)
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (val) => option["action"](val),
                  ),
                ),
              );
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
