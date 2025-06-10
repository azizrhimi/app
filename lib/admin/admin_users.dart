import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:amira_app/shared/colors.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _motDePasseController = TextEditingController(); // ✅ champ mot de passe
  String? _selectedRole;
  bool _isAdding = false;
  final List<String> _roles = ['admin', 'client', 'transporteur'];

  Future<void> _addUser() async {
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _motDePasseController.text.isEmpty ||
        _selectedRole == null) {
      Get.snackbar('Erreur', 'Veuillez remplir tous les champs.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100);
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _motDePasseController.text.trim(), // ✅ mot de passe personnalisé
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'role': _selectedRole,
      });

      Get.snackbar('Succès', 'Utilisateur ajouté avec succès.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.shade100);

      setState(() {
        _emailController.clear();
        _nameController.clear();
        _motDePasseController.clear(); // ✅ vider champ mot de passe
        _selectedRole = null;
        _isAdding = false;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de l\'ajout : $e',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100);
    }
  }

  Future<void> _editUser(String userId, String currentName,
      String currentEmail, String currentRole) async {
    final editEmailController = TextEditingController(text: currentEmail);
    final editNameController = TextEditingController(text: currentName);
    String? editSelectedRole = currentRole;

    await Get.dialog(
      AlertDialog(
        title: const Text('Modifier l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: editNameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            DropdownButton<String>(
              value: editSelectedRole,
              hint: const Text('Sélectionner un rôle'),
              items: _roles.map((String role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  editSelectedRole = newValue;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (editEmailController.text.isEmpty ||
                  editNameController.text.isEmpty ||
                  editSelectedRole == null) {
                Get.snackbar('Erreur', 'Veuillez remplir tous les champs.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade100);
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({
                  'email': editEmailController.text.trim(),
                  'name': editNameController.text.trim(),
                  'role': editSelectedRole,
                });
                Get.back();
                Get.snackbar('Succès', 'Utilisateur modifié avec succès.',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.green.shade100);
              } catch (e) {
                Get.snackbar('Erreur', 'Échec de la modification : $e',
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.red.shade100);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: mainColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                _isAdding = true;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAdding)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  TextField(
                    controller: _motDePasseController,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                  ),
                  DropdownButton<String>(
                    value: _selectedRole,
                    hint: const Text('Sélectionner un rôle'),
                    items: _roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isAdding = false;
                          });
                        },
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: _addUser,
                        child: const Text('Ajouter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Nom")),
                      DataColumn(label: Text("Email")),
                      DataColumn(label: Text("Rôle")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: users.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final role = data['role'] ?? 'inconnu';
                      final displayName = role == 'transporteur'
                          ? (data['name'] ?? 'Sans nom')
                          : role == 'client'
                              ? '${data['name'] ?? ''}'.trim()
                              : (data['name'] ?? 'Admin');

                      return DataRow(cells: [
                        DataCell(Text(displayName)),
                        DataCell(Text(data['email'] ?? 'Sans email')),
                        DataCell(Text(role)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editUser(
                                doc.id,
                                displayName,
                                data['email'] ?? '',
                                role,
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                        const Text('Supprimer l’utilisateur'),
                                    content: Text(
                                        'Voulez-vous supprimer $displayName ?'),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Annuler'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Supprimer',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(doc.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Utilisateur supprimé avec succès')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Erreur lors de la suppression : $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
