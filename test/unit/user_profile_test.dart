import 'package:flutter_test/flutter_test.dart';
import 'package:feierabendbierchen_flutter/models/user_profile.dart';
import 'package:feierabendbierchen_flutter/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('UserProfile', () {
    test('sollte UserProfile korrekt erstellen', () {
      // Arrange & Act
      final profile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderMale,
        imageUrl: 'https://example.com/image.jpg',
      );

      // Assert
      expect(profile.userId, equals('test-user'));
      expect(profile.name, equals('Test User'));
      expect(profile.weight, equals(75.0));
      expect(profile.height, equals(175.0));
      expect(profile.gender, equals(AppConstants.genderMale));
      expect(profile.imageUrl, equals('https://example.com/image.jpg'));
    });

    test('sollte toFirestore korrekt konvertieren', () {
      // Arrange
      final profile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderFemale,
      );

      // Act
      final firestoreData = profile.toFirestore();

      // Assert
      expect(firestoreData['name'], equals('Test User'));
      expect(firestoreData['weight'], equals(75.0));
      expect(firestoreData['height'], equals(175.0));
      expect(firestoreData['gender'], equals(AppConstants.genderFemale));
      expect(firestoreData['imageUrl'], isNull);
    });

    test('sollte hasImage korrekt prüfen', () {
      // Arrange - Mit Bild
      final profileWithImage = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderMale,
        imageUrl: 'https://example.com/image.jpg',
      );

      // Arrange - Ohne Bild
      final profileWithoutImage = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderMale,
      );

      // Arrange - Leeres Bild
      final profileWithEmptyImage = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderMale,
        imageUrl: '',
      );

      // Act & Assert
      expect(profileWithImage.hasImage(), isTrue);
      expect(profileWithoutImage.hasImage(), isFalse);
      expect(profileWithEmptyImage.hasImage(), isFalse);
    });

    test('sollte verschiedene Gender-Werte akzeptieren', () {
      // Arrange & Act
      final maleProfile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 75.0,
        height: 175.0,
        gender: AppConstants.genderMale,
      );

      final femaleProfile = UserProfile(
        userId: 'test-user',
        name: 'Test User',
        weight: 65.0,
        height: 165.0,
        gender: AppConstants.genderFemale,
      );

      // Assert
      expect(maleProfile.gender, equals(AppConstants.genderMale));
      expect(femaleProfile.gender, equals(AppConstants.genderFemale));
    });
  });
}
