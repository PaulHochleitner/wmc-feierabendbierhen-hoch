import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeierabendBierchen',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

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
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
            icon: Icon(Icons.account_circle),
            label: "Accoount",
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Willkommen zurück",
            style: TextStyle(fontSize: 24, fontStyle: FontStyle.italic),
          ),
          Text("Petar Kukic", style: TextStyle(fontSize: 32.0)),
          SizedBox(height: 20),
          Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
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
                  Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('/consumed-beer.png'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
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

// Letzen 3 Getränke
// Wöchentlicher Verbrauch

class BeerPage extends StatelessWidget {
  const BeerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Beer Page"));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ES GEHT NOCH PERSÖNLICHER"),
        Text(
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
        Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('/consumed-beer.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        GoogleProvider(
          clientId:
              '903834040298-pl04rrl645ov1pmk56vuvcn73b3uk28j.apps.googleusercontent.com',
        ),
      ],
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          Navigator.pop(context);
        }),
      ],
    );
  }
}
