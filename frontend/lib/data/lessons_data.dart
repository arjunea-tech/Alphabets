import '../models/lesson_model.dart';
import '../theme/app_colors.dart';

const List<LessonCategoryModel> lessonCategoriesList = [
  LessonCategoryModel(
    id: 'lesson_alphabets',
    title: 'English Alphabets',
    subtitle: 'Learn 26 Letters from A to Z with Fun',
    countText: '26 Letters',
    buttonText: 'Start Learning',
    iconEmoji: '🔤',
    gradientColors: AppColors.blueGradient,
    routeName: '/alphabets',
  ),
  LessonCategoryModel(
    id: 'lesson_vowels',
    title: 'Vowels',
    subtitle: 'A, E, I, O, U - Foundation of English Words',
    countText: '5 Vowels',
    buttonText: 'Learn Vowels',
    iconEmoji: '🍎',
    gradientColors: AppColors.pinkGradient,
    routeName: '/vowels',
  ),
  LessonCategoryModel(
    id: 'lesson_consonants',
    title: 'Consonants',
    subtitle: '21 Consonant Letters with Fun Examples',
    countText: '21 Consonants',
    buttonText: 'Learn Consonants',
    iconEmoji: '🎡',
    gradientColors: AppColors.greenGradient,
    routeName: '/consonants',
  ),
  LessonCategoryModel(
    id: 'lesson_reading',
    title: 'Reading Stories',
    subtitle: 'Engaging illustrated stories for kids',
    countText: 'Moral Stories',
    buttonText: 'Read Stories',
    iconEmoji: '📚',
    gradientColors: AppColors.orangeGradient,
    routeName: '/reading',
  ),
];
