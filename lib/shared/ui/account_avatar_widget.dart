import 'package:flutter/material.dart';

class AccountAvatarWidget extends StatelessWidget {
  const AccountAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const CircleAvatar(radius: 16, child: Icon(Icons.person)),
      onPressed: () {
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(55, 55, 0, 0),
          items: [
            PopupMenuItem(
              value: 'account_settings',
              child: const Text('Account Settings'),
              onTap: () {},
            ),
            const PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ).then((value) {
          if (value == 'logout') {
            // Handle logout logic here
          }
        });
      },
    );
  }
}
