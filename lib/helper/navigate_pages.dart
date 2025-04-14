import 'package:flutter/material.dart';
import 'package:nau/models/post.dart';
import 'package:nau/pages/account_settings_page.dart';
import 'package:nau/pages/blocked_users_page.dart';
import 'package:nau/pages/profile_page.dart';

import '../pages/post_page.dart';

//ir a la pantalla del usuario
void goUserPage(BuildContext context, String uid) {
  //navegar a la pagina del usuario
  Navigator.push(
      context, 
    MaterialPageRoute(
      builder: (context) => ProfilePage(uid: uid),
    ),
  );
}

//ir a pantalla de post
void goPostPage(BuildContext context, Post post){
  Navigator.push(
      context, 
    MaterialPageRoute(
      builder: (context) => PostPage(post: post,),
    ),
  );


}
  //ir a pantalla de post
void goBlockedUsersPage(BuildContext context){
  Navigator.push(
      context, 
    MaterialPageRoute(
      builder: (context) => const BlockedUsersPage(),
    ),
  );
}
  //ir a pantalla de post
void goAccountSettingsPage(BuildContext context){
  Navigator.push(
      context, 
    MaterialPageRoute(
      builder: (context) => const AccountSettingsPage(),
    ),
  );
  }