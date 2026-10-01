import '../models/story_model.dart';

const StoryModel hareAndTortoiseStory = StoryModel(
  id: 'story_tortoise_rabbit',
  title: 'முயலும் ஆமையும்',
  subtitle: 'முயற்சி திருவினையாக்கும்!',
  coverEmoji: '🐰🐢',
  coverImage: 'assets/images/story_friends.jpg',
  moral: 'பொறுமையும் தொடர் முயற்சியும் எப்போதும் வெற்றி தரும்!',
  pages: [
    // Page 1: Introduction (Only page with the 3 interactive keywords: காடு, முயல், ஆமை)
    StoryPageModel(
      pageNumber: 1,
      characterName: 'காடு',
      emojiIllustration: '🌲🐰 🐢🌿',
      imagePath: 'assets/images/story_forest.jpg',
      text: 'ஒரு காட்டில் முயலும் ஆமையும் வாழ்ந்தன.',
      interactiveWords: [
        StoryInteractiveWord(
          word: 'காட்டில்',
          displayLabel: 'காடு',
          imagePath: 'assets/images/story_forest.jpg',
          emoji: '🌲',
          meaning: 'அழகான காடு (Forest)',
        ),
        StoryInteractiveWord(
          word: 'முயலும்',
          displayLabel: 'முயல்',
          imagePath: 'assets/images/story_rabbit.jpg',
          emoji: '🐰',
          meaning: 'சுட்டி முயல் (Rabbit)',
        ),
        StoryInteractiveWord(
          word: 'ஆமையும்',
          displayLabel: 'ஆமை',
          imagePath: 'assets/images/story_tortoise.jpg',
          emoji: '🐢',
          meaning: 'அன்பான ஆமை (Tortoise)',
        ),
      ],
    ),

    // Page 2: Rabbit runs fast, Tortoise walks slow (Clean text)
    StoryPageModel(
      pageNumber: 2,
      characterName: 'முயலும் ஆமையும்',
      emojiIllustration: '🐰💨 🐢🐾',
      imagePath: 'assets/images/story_friends.jpg',
      text: 'முயல் வேகமாக ஓடும்.\nஆமை மெதுவாக நடக்கும்.',
      interactiveWords: [],
    ),

    // Page 3: Running race starts (Clean text)
    StoryPageModel(
      pageNumber: 3,
      characterName: 'ஓட்டப்பந்தயம்',
      emojiIllustration: '🏁🐰💨 ... 🐢',
      imagePath: 'assets/images/story_race.jpg',
      text: 'இருவரும் ஓட்டப்பந்தயம் வைத்தனர்.\nமுயல் வேகமாக ஓடியது.',
      interactiveWords: [],
    ),

    // Page 4: Rabbit sleeps under tree (Clean text)
    StoryPageModel(
      pageNumber: 4,
      characterName: 'தூங்கும் முயல்',
      emojiIllustration: '🌳😴🐰💤  🐢🐾',
      imagePath: 'assets/images/story_sleeping_rabbit.jpg',
      text: 'முயல் மரத்தடியில் தூங்கிவிட்டது.\nஆமை தொடர்ந்து நடந்தது.',
      interactiveWords: [],
    ),

    // Page 5: Tortoise wins (Clean text)
    StoryPageModel(
      pageNumber: 5,
      characterName: 'வெற்றி!',
      emojiIllustration: '🎉🏆🐢✨ 😲🐰',
      imagePath: 'assets/images/story_victory.jpg',
      text: 'ஆமை முதலில் சென்றது.\nபோட்டியில் வெற்றி பெற்றது!',
      interactiveWords: [],
    ),

    // Page 6: Moral / Realization (Clean text)
    StoryPageModel(
      pageNumber: 6,
      characterName: 'நீதி',
      emojiIllustration: '🌟🤝🐰🐢💖',
      imagePath: 'assets/images/story_friends.jpg',
      text: 'முயல் தன் தவறை உணர்ந்தது.\nவிடாமுயற்சி வெற்றி தரும்!',
      interactiveWords: [],
    ),
  ],
);
