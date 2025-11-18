// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:resala/screens/themes/app_theme.dart';
// import 'package:resala/services/database_service.dart';

// class ProfilesScreen extends StatefulWidget {
//   const ProfilesScreen({super.key});

//   @override
//   State<ProfilesScreen> createState() => _ProfilesScreenState();
// }

// class _ProfilesScreenState extends State<ProfilesScreen> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();

//   Future<void> _addProfile() async {
//     if (_nameController.text.isEmpty) return;

//     final database = Provider.of<DatabaseService>(context, listen: false);
//     try {
//       await database.addProfile({
//         'name': _nameController.text,
//         'email': _emailController.text,
//         'phone': _phoneController.text,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       _nameController.clear();
//       _emailController.clear();
//       _phoneController.clear();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('تم إضافة البروفايل بنجاح!')),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
//     }
//   }

//   Future<void> _deleteProfile(String profileId) async {
//     final database = Provider.of<DatabaseService>(context, listen: false);
//     try {
//       await database.deleteDocument('profiles', profileId);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("بروفايلات"),
//         backgroundColor: AppTheme.primary,
//         foregroundColor: Colors.white,
//       ),
//       body: Container(
//         color: AppTheme.primary,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Add Profile Form
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       TextField(
//                         controller: _nameController,
//                         decoration: const InputDecoration(labelText: 'الاسم'),
//                       ),
//                       TextField(
//                         controller: _emailController,
//                         decoration: const InputDecoration(
//                           labelText: 'البريد الإلكتروني',
//                         ),
//                       ),
//                       TextField(
//                         controller: _phoneController,
//                         decoration: const InputDecoration(labelText: 'الهاتف'),
//                       ),
//                       const SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: _addProfile,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppTheme.primary,
//                           foregroundColor: Colors.white,
//                           minimumSize: const Size(double.infinity, 50),
//                         ),
//                         child: const Text('إضافة بروفايل'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Profiles List
//               Expanded(
//                 child: StreamBuilder(
//                   stream: Provider.of<DatabaseService>(context).getProfiles(),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasError) {
//                       return Center(child: Text('خطأ: ${snapshot.error}'));
//                     }
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     final profiles = snapshot.data!.docs;

//                     if (profiles.isEmpty) {
//                       return const Center(
//                         child: Text(
//                           'لا توجد بروفايلات',
//                           style: TextStyle(color: Colors.white, fontSize: 18),
//                         ),
//                       );
//                     }

//                     return ListView.builder(
//                       itemCount: profiles.length,
//                       itemBuilder: (context, index) {
//                         final profile = profiles[index];
//                         final data = profile.data() as Map<String, dynamic>;

//                         return Card(
//                           margin: const EdgeInsets.only(bottom: 8),
//                           child: ListTile(
//                             leading: const Icon(Icons.person),
//                             title: Text(data['name'] ?? ''),
//                             subtitle: Text(
//                               '${data['email'] ?? ''} - ${data['phone'] ?? ''}',
//                             ),
//                             trailing: IconButton(
//                               icon: const Icon(Icons.delete, color: Colors.red),
//                               onPressed: () => _deleteProfile(profile.id),
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
