import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  User? user;
  String? existingImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          nameController.text = userDoc['name'];
          emailController.text = userDoc['email'];
          existingImageUrl = userDoc['imageUrl'];
        });
      }
    }
  }

  void handleEdit() {
    setState(() {
      isEditing = true;
    });
  }

  Future<void> handleSave() async {
    setState(() {
      isEditing = false;
    });

    String? imageUrl = existingImageUrl;
    if (_image != null && _image!.path != existingImageUrl) {
      imageUrl = await _uploadImage(_image!);
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': nameController.text,
        'email': emailController.text,
        'imageUrl': imageUrl,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informações salvas com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar informações: $e')),
      );
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final extension = image.path.split('.').last;
      final storageRef = FirebaseStorage.instance.ref().child('user_images/${DateTime.now().millisecondsSinceEpoch}.$extension');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer upload da imagem: $e')),
      );
      return '';
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _image = File(result.files.single.path!);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: isEditing ? _pickImage : null,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _image != null
                    ? FileImage(_image!)
                    : (existingImageUrl != null
                        ? NetworkImage(existingImageUrl!)
                        : const AssetImage('assets/profile_picture.png')) as ImageProvider,
                child: _image == null && existingImageUrl == null ? const Icon(Icons.person, size: 50) : null,
              ),
            ),
            if (isEditing && _image != null)
              TextButton(
                onPressed: _removeImage,
                child: const Text('Remover Imagem'),
              ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              enabled: isEditing,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: isEditing,
            ),
            const SizedBox(height: 20),
            isEditing
                ? ElevatedButton(
                    onPressed: handleSave,
                    child: const Text('Salvar'),
                  )
                : ElevatedButton(
                    onPressed: handleEdit,
                    child: const Text('Editar'),
                  ),
          ],
        ),
      ),
    );
  }
}
