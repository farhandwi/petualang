import '../models/gamification_models.dart';

class GamificationDummyData {
  static UserGamificationProfile get level1Profile => UserGamificationProfile(
        level: 1,
        currentExp: 450,
        nextLevelExp: 1000,
        totalActivities: 1,
        totalCommunities: 0,
        unlockedAchievements: 1,
        activities: [
          GamificationActivity(
              id: 'a1',
              title: 'Pendakian',
              iconAsset: 'terrain',
              completions: 1,
              description: 'Gunung Gede'),
          GamificationActivity(
              id: 'a2',
              title: 'Lari Trail',
              iconAsset: 'directions_run',
              completions: 0,
              description: 'Belum ada data'),
        ],
        communities: [],
        achievements: [
          Achievement(
              id: 'ach1',
              title: 'Langkah Pertama',
              description: 'Menyelesaikan 1 aktifitas perdana.',
              activityType: 'General',
              activityId: 'a1',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=L+P&background=random&format=png'),
          Achievement(
              id: 'ach2',
              title: 'Sang Sherpa',
              description: 'Menyelesaikan 20 pendakian.',
              activityType: 'Pendakian',
              activityId: 'a1',
              isUnlocked: false,
              imageUrl: 'https://ui-avatars.com/api/?name=S+S&background=random&format=png'),
        ],
      );

  static UserGamificationProfile get level3Profile => UserGamificationProfile(
        level: 3,
        currentExp: 2400,
        nextLevelExp: 3500,
        totalActivities: 8,
        totalCommunities: 2,
        unlockedAchievements: 4,
        activities: [
          GamificationActivity(
              id: 'a1',
              title: 'Pendakian',
              iconAsset: 'terrain',
              completions: 3,
              description: 'Sindoro, Sumbing, Merbabu'),
          GamificationActivity(
              id: 'a2',
              title: 'Open Trip',
              iconAsset: 'groups',
              completions: 2,
              description: 'Pahawang, Bromo'),
          GamificationActivity(
              id: 'a3',
              title: 'Berkemah',
              iconAsset: 'holiday_village',
              completions: 3,
              description: 'Ranca Upas, dll'),
        ],
        communities: [
          Community(
              id: 'c1',
              name: 'Pendaki Amatir',
              imageUrl: 'https://picsum.photos/200?random=1',
              activityId: 'a1',
              memberCount: 1540),
          Community(
              id: 'c2',
              name: 'Campervan Indo',
              imageUrl: 'https://picsum.photos/200?random=2',
              activityId: 'a3',
              memberCount: 890),
        ],
        achievements: [
          Achievement(
              id: 'ach1',
              title: 'Penakluk Awan',
              description: 'Menginjakkan kaki > 3.000 mdpl.',
              activityType: 'Pendakian',
              activityId: 'a1',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=P+A&background=random&format=png'),
          Achievement(
              id: 'ach2',
              title: 'Penguasa Malam',
              description: 'Tidur di alam bebas 30 malam.',
              activityType: 'Berkemah',
              activityId: 'a3',
              isUnlocked: false,
              imageUrl: 'https://ui-avatars.com/api/?name=P+M&background=random&format=png'),
          Achievement(
              id: 'ach3',
              title: 'Jiwa Api Unggun',
              description: 'Mendirikan tenda di lanskap berbeda.',
              activityType: 'Berkemah',
              activityId: 'a3',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=J+A&background=random&format=png'),
        ],
      );

  static UserGamificationProfile get level5Profile => UserGamificationProfile(
        level: 5,
        currentExp: 6800,
        nextLevelExp: 8000,
        totalActivities: 24,
        totalCommunities: 4,
        unlockedAchievements: 9,
        activities: [
          GamificationActivity(
              id: 'a1',
              title: 'Pendakian',
              iconAsset: 'terrain',
              completions: 12,
              description: 'Rinjani, Semeru, dll.'),
          GamificationActivity(
              id: 'a2',
              title: 'Lari Trail',
              iconAsset: 'directions_run',
              completions: 5,
              description: 'Sikunir, Dieng'),
          GamificationActivity(
              id: 'a3',
              title: 'Sepeda Gunung',
              iconAsset: 'pedal_bike',
              completions: 7,
              description: 'Cikole Downhill'),
        ],
        communities: [
          Community(
              id: 'c1',
              name: 'Sindoro-Sumbing Hiker',
              imageUrl: 'https://picsum.photos/200?random=3',
              activityId: 'a1',
              memberCount: 8500),
          Community(
              id: 'c2',
              name: 'Trail Runners BDG',
              imageUrl: 'https://picsum.photos/200?random=4',
              activityId: 'a2',
              memberCount: 3200),
          Community(
              id: 'c3',
              name: 'MTB Enduro ID',
              imageUrl: 'https://picsum.photos/200?random=5',
              activityId: 'a3',
              memberCount: 1100),
        ],
        achievements: [
          Achievement(
              id: 'ach1',
              title: 'Kijang Hutan',
              description: 'Pace tercepat di jalur pinus.',
              activityType: 'Lari Trail',
              activityId: 'a2',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=K+H&background=random&format=png'),
          Achievement(
              id: 'ach2',
              title: 'Roda Gila',
              description: 'Downhill 10km tanpa insiden.',
              activityType: 'Sepeda Gunung',
              activityId: 'a3',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=R+G&background=random&format=png'),
          Achievement(
              id: 'ach3',
              title: 'Magnet Tongkrongan',
              description: 'Join 10 open trip berbeda.',
              activityType: 'Open Trip',
              activityId: 'a4',
              isUnlocked: false,
              imageUrl: 'https://ui-avatars.com/api/?name=M+T&background=random&format=png'),
        ],
      );

  static UserGamificationProfile get maxLevelProfile => UserGamificationProfile(
        level: 50,
        currentExp: 99999,
        nextLevelExp: 99999,
        totalActivities: 342,
        totalCommunities: 15,
        unlockedAchievements: 45,
        activities: [
          GamificationActivity(
              id: 'a1',
              title: 'Pendakian',
              iconAsset: 'terrain',
              completions: 150,
              description: 'Seluruh puncak nusantara'),
          GamificationActivity(
              id: 'a2',
              title: 'Lari Trail',
              iconAsset: 'directions_run',
              completions: 48,
              description: 'Ultra-marathon Finisher'),
          GamificationActivity(
              id: 'a3',
              title: 'Panjat Tebing',
              iconAsset: 'filter_hdr',
              completions: 35,
              description: 'Tebing Citatah, dll'),
          GamificationActivity(
              id: 'a4',
              title: 'Open Trip',
              iconAsset: 'groups',
              completions: 109,
              description: 'Senior Guide/Participant'),
        ],
        communities: [
          Community(
              id: 'c1',
              name: 'Eiger Adventure Club',
              imageUrl: 'https://picsum.photos/200?random=6',
              activityId: 'a1',
              memberCount: 50000),
          Community(
              id: 'c2',
              name: '7 Summits ID',
              imageUrl: 'https://picsum.photos/200?random=7',
              activityId: 'a1',
              memberCount: 1500),
        ],
        achievements: [
          Achievement(
              id: 'ach1',
              title: 'Jejak Abadi',
              description: 'Menaklukkan 7 puncak tertinggi.',
              activityType: 'Pendakian',
              activityId: 'a1',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=J+A&background=random&format=png'),
          Achievement(
              id: 'ach2',
              title: 'Kilat Menyambar',
              description: 'Menyelesaikan ultra-marathon.',
              activityType: 'Lari Trail',
              activityId: 'a2',
              isUnlocked: true,
              imageUrl: 'https://ui-avatars.com/api/?name=K+M&background=random&format=png'),
        ],
      );
}
