import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/consumed_beer.dart';
import '../../core/theme/app_theme.dart';
import '../common/bubble_animation.dart';

/// Widget für eine Bier-Liste-Tile mit Animation
class BeerListTile extends StatefulWidget {
  final ConsumedBeer beer;
  final Animation<double> animation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BeerListTile({
    super.key,
    required this.beer,
    required this.animation,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<BeerListTile> createState() => _BeerListTileState();
}

class _BeerListTileState extends State<BeerListTile> {
  late List<Bubble> _bubbles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _bubbles = BubbleGenerator.generateBubbles(
      count: 15,
      random: _random,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.beerGold, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Bier Hintergrund (Gradient)
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.beerCardGradient,
              ),
            ),

            // Blasen Animation
            AnimatedBuilder(
              animation: widget.animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BubblePainter(
                    bubbles: _bubbles,
                    animationValue: widget.animation.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Inhalt
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Icon / Flagge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.beer.getCountryEmoji(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Text Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.beer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.beer.getCountryName(),
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.black.withOpacity(0.6),
                            ),
                            Text(
                              " ${widget.beer.rating}/10",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.beer.date.day}.${widget.beer.date.month}.${widget.beer.date.year}",
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Prozent Anzeige
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${widget.beer.percentage}%",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black54),
                        tooltip: 'Eintrag bearbeiten',
                        onPressed: widget.onEdit,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Eintrag löschen',
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
