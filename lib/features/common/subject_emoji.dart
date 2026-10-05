/// A friendly picture for each subject code (the three letters at the start of a skill code).
String subjectEmoji(String subjectCode) {
  switch (subjectCode) {
    case 'MAT':
      return '🔢';
    case 'ENG':
      return '📚';
    case 'LNG':
      return '🗣️';
    case 'SCI':
      return '🔬';
    case 'ART':
      return '🎨';
    case 'LIF':
      return '🏠';
    case 'PHY':
      return '🏃';
    case 'SOC':
      return '🌍';
    default:
      return '⭐';
  }
}
