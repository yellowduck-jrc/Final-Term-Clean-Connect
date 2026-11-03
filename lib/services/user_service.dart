import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user_model.dart';

class UserService{
  final FirebaseFirestore debase = FirebaseFirestore.instance;

  //Saves a new user's information in Firestore
  Future<void> createUser(AppUserModel user) async{
    await debase.collection('users').doc(user.uid).set(
      user.toMap(),
    );
  }

  //Retrieves a user's information using their UID
  Future<AppUserModel?> getUser(String uid) async {
    DocumentSnapshot<Map<String, dynamic>> document = 
    await debase.collection('users').doc(uid).get();

  if(document.exists && document.data() != null) {
    return AppUserModel.fromMap(
       document.id,
       document.data()!,
      );
    }
    return null;
  }
  //Updates existing user information
  Future<void> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await debase.collection('users').doc(uid).update(data);
  }
}