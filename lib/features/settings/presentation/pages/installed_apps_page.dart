import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../data/models/system_models.dart';

class InstalledAppsPage extends StatefulWidget {
  const InstalledAppsPage({super.key});

  @override
  State<InstalledAppsPage> createState() => _InstalledAppsPageState();
}

class _InstalledAppsPageState extends State<InstalledAppsPage> {
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    List<SystemApplication> applications = settingsProvider.applications; 

    if (_searchQuery.isNotEmpty) {
      applications = applications
          .where((app) => app.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    applications.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        case 'type':
          return a.type.compareTo(b.type);
        case 'size':
          return a.size.compareTo(b.size);
        default:
          return a.name.compareTo(b.name);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              settingsProvider.refreshSystemData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search applications...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Found ${applications.length} applications',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                return _AppListItem(app: app);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Name'),
              leading: const Icon(Icons.sort_by_alpha),
              onTap: () {
                setState(() {
                  _sortBy = 'name';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Type'),
              leading: const Icon(Icons.category),
              onTap: () {
                setState(() {
                  _sortBy = 'type';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Size'),
              leading: const Icon(Icons.storage),
              onTap: () {
                setState(() {
                  _sortBy = 'size';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppListItem extends StatelessWidget {
  final SystemApplication app;

  const _AppListItem({required this.app});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getAppColor(app.type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getAppIcon(app.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(app.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.path),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    app.type.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(app.size / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showAppDetails(context, app),
        ),
      ),
    );
  }

  Color _getAppColor(String type) {
    switch (type) {
      case 'system':
        return Colors.orange;
      case 'binary':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getAppIcon(String type) {
    switch (type) {
      case 'system':
        return Icons.settings;
      case 'binary':
        return Icons.apps;
      default:
        return Icons.question_mark;
    }
  }

  void _showAppDetails(BuildContext context, SystemApplication app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(app.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Path: ${app.path}'),
            Text('Type: ${app.type}'),
            Text('Size: ${(app.size / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
