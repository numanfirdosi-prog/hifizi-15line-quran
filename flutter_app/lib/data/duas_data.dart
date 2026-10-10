class Dua {
  final String id;
  final String title;
  final String category;
  final String tag;
  final String arabic;
  final String transliteration;
  final String translation;
  final String translationUrdu;

  const Dua({
    required this.id,
    required this.title,
    required this.category,
    required this.tag,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.translationUrdu,
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
    translationUrdu:
        'میں ماہِ رمضان کا روزہ کل رکھنے کی نیت کرتا/کرتی ہوں۔',
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
    translationUrdu:
        'اے اللہ! میں نے تیرے لیے روزہ رکھا، تجھ پر ایمان لایا، تجھ پر بھروسا کیا، اور تیرے ہی رزق سے روزہ افطار کرتا/کرتی ہوں۔',
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
    translationUrdu:
        'پیاس بجھ گئی، رگیں تر ہو گئیں، اور اجر ثابت ہو گیا، ان شاء اللہ۔',
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
    translationUrdu:
        'اے میرے رب! بخش دے اور رحم فرما، کیونکہ تو سب سے بہتر رحم کرنے والا ہے۔ (23:118)',
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
    translationUrdu:
        'میں اپنے رب اللہ سے ہر گناہ کی معافی مانگتا/مانگتی ہوں اور اس کی طرف رجوع کرتا/کرتی ہوں۔',
  ),
  Dua(
    id: 'ashra-3',
    title: 'Teesre Ashre ki Dua (Nijat)',
    category: 'Ashra',
    tag: 'ASHRA 3 • NIJAT',
    arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
    transliteration: 'Allahumma ajirni minan-nar.',
    translation: 'O Allah, save me from the Fire.',
    translationUrdu: 'اے اللہ! مجھے آگ سے بچا۔',
  ),
  Dua(
    id: 'qadr',
    title: 'Laylatul Qadr ki Dua',
    category: 'Special',
    tag: 'LAYLATUL QADR',
    arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    transliteration: 'Allahumma innaka afuwwun tuhibbul-afwa fa\'fu anni.',
    translation: 'O Allah, You are Pardoning and love to pardon, so pardon me.',
    translationUrdu:
        'اے اللہ! بے شک تو بہت معاف کرنے والا ہے اور معاف کرنا پسند کرتا ہے، پس مجھے معاف فرما۔',
  ),
  Dua(
    id: 'taraweeh',
    title: 'Taraweeh ki Dua',
    category: 'Special',
    tag: 'TARAWEEH',
    arabic:
        'سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ سُبْحَانَ ذِي الْعِزَّةِ وَالْعَظَمَةِ وَالْهَيْبَةِ وَالْقُدْرَةِ وَالْكِبْرِيَاءِ وَالْجَبَرُوتِ سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوتُ سُبُّوحٌ قُدُّوسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوحِ اللَّهُمَّ أَجِرْنَا مِنَ النَّارِ يَا مُجِيرُ يَا مُجِيرُ يَا مُجِيرُ',
    transliteration:
        'Subhana zil-mulki wal-malakut, subhana zil-izzati wal-azamati wal-haybati wal-qudrati wal-kibriyā’i wal-jabarut. Subhanal-malikil-hayyil-lazi la yanamu wa la yamut. Subbuhun quddusun rabbuna wa rabbul-mala’ikati war-ruh. Allahumma ajirna minan-nar, ya Mujiru ya Mujiru ya Mujir.',
    translation:
        'Glory be to the Owner of the Kingdom and the Dominion; glory be to the Owner of Honour, Greatness, Awe, Power, Pride and Might. Glory be to the Living King who neither sleeps nor dies. Most Glorious, Most Holy — our Lord and the Lord of the angels and the Spirit. O Allah, save us from the Fire; O Giver of Refuge, O Giver of Refuge, O Giver of Refuge.',
    translationUrdu:
        'پاک ہے وہ جو بادشاہت اور (آسمانی) سلطنت کا مالک ہے؛ پاک ہے وہ جو عزت، عظمت، ہیبت، قدرت، کبریائی اور جبروت کا مالک ہے۔ پاک ہے وہ زندہ بادشاہ جو نہ سوتا ہے نہ مرتا ہے۔ نہایت پاک، نہایت مقدس — ہمارا رب اور فرشتوں اور روح کا رب۔ اے اللہ! ہمیں آگ سے پناہ دے؛ اے پناہ دینے والے، اے پناہ دینے والے، اے پناہ دینے والے۔',
  ),
];
