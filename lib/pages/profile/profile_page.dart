import 'package:flutter/material.dart';
import './login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ES GEHT NOCH PERSÖNLICHER"),
        const Text(
          "Für ein personalisiertes App-Erlebnis, melde dich an oder log dich ein.",
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text("Login"),
        ),
        const SizedBox(
          width: 400,
          height: 400,
          child: Image(
            image: AssetImage('assets/consumed-beer.png'),
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}