import 'quran_data.dart';

class JuzInfo {
  final int number;
  final String nameAr;
  final String nameTr;
  final int startPage;
  final String startVerse;
  final String endVerse;
  final String surahRange;
  const JuzInfo({
    required this.number,
    required this.nameAr,
    required this.nameTr,
    required this.startPage,
    required this.startVerse,
    required this.endVerse,
    required this.surahRange,
  });
}

const List<JuzInfo> juzList = [
  JuzInfo(
    number: 1,
    nameAr: 'آلم',
    nameTr: 'Alif Lam Mim',
    startPage: 2,
    startVerse: '1:1',
    endVerse: '2:141',
    surahRange: 'Al-Fatihah 1 - Al-Baqarah 141',
  ),
  JuzInfo(
    number: 2,
    nameAr: 'سيقول',
    nameTr: 'Sayaqul',
    startPage: 23,
    startVerse: '2:142',
    endVerse: '2:252',
    surahRange: 'Al-Baqarah 142 - Al-Baqarah 252',
  ),
  JuzInfo(
    number: 3,
    nameAr: 'تلك الرسل',
    nameTr: 'Tilkar Rusul',
    startPage: 43,
    startVerse: '2:253',
    endVerse: '3:92',
    surahRange: 'Al-Baqarah 253 - Ali Imran 92',
  ),
  JuzInfo(
    number: 4,
    nameAr: 'لن تنالوا',
    nameTr: 'Lan Tanalu',
    startPage: 63,
    startVerse: '3:93',
    endVerse: '4:23',
    surahRange: 'Ali Imran 93 - An-Nisa 23',
  ),
  JuzInfo(
    number: 5,
    nameAr: 'والمحصنات',
    nameTr: 'Wal Mohsanat',
    startPage: 83,
    startVerse: '4:24',
    endVerse: '4:147',
    surahRange: 'An-Nisa 24 - An-Nisa 147',
  ),
  JuzInfo(
    number: 6,
    nameAr: 'لا يحب الله',
    nameTr: 'La Yuhibbullah',
    startPage: 103,
    startVerse: '4:148',
    endVerse: '5:81',
    surahRange: 'An-Nisa 148 - Al-Ma’idah 81',
  ),
  JuzInfo(
    number: 7,
    nameAr: 'وإذا سمعوا',
    nameTr: 'Wa Iza Samiu',
    startPage: 122,
    startVerse: '5:82',
    endVerse: '6:110',
    surahRange: 'Al-Ma’idah 82 - Al-An’am 110',
  ),
  JuzInfo(
    number: 8,
    nameAr: 'ولو أننا',
    nameTr: 'Wa Lau Annana',
    startPage: 143,
    startVerse: '6:111',
    endVerse: '7:87',
    surahRange: 'Al-An’am 111 - Al-A’raf 87',
  ),
  JuzInfo(
    number: 9,
    nameAr: 'قال الملأ',
    nameTr: 'Qalal Mala',
    startPage: 163,
    startVerse: '7:88',
    endVerse: '8:40',
    surahRange: 'Al-A’raf 88 - Al-Anfal 40',
  ),
  JuzInfo(
    number: 10,
    nameAr: 'واعلموا',
    nameTr: 'Walamu',
    startPage: 183,
    startVerse: '8:41',
    endVerse: '9:92',
    surahRange: 'Al-Anfal 41 - At-Tawbah 92',
  ),
  JuzInfo(
    number: 11,
    nameAr: 'يعتذرون',
    nameTr: 'Yatazirun',
    startPage: 202,
    startVerse: '9:93',
    endVerse: '11:5',
    surahRange: 'At-Tawbah 93 - Hud 5',
  ),
  JuzInfo(
    number: 12,
    nameAr: 'وما من دابة',
    nameTr: 'Wa Ma Min Dabbah',
    startPage: 223,
    startVerse: '11:6',
    endVerse: '12:52',
    surahRange: 'Hud 6 - Yusuf 52',
  ),
  JuzInfo(
    number: 13,
    nameAr: 'وما أبرئ',
    nameTr: 'Wa Ma Ubarri',
    startPage: 243,
    startVerse: '12:53',
    endVerse: '14:52',
    surahRange: 'Yusuf 53 - Ibrahim 52',
  ),
  JuzInfo(
    number: 14,
    nameAr: 'ربما',
    nameTr: 'Rubama',
    startPage: 262,
    startVerse: '15:1',
    endVerse: '16:128',
    surahRange: 'Al-Hijr 1 - An-Nahl 128',
  ),
  JuzInfo(
    number: 15,
    nameAr: 'سبحان الذي',
    nameTr: 'Subhanallazi',
    startPage: 283,
    startVerse: '17:1',
    endVerse: '18:74',
    surahRange: 'Al-Isra 1 - Al-Kahf 74',
  ),
  JuzInfo(
    number: 16,
    nameAr: 'قال ألم',
    nameTr: 'Qal Alam',
    startPage: 303,
    startVerse: '18:75',
    endVerse: '20:135',
    surahRange: 'Al-Kahf 75 - Ta-Ha 135',
  ),
  JuzInfo(
    number: 17,
    nameAr: 'اقترب للناس',
    nameTr: 'Iqtaraba Linnas',
    startPage: 323,
    startVerse: '21:1',
    endVerse: '22:78',
    surahRange: 'Al-Anbiya 1 - Al-Hajj 78',
  ),
  JuzInfo(
    number: 18,
    nameAr: 'قد أفلح',
    nameTr: 'Qad Aflaha',
    startPage: 343,
    startVerse: '23:1',
    endVerse: '25:20',
    surahRange: 'Al-Mu’minun 1 - Al-Furqan 20',
  ),
  JuzInfo(
    number: 19,
    nameAr: 'وقال الذين',
    nameTr: 'Wa Qalallazina',
    startPage: 363,
    startVerse: '25:21',
    endVerse: '27:55',
    surahRange: 'Al-Furqan 21 - An-Naml 55',
  ),
  JuzInfo(
    number: 20,
    nameAr: 'أمن خلق',
    nameTr: 'Amman Khalaq',
    startPage: 382,
    startVerse: '27:56',
    endVerse: '29:45',
    surahRange: 'An-Naml 56 - Al-Ankabut 45',
  ),
  JuzInfo(
    number: 21,
    nameAr: 'اتل ما أوحي',
    nameTr: 'Utlu Ma Uhiya',
    startPage: 403,
    startVerse: '29:46',
    endVerse: '33:30',
    surahRange: 'Al-Ankabut 46 - Al-Ahzab 30',
  ),
  JuzInfo(
    number: 22,
    nameAr: 'ومن يقنت',
    nameTr: 'Wa Man Yaqnut',
    startPage: 423,
    startVerse: '33:31',
    endVerse: '36:27',
    surahRange: 'Al-Ahzab 31 - Ya-Sin 27',
  ),
  JuzInfo(
    number: 23,
    nameAr: 'وما لي',
    nameTr: 'Wa Ma Liya',
    startPage: 443,
    startVerse: '36:28',
    endVerse: '39:31',
    surahRange: 'Ya-Sin 28 - Az-Zumar 31',
  ),
  JuzInfo(
    number: 24,
    nameAr: 'فمن أظلم',
    nameTr: 'Faman Azlam',
    startPage: 463,
    startVerse: '39:32',
    endVerse: '41:46',
    surahRange: 'Az-Zumar 32 - Fussilat 46',
  ),
  JuzInfo(
    number: 25,
    nameAr: 'إليه يرد',
    nameTr: 'Ilaihi Yuraddu',
    startPage: 483,
    startVerse: '41:47',
    endVerse: '45:37',
    surahRange: 'Fussilat 47 - Al-Jathiyah 37',
  ),
  JuzInfo(
    number: 26,
    nameAr: 'حم',
    nameTr: 'Ha Mim',
    startPage: 503,
    startVerse: '46:1',
    endVerse: '51:30',
    surahRange: 'Al-Ahqaf 1 - Adh-Dhariyat 30',
  ),
  JuzInfo(
    number: 27,
    nameAr: 'قال فما خطبكم',
    nameTr: 'Qala Fama Khatbukum',
    startPage: 523,
    startVerse: '51:31',
    endVerse: '57:29',
    surahRange: 'Adh-Dhariyat 31 - Al-Hadid 29',
  ),
  JuzInfo(
    number: 28,
    nameAr: 'قد سمع الله',
    nameTr: 'Qad Samiallah',
    startPage: 543,
    startVerse: '58:1',
    endVerse: '66:12',
    surahRange: 'Al-Mujadila 1 - At-Tahrim 12',
  ),
  JuzInfo(
    number: 29,
    nameAr: 'تبارك الذي',
    nameTr: 'Tabarakallazi',
    startPage: 563,
    startVerse: '67:1',
    endVerse: '77:50',
    surahRange: 'Al-Mulk 1 - Al-Mursalat 50',
  ),
  JuzInfo(
    number: 30,
    nameAr: 'عم',
    nameTr: 'Amma',
    startPage: 587,
    startVerse: '78:1',
    endVerse: '114:6',
    surahRange: 'An-Naba 1 - An-Nas 6',
  ),
];

/// Returns the juz number containing [page] (1..611).
int juzForPage(int page) {
  var result = 1;
  for (final j in juzList) {
    if (page >= j.startPage) {
      result = j.number;
    } else {
      break;
    }
  }
  return result;
}

/// Khatm Planner: day N (1..30) covers Juz N.
/// Returns (startPage, endPage); day 30 ends at the last mushaf page.
(int, int) khatmDayPages(int day) {
  assert(day >= 1 && day <= 30);
  final start = juzList[day - 1].startPage;
  final end = day < 30 ? juzList[day].startPage - 1 : totalPagesInMushaf;
  return (start, end);
}
