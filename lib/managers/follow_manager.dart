import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> followUser(String targetUserId) async {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final currentUserRef =
      FirebaseFirestore.instance.collection("users").doc(currentUserId);
  final targetUserRef =
      FirebaseFirestore.instance.collection("users").doc(targetUserId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    transaction.update(currentUserRef, {
      'following': FieldValue.arrayUnion([targetUserId])
    });
    transaction.update(targetUserRef, {
      'followers': FieldValue.arrayUnion([currentUserId])
    });
  });
}

Future<void> unfollowUser(String targetUserId) async {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final currentUserRef =
      FirebaseFirestore.instance.collection("users").doc(currentUserId);
  final targetUserRef =
      FirebaseFirestore.instance.collection("users").doc(targetUserId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    transaction.update(currentUserRef, {
      'following': FieldValue.arrayRemove([targetUserId])
    });
    transaction.update(targetUserRef, {
      'followers': FieldValue.arrayRemove([currentUserId])
    });
  });
}
