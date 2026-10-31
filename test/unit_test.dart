import 'package:flutter_test/flutter_test.dart';
import 'package:messkhojo_flutter/core/utils/fuzzy_search.dart';
import 'package:messkhojo_flutter/data/models/mess_model.dart';
import 'package:messkhojo_flutter/data/models/room_model.dart';
import 'package:messkhojo_flutter/data/models/hero_ad_model.dart';
import 'package:messkhojo_flutter/data/models/claim_model.dart';
import 'package:messkhojo_flutter/data/models/inquiry_model.dart';

void main() {
  group('Fuzzy Search Utility Tests', () {
    test('levenshtein calculates similarity distance correctly', () {
      // Exactly same words
      expect(levenshtein('Balasore', 'Balasore'), 0);
      
      // Completely different words
      expect(levenshtein('Balasore', 'Kolkata'), 7);
      
      // Partial matches
      expect(levenshtein('Bhadrak', 'Bhadrakh'), 1);
    });

    test('fuzzyScore scores correctly', () {
      final scorePerfect = fuzzyScore('Balasore', 'Balasore Boys Mess');
      expect(scorePerfect, greaterThan(0));

      final scoreNone = fuzzyScore('Kolkata', 'Balasore Boys Mess');
      expect(scoreNone, equals(0));
    });
  });

  group('MessModel & RoomModel Unit Tests', () {
    test('MessModel fromMap and toMap serialization', () {
      final now = DateTime.now();
      final original = MessModel(
        id: 'test-mess-123',
        name: 'Saraswati Mess',
        address: 'Near FM College, Balasore',
        description: 'Clean mess with food facility',
        messType: 'Boys',
        posterUrl: 'https://images.com/poster.jpg',
        galleryUrls: ['https://images.com/g1.jpg', 'https://images.com/g2.jpg'],
        district: 'balasore',
        contact: '+919876543210',
        hideContact: false,
        lastUpdatedDate: now,
      );

      final map = original.toMap();
      expect(map['name'], 'Saraswati Mess');
      expect(map['district'], 'balasore');
      expect(map['contact'], '+919876543210');
      expect(map['hideContact'], false);

      final deserialized = MessModel.fromMap(map, 'test-mess-123');
      expect(deserialized.id, 'test-mess-123');
      expect(deserialized.name, 'Saraswati Mess');
      expect(deserialized.district, 'balasore');
      expect(deserialized.contact, '+919876543210');
      expect(deserialized.hideContact, false);
      expect(deserialized.galleryUrls, containsAll(['https://images.com/g1.jpg', 'https://images.com/g2.jpg']));
    });

    test('RoomModel fromMap and toMap serialization', () {
      final original = RoomModel(
        id: 'room-1',
        messId: 'test-mess-123',
        roomType: 'Deluxe AC',
        occupancy: 'Double',
        price: 2500,
        rent: 2500,
        availableCount: 2,
        available: true,
        imageUrls: ['https://images.com/room1.jpg'],
        amenities: {'ac': true, 'attachedBathroom': true},
        district: 'balasore',
      );

      final map = original.toMap();
      expect(map['messId'], 'test-mess-123');
      expect(map['price'], 2500);
      expect(map['availableCount'], 2);

      final deserialized = RoomModel.fromMap(map, 'room-1');
      expect(deserialized.id, 'room-1');
      expect(deserialized.price, 2500);
      expect(deserialized.availableCount, 2);
      expect(deserialized.amenities['ac'], true);
    });

    test('MessModel handles newly synced website fields', () {
      final data = {
        'name': 'Bhubaneswar Premier Mess',
        'district': 'khorda',
        'city': 'bhubaneswar',
        'locality': 'Patia',
        'foodAvailability': 'Food Available',
        'waterFacility': 'Both',
        'laundryFacility': 'Washing Machine',
        'cleaningService': 'Both',
        'cctv': true,
        'wardenWatchman': true,
        'extraSpace': ['Parking', 'Terrace'],
        'securityDeposit': '1 Month',
        'noticePeriod': '1 Month',
        'operatingSince': '2021',
        'buildingPhotoUrls': ['https://images.com/building.jpg'],
        'vacantRooms': ['Single', 'Double'],
        'contact': '+919999999999',
      };

      final mess = MessModel.fromMap(data, 'mess-bbsr-1');
      expect(mess.locality, 'Patia');
      expect(mess.foodAvailability, 'Food Available');
      expect(mess.waterFacility, 'Both');
      expect(mess.laundryFacility, 'Washing Machine');
      expect(mess.cctv, true);
      expect(mess.wardenWatchman, true);
      expect(mess.extraSpace, contains('Parking'));
      expect(mess.securityDeposit, '1 Month');
      expect(mess.noticePeriod, '1 Month');
      expect(mess.operatingSince, '2021');
      expect(mess.buildingPhotoUrls?.first, 'https://images.com/building.jpg');
      expect(mess.vacantRooms, contains('Single'));
    });

    test('RoomModel handles newly synced website fields (label, isVacant, otherInfo)', () {
      final data = {
        'messId': 'mess-bbsr-1',
        'occupancy': '2',
        'price': 3000,
        'label': 'AC Room with Attached Bath',
        'isVacant': true,
        'otherInfo': 'Balcony facing, furnished with study table',
        'category': 'Deluxe',
      };

      final room = RoomModel.fromMap(data, 'room-deluxe-1');
      expect(room.label, 'AC Room with Attached Bath');
      expect(room.isVacant, true);
      expect(room.otherInfo, 'Balcony facing, furnished with study table');
      expect(room.category, 'Deluxe');
    });

    test('HeroAdModel serializes and selects mobileUrl over imageUrl', () {
      final ad = HeroAdModel.fromMap({
        'imageUrl': 'https://images.com/desktop.jpg',
        'mobileUrl': 'https://images.com/mobile.jpg',
        'active': true,
        'order': 1,
        'section': 'home',
        'title': '50% Off First Month',
      }, 'ad-1');

      expect(ad.id, 'ad-1');
      expect(ad.displayUrl, 'https://images.com/mobile.jpg');
      expect(ad.active, true);
      expect(ad.order, 1);
      expect(ad.title, '50% Off First Month');
    });

    test('InquiryModel fromMap and toMap', () {
      final inquiry = InquiryModel(
        id: 'inq-1',
        userName: 'Rahul Verma',
        userPhone: '9876543210',
        messId: 'mess-1',
        messName: 'Sunrise Mess',
        status: 'pending',
      );

      final map = inquiry.toMap();
      expect(map['userName'], 'Rahul Verma');
      expect(map['messName'], 'Sunrise Mess');
      expect(map['status'], 'pending');

      final deserialized = InquiryModel.fromMap(map, 'inq-1');
      expect(deserialized.userName, 'Rahul Verma');
      expect(deserialized.messName, 'Sunrise Mess');
    });

    test('ClaimModel fromMap and toMap', () {
      final claim = ClaimModel(
        id: 'claim-1',
        messId: 'mess-1',
        messName: 'Sunrise Mess',
        userName: 'Owner Name',
        userPhone: '9876543210',
        userEmail: 'owner@gmail.com',
        status: ClaimStatus.pending,
      );

      final map = claim.toMap();
      expect(map['messName'], 'Sunrise Mess');
      expect(map['status'], 'pending');

      final deserialized = ClaimModel.fromMap(map, 'claim-1');
      expect(deserialized.userName, 'Owner Name');
      expect(deserialized.status, ClaimStatus.pending);
    });
  });
}
