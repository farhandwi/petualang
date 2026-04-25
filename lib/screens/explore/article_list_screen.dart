import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/app_config.dart';
import '../../models/explore_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ArticleModel> _articles = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchArticles({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
      });
    }

    if (!_hasMore) return;

    try {
      final queryParams = {
        'page': _page.toString(),
        'limit': '10',
        if (_searchController.text.isNotEmpty) 'search': _searchController.text,
        if (_selectedCategory != 'Semua') 'category': _selectedCategory,
      };

      final uri = Uri.parse('${AppConfig.baseUrlApi}/articles').replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          final List<dynamic> data = body['data'];
          final List<String> cats = List<String>.from(body['categories'] ?? []);
          
          setState(() {
            if (refresh) {
              _articles = data.map((json) => ArticleModel.fromJson(json)).toList();
            } else {
              _articles.addAll(data.map((json) => ArticleModel.fromJson(json)).toList());
            }
            if (cats.isNotEmpty && _categories.length == 1) {
               _categories = cats;
            }
            _hasMore = data.length == 10;
            if (_hasMore) _page++;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching articles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edukasi & Tips Petualang',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.card,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari artikel...',
                hintStyle: GoogleFonts.beVietnamPro(color: colors.textMuted),
                prefixIcon: Icon(Icons.search, color: colors.textMuted),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (_) => _fetchArticles(refresh: true),
            ),
          ),
          
          // Category Filter
          Container(
            color: colors.card,
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _fetchArticles(refresh: true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colors.primaryOrange : colors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? colors.primaryOrange : colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        category,
                        style: GoogleFonts.beVietnamPro(
                          color: isSelected ? Colors.white : colors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Article List
          Expanded(
            child: _isLoading && _articles.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _articles.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada artikel ditemukan.',
                          style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (!_isLoading &&
                              _hasMore &&
                              scrollInfo.metrics.pixels >=
                                  scrollInfo.metrics.maxScrollExtent - 200) {
                            _fetchArticles();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _articles.length + (_hasMore ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            if (index == _articles.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final article = _articles[index];
                            return _ListArticleCard(article: article);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ListArticleCard extends StatelessWidget {
  final ArticleModel article;

  const _ListArticleCard({required this.article});

  Future<void> _incrementViewCount() async {
    try {
      await http.post(Uri.parse('${AppConfig.baseUrlApi}/articles/${article.id}/view'));
    } catch (e) {
      print('Failed to increment view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return GestureDetector(
      onTap: () {
        _incrementViewCount();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArticleDetailScreen(article: article)),
        );
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: isDark 
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                image: article.imageUrl != null 
                  ? DecorationImage(
                      image: AssetImage(article.imageUrl!), // Assume it's local assets for dummy data
                      fit: BoxFit.cover,
                    )
                  : null,
                color: isDark ? Colors.black12 : Colors.grey.shade100,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.category,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.primaryOrange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye_rounded, size: 12, color: colors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${article.viewCount}',
                              style: GoogleFonts.beVietnamPro(
                                color: colors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        article.title,
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy').format(article.createdAt),
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
