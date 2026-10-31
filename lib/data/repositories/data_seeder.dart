import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class DataSeeder {
  static Future<void> seedIfEmpty() async {
    final firestore = FirebaseFirestore.instance;
    
    // Check if messes collection is empty
    final messSnapshot = await firestore
        .collection(AppConstants.messesCollection)
        .get();
        
    if (messSnapshot.docs.isNotEmpty) {
      debugPrint('Firestore already contains ${messSnapshot.docs.length} messes:');
      for (var doc in messSnapshot.docs) {
        debugPrint('  - Mess ID: ${doc.id}, Name: ${doc.data()['name']}, Hidden: ${doc.data()['hidden']}, District: ${doc.data()['district']}');
      }
      
      final roomsSnapshot = await firestore
          .collection(AppConstants.roomsCollection)
          .get();
      debugPrint('Firestore contains ${roomsSnapshot.docs.length} rooms:');
      for (var doc in roomsSnapshot.docs) {
        debugPrint('  - Room ID: ${doc.id}, MessID: ${doc.data()['messId']}, District: ${doc.data()['district']}');
      }
      return;
    }
    
    debugPrint('Firestore messes collection is empty. Starting seeding...');
    
    // Define sample messes
    final sampleMesses = [
      {
        'name': 'Royal Boys PG & Mess',
        'address': 'Station Road, Near FM College, Balasore',
        'description': 'Premium accommodation for boys with nutritious homely food, high-speed Wi-Fi, and 24/7 security. Just a 5-minute walk from FM College.',
        'messType': 'Boys',
        'posterUrl': 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=600&q=80',
        'galleryUrls': [
          'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
        ],
        'amenities': {
          'wifi': true,
          'ac': true,
          'food': true,
          'inverter': true,
          'tableChair': true,
        },
        'location': const GeoPoint(21.4938, 86.9221),
        'locationUrl': 'https://maps.google.com/?q=21.4938,86.9221',
        'hidden': false,
        'isUserSourced': false,
        'isSponsored': true,
        'sponsorRank': 1,
        'lastUpdatedDate': Timestamp.now(),
        'foodFacility': '3 meals/day included (Veg & Non-Veg options)',
        'security': 'CCTV, 24/7 Warden, Biometric Entry',
        'extraAppliances': 'Washing Machine, Water Purifier, Geyser',
        'advanceDeposit': '₹5,000 (Refundable)',
        'district': 'balasore',
        'contact': '9876543210',
        'hideContact': false,
        'rooms': [
          {
            'roomType': 'Single Bed Room',
            'occupancy': '1',
            'price': 6500,
            'rent': 6500,
            'imageUrls': [
              'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': true,
              'wifi': true,
              'attachedBath': true,
            },
            'availableCount': 2,
            'available': true,
            'district': 'balasore',
          },
          {
            'roomType': 'Double Sharing Room',
            'occupancy': '2',
            'price': 4200,
            'rent': 4200,
            'imageUrls': [
              'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': false,
              'wifi': true,
              'attachedBath': false,
            },
            'availableCount': 5,
            'available': true,
            'district': 'balasore',
          }
        ]
      },
      {
        'name': 'Elite Girls Residency & Home',
        'address': 'Kuruda, Near FM University, Balasore',
        'description': 'Extremely safe and secure mess for female students and working professionals. Clean rooms, high security, Warden supervision, and delicious daily meals.',
        'messType': 'Girls',
        'posterUrl': 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=600&q=80',
        'galleryUrls': [
          'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=600&q=80',
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80',
        ],
        'amenities': {
          'wifi': true,
          'ac': true,
          'food': true,
          'inverter': true,
          'tableChair': true,
        },
        'location': const GeoPoint(21.4984, 86.9312),
        'locationUrl': 'https://maps.google.com/?q=21.4984,86.9312',
        'hidden': false,
        'isUserSourced': false,
        'isSponsored': false,
        'lastUpdatedDate': Timestamp.now(),
        'foodFacility': 'Homely food (Breakfast, Lunch, Dinner)',
        'security': '24/7 security guard, CCTV cameras, Restricted entry',
        'extraAppliances': 'Fridge, Washing Machine, RO Water, Microwave',
        'advanceDeposit': '₹4,000 (Refundable)',
        'district': 'balasore',
        'contact': '9876543211',
        'hideContact': false,
        'rooms': [
          {
            'roomType': 'Single AC Room',
            'occupancy': '1',
            'price': 7500,
            'rent': 7500,
            'imageUrls': [
              'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': true,
              'wifi': true,
            },
            'availableCount': 3,
            'available': true,
            'district': 'balasore',
          },
          {
            'roomType': 'Double AC Sharing',
            'occupancy': '2',
            'price': 5000,
            'rent': 5000,
            'imageUrls': [
              'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': true,
              'wifi': true,
            },
            'availableCount': 4,
            'available': true,
            'district': 'balasore',
          }
        ]
      },
      {
        'name': 'Sai Krishna Student Mess',
        'address': 'OT Road, Near Harichandan Mandir, Balasore',
        'description': 'Budget-friendly mess catering to students. Offers clean sharing rooms, study tables, and quality meals twice a day (Lunch & Dinner). No hidden charges.',
        'messType': 'Boys',
        'posterUrl': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=600&q=80',
        'galleryUrls': [
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=600&q=80',
        ],
        'amenities': {
          'wifi': true,
          'ac': false,
          'food': true,
          'inverter': false,
          'tableChair': true,
        },
        'location': const GeoPoint(21.4912, 86.9150),
        'locationUrl': 'https://maps.google.com/?q=21.4912,86.9150',
        'hidden': false,
        'isUserSourced': true,
        'isSponsored': false,
        'lastUpdatedDate': Timestamp.now(),
        'foodFacility': 'Lunch and Dinner (Veg daily, Non-veg twice a week)',
        'security': 'Safe locality, CCTV at gate',
        'extraAppliances': 'Water Filter, Common Study Area',
        'advanceDeposit': '₹2,000',
        'district': 'balasore',
        'contact': '9876543212',
        'hideContact': false,
        'rooms': [
          {
            'roomType': 'Double Sharing',
            'occupancy': '2',
            'price': 3000,
            'rent': 3000,
            'imageUrls': [
              'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': false,
              'wifi': true,
            },
            'availableCount': 6,
            'available': true,
            'district': 'balasore',
          },
          {
            'roomType': 'Triple Sharing Room',
            'occupancy': '3',
            'price': 2200,
            'rent': 2200,
            'imageUrls': [
              'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?auto=format&fit=crop&w=600&q=80',
            ],
            'images': [],
            'amenities': {
              'ac': false,
              'wifi': true,
            },
            'availableCount': 8,
            'available': true,
            'district': 'balasore',
          }
        ]
      }
    ];

    // Seed data
    for (var messData in sampleMesses) {
      final roomsData = messData.remove('rooms') as List<Map<String, dynamic>>;
      
      // Add mess document
      final messDocRef = await firestore
          .collection(AppConstants.messesCollection)
          .add(messData);
          
      debugPrint('Seeded mess: ${messData['name']} with ID: ${messDocRef.id}');
      
      // Add its rooms
      for (var roomData in roomsData) {
        roomData['messId'] = messDocRef.id;
        final roomDocRef = await firestore
            .collection(AppConstants.roomsCollection)
            .add(roomData);
        debugPrint('  Seeded room: ${roomData['roomType']} with ID: ${roomDocRef.id}');
      }
    }
    
    debugPrint('Firestore database seeding successfully completed!');
  }
}
