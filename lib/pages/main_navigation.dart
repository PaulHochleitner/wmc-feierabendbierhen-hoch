import 'package:flutter/material.dart';
import './home/home_page.dart';
import './beer/beer_page.dart';
import './profile/profile_page.dart';

class MyHomePage extends StatefulWidget {
  final bool isLoggedIn;

  const MyHomePage({super.key, required this.isLoggedIn});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomePage(),
      if (widget.isLoggedIn) const BeerPage(),
      const ProfilePage(),
    ];

    void onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("FeierabendBierchen")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          if (widget.isLoggedIn)
            const BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: "Bierchen",
            ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: "Account"),
        ],
      ),
    );
  }
}