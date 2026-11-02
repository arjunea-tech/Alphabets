import '../models/story_model.dart';

const StoryModel hareAndTortoiseStory = StoryModel(
  id: 'story_tortoise_rabbit',
  title: 'The Hare and the Tortoise',
  subtitle: 'Slow and steady wins the race!',
  coverEmoji: '🐰🐢',
  coverImage: 'assets/images/story_friends.jpg',
  moral: 'Patience and steady effort always triumph in the end!',
  pages: [
    // Page 1
    StoryPageModel(
      pageNumber: 1,
      characterName: 'Forest Friends',
      emojiIllustration: '🌲🐰 🐢🌿',
      imagePath: 'assets/images/story_forest.jpg',
      text: 'Once upon a time in a sunny green forest, a boastful Hare and a gentle Tortoise lived as neighbors.',
      interactiveWords: [
        StoryInteractiveWord(
          word: 'forest',
          displayLabel: 'Forest',
          imagePath: 'assets/images/story_forest.jpg',
          emoji: '🌲',
          meaning: 'A large area covered with trees and plants',
        ),
        StoryInteractiveWord(
          word: 'Hare',
          displayLabel: 'Hare',
          imagePath: 'assets/images/story_rabbit.jpg',
          emoji: '🐰',
          meaning: 'A fast-running animal with long ears',
        ),
        StoryInteractiveWord(
          word: 'Tortoise',
          displayLabel: 'Tortoise',
          imagePath: 'assets/images/story_tortoise.jpg',
          emoji: '🐢',
          meaning: 'A slow-moving animal with a hard shell',
        ),
      ],
    ),

    // Page 2
    StoryPageModel(
      pageNumber: 2,
      characterName: 'The Boastful Hare',
      emojiIllustration: '🐰💨 🐢🐾',
      imagePath: 'assets/images/story_friends.jpg',
      text: 'The Hare always bragged: "I am the fastest runner in the world!" The quiet Tortoise just smiled and kept walking.',
      interactiveWords: [],
    ),

    // Page 3
    StoryPageModel(
      pageNumber: 3,
      characterName: 'The Great Race',
      emojiIllustration: '🏁🐰💨 ... 🐢',
      imagePath: 'assets/images/story_race.jpg',
      text: 'They decided to have a big race to the tall oak tree! The Hare dashed forward like the wind.',
      interactiveWords: [],
    ),

    // Page 4
    StoryPageModel(
      pageNumber: 4,
      characterName: 'Sleeping Hare',
      emojiIllustration: '🌳😴🐰💤  🐢🐾',
      imagePath: 'assets/images/story_sleeping_rabbit.jpg',
      text: 'Looking back and seeing the Tortoise far behind, the Hare thought: "I have plenty of time. Let me take a nice nap under this tree!"',
      interactiveWords: [],
    ),

    // Page 5
    StoryPageModel(
      pageNumber: 5,
      characterName: 'Steady Walking',
      emojiIllustration: '🎉🏆🐢✨ 😲🐰',
      imagePath: 'assets/images/story_victory.jpg',
      text: 'The Tortoise never stopped walking. Step by step, plodding along with grit and patience.',
      interactiveWords: [],
    ),

    // Page 6
    StoryPageModel(
      pageNumber: 6,
      characterName: 'Victory!',
      emojiIllustration: '🌟🤝🐰🐢💖',
      imagePath: 'assets/images/story_friends.jpg',
      text: 'The Tortoise crossed the finish line first! When the Hare woke up, it was too late. Slow and steady wins the race!',
      interactiveWords: [],
    ),
  ],
);
