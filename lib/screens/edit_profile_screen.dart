import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  // We no longer need a text field for the profile image URL.
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  // Holds the image file selected by the user.
  XFile? _selectedImage;

  // Keep the original lowercase username to check for changes.
  String? _originalUsernameLowercase;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  // Load current user data from Firestore.
  Future<void> _loadCurrentUserData() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = data["username"] ?? "";
          _originalUsernameLowercase =
              (data["username_lowercase"] ?? "").toString();
        });
      }
    }
  }

  // Pick an image from the gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // Upload the selected image to Firebase Storage and return its URL.
  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child("profileImages")
          .child("${user!.uid}.jpg");
      UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  // Check if the username already exists in Firestore (excluding current user's doc).
  Future<bool> _checkUsernameExists(String lowercaseUsername) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("username_lowercase", isEqualTo: lowercaseUsername)
        .get();
    for (var doc in querySnapshot.docs) {
      if (doc.id != user!.uid) {
        return true;
      }
    }
    return false;
  }

  // Update the profile in Firestore and FirebaseAuth.
  Future<void> _updateProfile() async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      String? profilePicUrl;
      if (_selectedImage != null) {
        profilePicUrl = await _uploadImage(_selectedImage!);
      }

      // Get trimmed username and its lowercase version.
      final newUsername = _usernameController.text.trim();
      final lowercaseUsername = newUsername.toLowerCase();

      // If the username has changed, check if it already exists.
      if (_originalUsernameLowercase != null &&
          lowercaseUsername != _originalUsernameLowercase) {
        bool exists = await _checkUsernameExists(lowercaseUsername);
        if (exists) {
          throw Exception("Username already taken");
        }
      }

      // Update the user's document.
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .update({
        "username": newUsername,
        "username_lowercase": lowercaseUsername,
        if (profilePicUrl != null) "profilePic": profilePicUrl,
      });

      // If a new password was provided, update it.
      if (_passwordController.text.isNotEmpty) {
        await user!.updatePassword(_passwordController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Display the current profile image if available.
    Widget imageWidget;
    if (_selectedImage != null) {
      imageWidget = CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(File(_selectedImage!.path)),
      );
    } else {
      imageWidget = const CircleAvatar(
        radius: 50,
        backgroundImage: AssetImage("assets/default-icon.png"),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            imageWidget,
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              child: const Text("Choose Image"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Username",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password (optional)",
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
