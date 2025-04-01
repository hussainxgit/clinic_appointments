import 'package:flutter/material.dart';

class AdvertisingWidget extends StatelessWidget {
  const AdvertisingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200, // Fixed height for consistency, adjust as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          16,
        ), // Slightly larger radius for modern feel
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4), // Subtle shadow for depth
          ),
        ],
        image: const DecorationImage(
          image: NetworkImage(
            'https://static.vecteezy.com/system/resources/thumbnails/025/199/730/small_2x/abstract-colorful-twisted-liquid-shape-ai-generative-free-png.png',
          ),
          fit: BoxFit.cover, // Changed to cover for better image scaling
          opacity: 0.8, // Slight opacity to ensure text readability
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          20.0,
        ), // Slightly more padding for breathing room
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Badge/Tag
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(
                  (0.7 * 255).toInt(),
                ), // More contrast
                borderRadius: BorderRadius.circular(
                  8,
                ), // Smaller radius for badge
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const Text(
                "Today's Pick",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600, // Semi-bold for emphasis
                ),
              ),
            ),
            // Main Text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to Make Patients',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold, // Bold for hierarchy
                    color: Colors.black87, // Better contrast
                  ),
                ),
                Text(
                  'Happy Every Day',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
