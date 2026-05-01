import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/joined_community_list_widget.dart';
import 'community_discover_screen.dart';
import 'community_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Use addPostFrameCallback to avoid "setState() during build" error
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  Future<void> _loadData() async {
    await context.read<CommunityProvider>().fetchCommunities();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final community = context.watch<CommunityProvider>();
    final joinedCommunities = community.communities.where((c) => c.isMember).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Komunitas',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: colors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.primaryOrange,
        onRefresh: () async {
          await community.fetchCommunities();
        },
        child: JoinedCommunityListWidget(joinedCommunities: joinedCommunities),
      ),
    );
  }
}
