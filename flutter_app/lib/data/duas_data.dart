class Dua {
  final String id;
  final String title;
  final String category;
  final String tag;
  final String arabic;
  final String transliteration;
  final String translation;

  const Dua({
    required this.id,
    required this.title,
    required this.category,
    required this.tag,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

const List<Dua> duas = [
  Dua(
    id: 'sehri',
    title: 'Sehri Ki Dua (Fasting Intention)',
    category: 'Sehri & Iftar',
    tag: 'SEHRI / SUHOOR',
    arabic: 'وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ',
    transliteration: 'Wa bisawmi ghadin nawaytu min shahri Ramadan.',
    translation: 'I intend to keep the fast tomorrow for the month of Ramadan.',
  ),
  Dua(
    id: 'iftar',
    title: 'Iftar Ki Dua (Breaking the Fast)',
    category: 'Sehri & Iftar',
    tag: 'IFTAR TIME',
    arabic:
        'اللَّهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
    transliteration:
        'Allahumma inni laka sumtu wa bika aamantu wa alayka tawakkaltu wa ala rizqika aftartu.',
    translation:
        'O Allah, I fasted for You, I believe in You, I trust in You, and with Your sustenance I break my fast.',
  ),
  Dua(
    id: 'iftar-after',
    title: 'Iftar ke Baad ki Dua',
    category: 'Sehri & Iftar',
    tag: 'AFTER IFTAR',
    arabic:
        'ذَهَبَ الظَّمَأُ وَابْتَلَّتِ الْعُرُوقُ وَثَبَتَ الأَجْرُ إِنْ شَاءَ اللَّهُ',
    transliteration:
        'Dhahabaz-zama\'u wabtallatil-uruqu wa thabatal-ajru in sha Allah.',
    translation:
        'The thirst is gone, the veins are moistened, and the reward is confirmed, if Allah wills.',
  ),
  Dua(
    id: 'ashra-1',
    title: 'Pehle Ashre ki Dua (Rehmat)',
    category: 'Ashra',
    tag: 'ASHRA 1 • REHMAT',
    arabic: 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
    transliteration: 'Rabbighfir warham wa anta khayrur-rahimeen.',
    translation:
        'My Lord, forgive and have mercy, for You are the best of the merciful. (23:118)',
  ),
  Dua(
    id: 'ashra-2',
    title: 'Dusre Ashre ki Dua (Maghfirat)',
    category: 'Ashra',
    tag: 'ASHRA 2 • MAGHFIRAT',
    arabic: 'أَسْتَغْفِرُ اللَّهَ رَبِّي مِنْ كُلِّ ذَنْبٍ وَأَتُوبُ إِلَيْهِ',
    transliteration: 'Astaghfirullaha rabbi min kulli dhanbin wa atubu ilayh.',
    translation:
        'I seek forgiveness from Allah my Lord for every sin, and I turn to Him in repentance.',
  ),
  Dua(
    id: 'ashra-3',
    title: 'Teesre Ashre ki Dua (Nijat)',
    category: 'Ashra',
    tag: 'ASHRA 3 • NIJAT',
    arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
    transliteration: 'Allahumma ajirni minan-nar.',
    translation: 'O Allah, save me from the Fire.',
  ),
  Dua(
    id: 'qadr',
    title: 'Laylatul Qadr ki Dua',
    category: 'Special',
    tag: 'LAYLATUL QADR',
    arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    transliteration: 'Allahumma innaka afuwwun tuhibbul-afwa fa\'fu anni.',
    translation: 'O Allah, You are Pardoning and love to pardon, so pardon me.',
  ),
  Dua(
    id: 'taraweeh',
    title: 'Taraweeh ki Dua',
    category: 'Special',
    tag: 'TARAWEEH',
    arabic:
        'سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ سُبْحَانَ ذِي الْعِزَّةِ وَالْعَظَمَةِ',
    transliteration:
        'Subhana zil-mulki wal-malakut, subhana zil-izzati wal-azamah.',
    translation:
        'Glory be to the Owner of the Kingdom and Dominion, glory be to the Owner of Honour and Greatness.',
  ),
];
