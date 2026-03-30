import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  List<dynamic> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);
    final response = await ApiService.get(Constants.myDoctors);
    if (response['success'] == true) {
      setState(() {
        _permissions = response['permissions'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _revokeAccess(String permissionId, String doctorName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text('Are you sure you want to revoke access for $doctorName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await ApiService.put(
        '${Constants.permissions}/revoke/$permissionId',
        {},
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access revoked successfully'),
            backgroundColor: Color(0xFF0F6E56),
          ),
        );
        _loadPermissions();
      }
    }
  }

  Future<void> _showGrantDialog() async {
    final emailController = TextEditingController();
    String selectedScope = 'all';
    String selectedCategory = 'lab_report';
    Map<String, dynamic>? foundDoctor;
    bool isSearching = false;
    String searchError = '';

    final List<Map<String, String>> categories = [
      {'value': 'lab_report', 'label': 'Lab Report'},
      {'value': 'prescription', 'label': 'Prescription'},
      {'value': 'radiology', 'label': 'Radiology'},
      {'value': 'discharge_summary', 'label': 'Discharge Summary'},
      {'value': 'other', 'label': 'Other'},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Grant Doctor Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Doctor email address',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Enter doctor\'s email',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isSearching
                        ? null
                        : () async {
                            if (emailController.text.trim().isEmpty) return;
                            setModalState(() {
                              isSearching = true;
                              searchError = '';
                              foundDoctor = null;
                            });
                            final response = await ApiService.get(
                              '${Constants.searchDoctor}?email=${emailController.text.trim()}',
                            );
                            setModalState(() {
                              isSearching = false;
                              if (response['success'] == true) {
                                foundDoctor = response['doctor'];
                              } else {
                                searchError = response['message'] ?? 'Doctor not found';
                              }
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                  ),
                ],
              ),
              if (searchError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  searchError,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (foundDoctor != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F6E56).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0F6E56).withAlpha(50),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF0F6E56),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundDoctor!['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (foundDoctor!['specialization'] != null &&
                                foundDoctor!['specialization'].isNotEmpty)
                              Text(
                                foundDoctor!['specialization'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            if (foundDoctor!['organisation_name'] != null &&
                                foundDoctor!['organisation_name'].isNotEmpty)
                              Text(
                                foundDoctor!['organisation_name'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Access Scope',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('All records'),
                        subtitle: const Text('Doctor can see all your records'),
                        leading: Radio<String>(
                          value: 'all',
                          groupValue: selectedScope,
                          activeColor: const Color(0xFF0F6E56),
                          onChanged: (value) =>
                              setModalState(() => selectedScope = value!),
                        ),
                        onTap: () =>
                            setModalState(() => selectedScope = 'all'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('By category'),
                        subtitle: const Text('Doctor can only see a specific category'),
                        leading: Radio<String>(
                          value: 'category',
                          groupValue: selectedScope,
                          activeColor: const Color(0xFF0F6E56),
                          onChanged: (value) =>
                              setModalState(() => selectedScope = value!),
                        ),
                        onTap: () =>
                            setModalState(() => selectedScope = 'category'),
                      ),
                    ],
                  ),
                ),
                if (selectedScope == 'category') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Select category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['value'],
                        child: Text(cat['label']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => selectedCategory = value);
                      }
                    },
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final body = {
                      'provider_user_id': foundDoctor!['user_id'],
                      'scope_type': selectedScope,
                      if (selectedScope == 'category')
                        'shared_category': selectedCategory,
                    };

                    final response = await ApiService.post(
                      Constants.grantPermission,
                      body,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (response['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Access granted successfully'),
                          backgroundColor: Color(0xFF0F6E56),
                        ),
                      );
                      _loadPermissions();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response['message'] ?? 'Failed to grant access',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Grant Access'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Access'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _permissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No doctors have access yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to grant a doctor access',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPermissions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _permissions.length,
                    itemBuilder: (context, index) {
                      final permission = _permissions[index];
                      final provider = permission['provider_id'];
                      final user = provider?['user_id'];
                      final doctorName = user != null
                          ? '${user['first_name']} ${user['last_name']}'
                          : 'Unknown Doctor';
                      final email = user?['email'] ?? '';
                      final scope = permission['scope_type'] ?? 'all';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F6E56).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medical_services,
                              color: Color(0xFF0F6E56),
                            ),
                          ),
                          title: Text(
                            doctorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(email),
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F6E56).withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scope == 'all'
                                      ? 'Full access'
                                      : scope == 'category'
                                          ? 'Category: ${permission['shared_category'] ?? ''}'
                                          : 'Specific record',
                                  style: const TextStyle(
                                    color: Color(0xFF0F6E56),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _revokeAccess(
                              permission['_id'],
                              doctorName,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGrantDialog,
        backgroundColor: const Color(0xFF0F6E56),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}