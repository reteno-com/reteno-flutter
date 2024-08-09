import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reteno_plugin/reteno.dart';

class AppInboxButton extends StatelessWidget {
  const AppInboxButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            context.go('/appInbox');
          },
          icon: const Icon(Icons.mail),
        ),
        StreamBuilder<int>(
          stream: Reteno.appInbox.onMessagesCountChanged,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data.toString());
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
