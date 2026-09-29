import 'package:dart_crm/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Userheader extends ConsumerStatefulWidget {
  const Userheader({super.key});

  @override
  ConsumerState<Userheader> createState() => _UserheaderState();
}

class _UserheaderState extends ConsumerState<Userheader> {
  @override
  Widget build(BuildContext context) {
    // Fetch user data from authProvider
    final user = ref.read(authProvider).loginResponse?.executiveBasicData?[0];
    final userName = user?.executiveName ?? 'Unknown User';
    // final userState = user?. ?? 'Unknown State';
    final userRole = user?.profileName ?? 'No Role';
    // final userRole = user?.executiveDesignationName ??
    //     'No Role';

    return Container(
      color: Color.fromRGBO(248, 221, 160, 1),
      width: double.infinity,
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("$userName", style: TextStyle(fontSize: 12)),
            Text(userRole, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
