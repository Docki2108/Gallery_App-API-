// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../full_screen_image.dart';
import '../locals.dart';
import '../models/image_model.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Dio _dio;
  final List<ImageData> _images = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.unsplash.com/',
      headers: {
        'Authorization': 'Client-ID $apiKey',
      },
      receiveTimeout: const Duration(seconds: 10),
      connectTimeout: const Duration(seconds: 10),
    ));
    _fetchImages();
    _scrollController.addListener(_scrollListener);

    _searchController.addListener(() {
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _searchQuery = _searchController.text;
          _images.clear();
          page = 1;
          _isLoading = true;
          _fetchImages();
        });
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchImages({int page = 1}) async {
    if (_isLoadingMore) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final String endpoint = _searchQuery.isEmpty ? 'photos' : 'search/photos';

      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'query': _searchQuery.isEmpty ? '' : _searchQuery,
          'page': page,
          'per_page': perPage,
        },
      );

      final photos = _searchQuery.isEmpty
          ? response.data as List
          : response.data['results'] as List;

      setState(() {
        _images.addAll(
          photos
              .map((photo) => ImageData(
                    url: photo['urls']['regular'],
                    likes: photo['likes'] ?? 0,
                  ))
              .toList(),
        );
        _isLoading = false;
        _isLoadingMore = false;
        page = page;
      });
    } catch (e) {
      log("Ошибка при загрузке изображений: $e" as num);
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore) {
      _fetchImages(page: page + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int columnCount = (MediaQuery.of(context).size.width / 150).floor();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Галерея картинок (Unsplash API)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Поиск...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: MasonryGridView.count(
                      controller: _scrollController,
                      crossAxisCount: columnCount,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImage(
                                  imageUrls:
                                      _images.map((img) => img.url).toList(),
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                image.url,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Нравится: ${image.likes}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                    ),
                  ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
