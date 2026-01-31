import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:data/web_providers.dart';
import '../../providers/user_role_provider.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final token = await authRepo.getToken();
      
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Use the dioProvider which has correct baseUrl
      final dio = ref.read(dioProvider);

      final response = await dio.get(
        '/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      setState(() {
        _users = response.data;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 403) {
          _error = 'ACCESS_DENIED';
        } else {
          _error = e.message ?? 'Failed to load users';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(currentUserRoleProvider);

    // Show access denied for operators
    if (userRole == 'operator') {
      return _buildAccessDenied();
    }

    if (_error == 'ACCESS_DENIED') {
      return _buildAccessDenied();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchUsers();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buildUsersList(),
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Not Allowed',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You do not have permission to view this section.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Text(
              'Contact your administrator for access.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Team Members',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_users.length} members',
                  style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateColor.resolveWith(
                      (states) => Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Role', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Created At', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: _users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _getRoleColor(user['role']).withOpacity(0.2),
                                  child: Text(
                                    (user['username'] as String? ?? 'U')[0].toUpperCase(),
                                    style: TextStyle(
                                      color: _getRoleColor(user['role']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(user['username'] ?? 'Unknown'),
                              ],
                            ),
                          ),
                          DataCell(_RoleBadge(role: user['role'] ?? 'unknown')),
                          DataCell(Text(_formatDate(user['createdAt']))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'manager':
        return Colors.blue;
      case 'operator':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.purple;
        icon = Icons.admin_panel_settings;
        break;
      case 'manager':
        color = Colors.blue;
        icon = Icons.manage_accounts;
        break;
      case 'operator':
        color = Colors.green;
        icon = Icons.person;
        break;
      default:
        color = Colors.grey;
        icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
