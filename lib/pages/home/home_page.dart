import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Willkommen zurück",
            style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
          ),
          const Text("Petar Kukic", style: TextStyle(fontSize: 32.0)),
          const SizedBox(height: 20),
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Heutiger Bierkonsum",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text("Anz. an Getränken: 3"),
                        Text("Promille im Blut - JETZT: 0.5‰"),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100, // Adjusted size for better layout
                    height: 100,
                    child: Image(
                      image: AssetImage('assets/consumed-beer.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}