import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_providers.g.dart';

/// Every Firebase resource lives in Jakarta (docs/02).
const firebaseRegion = 'asia-southeast2';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
FirebaseFunctions functions(Ref ref) =>
    FirebaseFunctions.instanceFor(region: firebaseRegion);

@Riverpod(keepAlive: true)
FirebaseMessaging messaging(Ref ref) => FirebaseMessaging.instance;

@Riverpod(keepAlive: true)
FirebaseStorage storage(Ref ref) => FirebaseStorage.instance;
