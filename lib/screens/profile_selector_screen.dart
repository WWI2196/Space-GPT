// lib/screens/profile_selector_screen.dart
import 'package:flutter/material.dart';
import '../models/profile_model.dart';

class ProfileSelectorScreen extends StatelessWidget {
  final bool isUserProfile; // true for user, false for model
  final Function(ProfileModel) onProfileSelected;

  const ProfileSelectorScreen({
    required this.isUserProfile,
    required this.onProfileSelected,
    super.key,
  });

  static final List<ProfileModel> userProfiles = [
    ProfileModel(id: 'user1', name: 'Default User', imagePath: 'assets/user_profiles/avatar1.png'),
    ProfileModel(id: 'user2', name: 'User 2', imagePath: 'assets/user_profiles/avatar2.png'),
    ProfileModel(id: 'user3', name: 'User 3', imagePath: 'assets/user_profiles/avatar3.png'),
    ProfileModel(id: 'user4', name: 'User 4', imagePath: 'assets/user_profiles/avatar4.png'),
  ];

  static final List<ProfileModel> modelProfiles = [
    ProfileModel(id: 'bot1', name: 'Space Bot', imagePath: 'assets/bot_profiles/bot1.png'),
    ProfileModel(id: 'bot2', name: 'Assistant 2', imagePath: 'assets/bot_profiles/bot2.png'),
    ProfileModel(id: 'bot3', name: 'Assistant 3', imagePath: 'assets/bot_profiles/bot3.png'),
    ProfileModel(id: 'bot4', name: 'Assistant 4', imagePath: 'assets/bot_profiles/bot4.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final profiles = isUserProfile ? userProfiles : modelProfiles;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(isUserProfile ? 'Choose Your Avatar' : 'Select Bot Avatar'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          return Hero(
            tag: profiles[index].id,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onProfileSelected(profiles[index]);
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    profiles[index].imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.error, color: Colors.white),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}