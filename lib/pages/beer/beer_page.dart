import 'package:flutter/material.dart';

import '../../models/beer.dart';
import '../../services/beer_service.dart';

class BeerPage extends StatefulWidget {
  const BeerPage({super.key});

  @override
  State<BeerPage> createState() => _BeerPageState();
}

class _BeerPageState extends State<BeerPage> {
  final BeerService _beerService = BeerService();

  bool _isLoading = true;
  String? _error;
  List<Beer> _beers = [];

  @override
  void initState() {
    super.initState();
    _loadBeers();
  }

  Future<void> _loadBeers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final beers = await _beerService.getBeers();
      setState(() {
        _beers = beers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Konnte Biere nicht laden: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text('Brauereien werden geladen...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadBeers,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (_beers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_drink, size: 64),
            const SizedBox(height: 12),
            const Text('Keine Biere gefunden.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadBeers,
              child: const Text('Neu laden'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Biere (${_beers.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadBeers,
            child: ListView.separated(
              itemCount: _beers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final beer = _beers[index];
                final subtitleParts = [
                  beer.brewery,
                  beer.region,
                  if (beer.style != null) beer.style,
                ].where((e) => e != null && e.toString().isNotEmpty).join(' · ');

                return ListTile(
                  title: Text(beer.name),
                  subtitle: subtitleParts.isNotEmpty
                      ? Text(subtitleParts)
                      : const Text('Keine Details'),
                  trailing: beer.abv != null
                      ? Chip(
                          label: Text(
                            '${beer.abv!.toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        )
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}