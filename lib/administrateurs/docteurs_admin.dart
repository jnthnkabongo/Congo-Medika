import 'package:flutter/material.dart';
import '../services/doctors_service.dart';
import '../theme/app_theme.dart';

/// Gestion CRUD des médecins (espace administrateur).
class DocteursAdmin extends StatefulWidget {
  const DocteursAdmin({super.key});

  @override
  State<DocteursAdmin> createState() => _DocteursAdminState();
}

class _DocteursAdminState extends State<DocteursAdmin> {
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _specialties = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DoctorsService.getAllDoctors(),
        DoctorsService.getSpecialties(),
      ]);
      if (mounted) {
        setState(() {
          _doctors = results[0];
          _specialties = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredDoctors {
    if (_searchQuery.isEmpty) return _doctors;
    final q = _searchQuery.toLowerCase();
    return _doctors.where((d) {
      final name =
          '${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.toLowerCase();
      final email = (d['email'] ?? '').toString().toLowerCase();
      final specialty = (d['specialty'] ?? '').toString().toLowerCase();
      final license = (d['licenseNumber'] ?? '').toString().toLowerCase();
      final status = _statusLabel(d['status']).toLowerCase();
      return name.contains(q) ||
          email.contains(q) ||
          specialty.contains(q) ||
          license.contains(q) ||
          status.contains(q);
    }).toList();
  }

  String _statusLabel(dynamic status) {
    switch (status?.toString()) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'pending':
        return 'En attente';
      case 'blocked':
        return 'Bloqué';
      default:
        return status?.toString() ?? 'Inconnu';
    }
  }

  Color _statusColor(dynamic status) {
    switch (status?.toString()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showDoctorForm([Map<String, dynamic>? doctor]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => DoctorFormSheet(
          doctor: doctor,
          specialties: _specialties,
          scrollController: scrollController,
          onSaved: _loadData,
        ),
      ),
    );
  }

  Future<void> _deleteDoctor(Map<String, dynamic> doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le médecin'),
        content: Text(
          'Supprimer Dr. ${doctor['firstName']} ${doctor['lastName']} ?\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await DoctorsService.deleteDoctor(doctor['id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Médecin supprimé')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: AppTheme.adaptiveToolbarHeight(context),
        backgroundColor: const Color(0xFFF1EFF1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8D3188)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Docteurs',
          style: TextStyle(
            color: Color(0xFF8D3188),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médecin...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF8D3188),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Liste
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredDoctors.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Icon(
                                Icons.medical_services_outlined,
                                size: 56,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'Aucun médecin enregistré'
                                      : 'Aucun médecin trouvé',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredDoctors.length,
                            itemBuilder: (context, index) {
                              final doctor = _filteredDoctors[index];
                              return _buildDoctorCard(doctor);
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDoctorForm(),
        backgroundColor: const Color(0xFF8D3188),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final statusColor = _statusColor(doctor['status']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF8D3188).withValues(alpha: 0.1),
              child: Text(
                '${doctor['firstName']?[0] ?? ''}${doctor['lastName']?[0] ?? ''}',
                style: const TextStyle(
                  color: Color(0xFF8D3188),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${doctor['firstName']} ${doctor['lastName']}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    doctor['specialty'] ?? 'Spécialité non définie',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          doctor['email'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(doctor['status']),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showDoctorForm(doctor);
                        break;
                      case 'delete':
                        _deleteDoctor(doctor);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire création/édition d'un médecin (bottom sheet).
class DoctorFormSheet extends StatefulWidget {
  final Map<String, dynamic>? doctor;
  final List<Map<String, dynamic>> specialties;
  final ScrollController scrollController;
  final VoidCallback onSaved;

  const DoctorFormSheet({
    super.key,
    required this.doctor,
    required this.specialties,
    required this.scrollController,
    required this.onSaved,
  });

  @override
  State<DoctorFormSheet> createState() => _DoctorFormSheetState();
}

class _DoctorFormSheetState extends State<DoctorFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _licenseController;
  late final TextEditingController _feeController;
  late final TextEditingController _bioController;
  late final TextEditingController _passwordController;

  String? _selectedSpecialtyId;
  String _selectedStatus = 'active';
  bool _isSaving = false;

  bool get _isEdit => widget.doctor != null;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _firstNameController = TextEditingController(
      text: d?['firstName']?.toString() ?? '',
    );
    _lastNameController = TextEditingController(
      text: d?['lastName']?.toString() ?? '',
    );
    _emailController = TextEditingController(
      text: d?['email']?.toString() ?? '',
    );
    _phoneController = TextEditingController(
      text: d?['phone']?.toString() ?? '',
    );
    _licenseController = TextEditingController(
      text: d?['licenseNumber']?.toString() ?? '',
    );
    _feeController = TextEditingController(
      text: d?['consultationFee']?.toString() ?? '',
    );
    _bioController = TextEditingController(text: d?['bio']?.toString() ?? '');
    _passwordController = TextEditingController();
    _selectedSpecialtyId = d?['specialtyId']?.toString();
    _selectedStatus = d?['status']?.toString() ?? 'active';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une spécialité')),
      );
      return;
    }
    if (!_isEdit && _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit contenir au moins 6 caractères'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'specialtyId': _selectedSpecialtyId,
        'licenseNumber': _licenseController.text.trim(),
        'bio': _bioController.text.trim(),
        'consultationFee': double.tryParse(_feeController.text.trim()) ?? 0,
      };
      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }
      if (_isEdit) {
        data['status'] = _selectedStatus;
        await DoctorsService.updateDoctor(
          widget.doctor!['id'].toString(),
          data,
        );
      } else {
        await DoctorsService.createDoctor(data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Médecin modifié' : 'Médecin ajouté'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Modifier le médecin' : 'Nouveau médecin',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8D3188),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _field(_firstNameController, 'Prénom', true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastNameController, 'Nom', true)),
              ],
            ),
            const SizedBox(height: 12),
            _field(_emailController, 'Email', true, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_phoneController, 'Téléphone', true, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            // Spécialité
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecialtyId,
              decoration: _decoration('Spécialité'),
              items: widget.specialties.map((s) {
                return DropdownMenuItem(
                  value: s['id'].toString(),
                  child: Text(s['name'] ?? ''),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedSpecialtyId = v),
              validator: (v) => v == null ? 'Spécialité requise' : null,
            ),
            const SizedBox(height: 12),
            _field(_licenseController, 'Numéro de licence', true),
            const SizedBox(height: 12),
            _field(
              _feeController,
              'Frais de consultation',
              false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            _field(_bioController, 'Biographie', false, maxLines: 3),
            const SizedBox(height: 12),
            _field(
              _passwordController,
              _isEdit
                  ? 'Nouveau mot de passe (laisser vide pour ne pas changer)'
                  : 'Mot de passe',
              !_isEdit,
              obscure: true,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: _decoration('Statut'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Actif')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                  DropdownMenuItem(value: 'blocked', child: Text('Bloqué')),
                ],
                onChanged: (v) =>
                    setState(() => _selectedStatus = v ?? 'active'),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D3188),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Enregistrer' : 'Créer le compte',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    bool required, {
    TextInputType? keyboardType,
    bool obscure = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      decoration: _decoration(label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label requis';
        }
        if (label == 'Email' &&
            value != null &&
            value.isNotEmpty &&
            !value.contains('@')) {
          return 'Email invalide';
        }
        return null;
      },
    );
  }
}
