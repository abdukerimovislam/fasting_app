// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> articleData;

  const ArticleDetailScreen({super.key, required this.articleData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(articleData['title'] ?? 'Article'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (articleData['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  articleData['imageUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                  const SizedBox(height: 200, child: Icon(Icons.image_not_supported)),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              articleData['title'] ?? 'No Title',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              articleData['content'] ?? 'No content available.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}