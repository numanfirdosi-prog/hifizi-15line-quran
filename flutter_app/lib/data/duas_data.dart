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
    translationUrdu: 'میں نے ماہِ رمضان کے کل کے روزے کی نیت کی۔',
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
        'اے اللہ! میں نے تیرے ہی لیے روزہ رکھا، تجھ ہی پر ایمان لایا، تجھ ہی پر بھروسہ کیا اور تیرے ہی دیے ہوئے رزق سے افطار کیا۔',
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
        'پیاس چلی گئی، رگیں تر ہو گئیں اور اللہ کے حکم سے ثواب قائم ہو گیا۔',
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
        'اے میرے رب! بخش دے اور رحم فرما، اور تو سب سے بہترین رحم فرمانے والا ہے۔ (۲۳:۱۱۸)',
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
        'میں اپنے رب اللہ سے اپنے تمام گناہوں کی بخشش مانگتا ہوں اور اسی کی بارگاہ میں توبہ کرتا ہوں۔',
  ),
  Dua(
    id: 'ashra-3',
    title: 'Teesre Ashre ki Dua (Nijat)',
    category: 'Ashra',
    tag: 'ASHRA 3 • NIJAT',
    arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
    transliteration: 'Allahumma ajirni minan-nar.',
    translation: 'O Allah, save me from the Fire.',
    translationUrdu: 'اے اللہ! مجھے جہنم کی آگ سے نجات عطا فرما۔',
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
        'اے اللہ! بے شک تو بہت معاف فرمانے والا ہے اور معاف کرنے کو پسند فرماتا ہے، پس مجھے معاف فرما دے۔',
  ),
  Dua(
    id: 'taraweeh',
    title: 'Taraweeh ki Dua (تسبیح تراویح)',
    category: 'Special',
    tag: 'TARAWEEH',
    arabic:
        'سُبْحَانَ ذِي الْمُلْكِ وَالْمَلَكُوتِ، سُبْحَانَ ذِي الْعِزَّةِ وَالْعَظَمَةِ وَالْهَيْبَةِ وَالْقُدْرَةِ وَالْكِبْرِيَاءِ وَالْجَبَرُوتِ، سُبْحَانَ الْمَلِكِ الْحَيِّ الَّذِي لَا يَنَامُ وَلَا يَمُوتُ، سُبُّوحٌ قُدُّوسٌ رَبُّنَا وَرَبُّ الْمَلَائِكَةِ وَالرُّوحِ، لَا إِلٰهَ إِلَّا اللّٰهُ نَسْتَغْفِرُ اللّٰهَ، نَسْأَلُكَ الْجَنَّةَ وَنَعُوذُ بِكَ مِنَ النَّارِ',
    transliteration:
        'Subhana dhil-mulki wal-malakoot, subhana dhil-izzati wal-azamati wal-haybati wal-qudrati wal-kibriyaa\'i wal-jabaroot, subhanal-malikil-hayyil-ladhi la yanamu wa la yamoot, subboohun quddoosun rabbuna wa rabbul-malaa\'ikati war-rooh, la ilaha illallahu nastaghfirullah, nas\'alukal-jannata wa na\'oodhu bika minan-naar.',
    translation:
        'Glory be to the Owner of the earthly and heavenly kingdoms. Glory be to the Possessor of might, grandeur, awe, power, greatness, and majesty. Glory be to the King, the Living One who neither sleeps nor dies. Supreme, Pure, our Lord and the Lord of the angels and the Spirit. There is no deity but Allah; we seek Allah\'s forgiveness, we ask You for Paradise, and we seek Your refuge from the Fire.',
    translationUrdu:
        'پاک ہے وہ (اللہ) جو زمین اور آسمان کی بادشاہی کا مالک ہے، پاک ہے وہ جو عزت، عظمت، ہیبت، قدرت، بڑائی اور غلبے والا ہے۔ پاک ہے وہ زندہ بادشاہ جو نہ سوتا ہے اور نہ مرتا ہے۔ نہایت پاک اور مقدس ہے ہمارا پروردگار اور فرشتوں اور روح کا پروردگار۔ اللہ کے سوا کوئی معبود نہیں، ہم اللہ سے بخشش مانگتے ہیں، ہم تجھ سے جنت کا سوال کرتے ہیں اور جہنم کی آگ سے تیری پناہ چاہتے ہیں۔',
  ),
];
