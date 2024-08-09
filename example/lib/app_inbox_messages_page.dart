import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reteno_plugin/reteno.dart';

class AppInboxMessagesPage extends StatefulWidget {
  const AppInboxMessagesPage({super.key});

  @override
  State<AppInboxMessagesPage> createState() => _AppInboxMessagesPageState();
}

class _AppInboxMessagesPageState extends State<AppInboxMessagesPage> {
  _State _state = _State(
    messages: [],
    isLoading: true,
    isError: false,
  );
  @override
  void initState() {
    super.initState();
    getMessages(context);
  }

  Future<void> getMessages(BuildContext context) async {
    _state = _state.copyWith(isLoading: true, isError: false);
    setState(() {});
    try {
      final messages = await Reteno.appInbox.getAppInboxMessages();
      _state = _state.copyWith(isLoading: false, isError: false, messages: messages.messages);
    } catch (e) {
      _state = _state.copyWith(isLoading: false, isError: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Inbox Messages'),
        actions: [
          IconButton(
            onPressed: () {
              showAdaptiveDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Mark all messages as read?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Reteno.appInbox.markAllMessagesAsOpened();
                        if (context.mounted) {
                          getMessages(context);
                        }
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.checklist,
            ),
          ),
        ],
      ),
      body: _state.isLoading && _state.messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_state.messages.isEmpty) {
      return const Center(child: Text('No messages'));
    }
    return ListView.separated(
      itemCount: _state.messages.length,
      itemBuilder: (context, index) {
        final message = _state.messages[index];
        return ListTile(
          title: Text(message.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.content ?? ''),
              const SizedBox(height: 5),
              Text(message.createdDate, style: const TextStyle(fontSize: 10)),
            ],
          ),
          leading: message.imageUrl != null ? Image.network(message.imageUrl!) : null,
          trailing: message.isNewMessage
              ? const Icon(
                  Icons.circle,
                  color: Colors.blue,
                  size: 10,
                )
              : null,
          onTap: () {
            showAdaptiveDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Mark as read?'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      Reteno.appInbox.markAsOpened(message.id);
                      setState(() {
                        _state = _state.copyWith(
                          messages: _state.messages.map((m) {
                            if (m.id == message.id) {
                              return m.copyWith(isNewMessage: false);
                            }
                            return m;
                          }).toList(),
                        );
                      });
                    },
                    child: const Text('Yes'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('No'),
                  ),
                ],
              ),
            );
          },
        );
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }
}

class _State {
  _State({required this.messages, required this.isLoading, required this.isError});
  final List<AppInboxMessage> messages;
  final bool isLoading;
  final bool isError;

  _State copyWith({List<AppInboxMessage>? messages, bool? isLoading, bool? isError}) {
    return _State(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}
