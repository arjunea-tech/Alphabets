/// Definition and catalogue of rich character/mascot avatars available across AGARAM app
class AppAvatar {
  final int index;
  final String label;
  final String assetPath;

  const AppAvatar({
    required this.index,
    required this.label,
    required this.assetPath,
  });

  static const List<AppAvatar> list = [
    AppAvatar(
      index: 0,
      label: 'Little Boy',
      assetPath: 'assets/images/welcome.png',
    ),
    AppAvatar(
      index: 1,
      label: 'Little Girl',
      assetPath: 'assets/images/mascot_girl.png',
    ),
    AppAvatar(
      index: 2,
      label: 'Writing Boy',
      assetPath: 'assets/images/writing.png',
    ),
    AppAvatar(
      index: 3,
      label: 'Story Boy',
      assetPath: 'assets/images/story.png',
    ),
    AppAvatar(
      index: 4,
      label: 'Bunny',
      assetPath: 'assets/images/story_rabbit.jpg',
    ),
    AppAvatar(
      index: 5,
      label: 'Tortoise',
      assetPath: 'assets/images/story_tortoise.jpg',
    ),
  ];

  static String getAssetPath(int index) {
    if (index >= 0 && index < list.length) {
      return list[index].assetPath;
    }
    return list[0].assetPath;
  }

  static int getIndex(String assetPath) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].assetPath == assetPath) return i;
    }
    return 0;
  }
}
