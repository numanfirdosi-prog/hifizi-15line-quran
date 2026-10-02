class Faq {
  final String q;
  final String a;

  const Faq(this.q, this.a);
}

const List<Faq> faqs = [
  Faq(
    'Kya app offline chalti hai?',
    'Ji haan. Quran ke tamam 611 pages (15-line Hifzi mushaf) download ke baad bina internet ke parhe ja sakte hain. Surah index, juz index, bookmarks aur aapki settings bhi offline kaam karti hain. Audio recitation aur page images ko pehli baar dekhne/sunne ke liye internet chahiye hota hai.',
  ),
  Faq(
    'Namaz ke auqaat kaise calculate hote hain?',
    'Namaz ke auqaat aapke GPS location se on-device calculate hote hain. Calculation method, Fajr/Isha angles aur asr juristic method Settings > Prayer Times me badle ja sakte hain (default: Muslim World League). Azan ke liye notification permission zaroori hai.',
  ),
  Faq(
    'Qiblah compass ko kaise calibrate karun?',
    'Settings > Qiblah me calibration slider hai. Apne phone ko flat satah par rakhein aur phone ko figure-8 (8 ki shakal) me 2-3 baar ghumayein taake magnetometer calibrate ho jaye. Phir slider se needle ko apne maloom Qiblah se match karke fine-tune karein.',
  ),
  Faq(
    'Backup & Restore kaise kaam karta hai?',
    'Settings > Backup me aap apne bookmarks, last-read position, preferences aur namaz settings ka backup file bana sakte hain. Ye file aapke phone par save hoti hai — ise naye phone par Restore se wapas la sakte hain. Koi account ya cloud login nahi chahiye.',
  ),
  Faq(
    'Audio recitation me kitna data lagta hai?',
    'Audio recitation streaming par chalti hai, is liye mobile data par sunne me data kharch hota hai. Download Center se surah ya juz ka audio pehle Wi-Fi par download kar lein, phir offline sun sakte hain.',
  ),
  Faq(
    'Mere bookmarks private hain?',
    '100% private. Tamam bookmarks, last-read pages aur preferences sirf aapke device par save hote hain. Koi account, server upload ya analytics nahi hai — aapka data aapke phone se bahar nahi jata.',
  ),
  Faq(
    'Ayah repeat / loop feature kaise use karun?',
    'Audio Studio me kisi bhi ayah par repeat mode on karke us ayah ko baar-baar suna ja sakta hai — hifz (memorization) ke liye bohot mufeed hai. Aap surah range bhi select karke loop me laga sakte hain.',
  ),
  Faq(
    'Themes aur display options kya hain?',
    'Preferences me Light, Dark aur Sepia themes ke saath Arabic font size, translation on/off aur transliteration display ke options hain. Page view me 15-line Hifzi layout authentic mushaf jaisa dikhta hai.',
  ),
  Faq(
    'Download Center kis liye hai?',
    'Download Center se aap poore Quran ke page images, audio recitations (12 qaris) aur translations ko ek saath download karke offline rakh sakte hain — safar me ya kam network wali jagah par behtareen.',
  ),
  Faq(
    'Koi masla (bug) ho to kahan report karun?',
    'About screen par "Report an Issue" option hai. Wahan app version, device model aur masle ki tafseel likhein taake hum jald fix kar saken. Aapka feedback hamare liye qeemti hai.',
  ),
];

const String aboutText =
    'Nur-ul-Quran — 15-line South-Asian Hifzi mushaf ka digital tajurba. '
    'Tamam 611 pages authentic Hifzi layout me, 114 surahs ka mukammal index, 30 ajza, '
    'talash (search), 12 qaris ki audio recitations, bookmarks, aur reader study tools. '
    'Iske ilawa namaz ke auqaat azan ke saath, Qiblah compass, Ramzan duas aur daily Ayah of the Day. '
    'Version 1.0.1.';

const String privacyText =
    'Nur-ul-Quran 100% on-device app hai. Koi account nahi, koi tracking ya analytics nahi. '
    'Aapki location sirf aapke phone par namaz ke auqaat aur Qiblah direction calculate karne ke liye istemal hoti hai — '
    'yeh kabhi kisi server ko nahi bheji jati. Quran page images aur audio sirf tab network se load hote hain jab aap unhe dekhte ya sunte hain. '
    'Bookmarks, preferences aur backups sab aapke device par mehfooz rehte hain.';

const List<String> ramadanReflections = [
  'Ramzan ka pehla din: niyyat ko khalis karo — rozah sirf bhook nahi, dil ki safai hai.',
  'Har iftar par shukr: jis rizq se rozah kholte ho, woh Allah ka inaam hai — Alhamdulillah kaho.',
  'Taraweeh me Quran suno: samajh kar sunne se dil naram hota hai aur imaan taza hota hai.',
  'Pehla ashra rehmat ka hai — apne liye aur poori ummat ke liye rehmat ki dua maango.',
  'Dusra ashra maghfirat ka hai — Astaghfar ko apni zuban ka wazeefa bana lo.',
  'Aakhri ashra nijat ka hai — dozakh se panah maango aur nekiyon me tez raftar pakdo.',
  'Laylatul Qadr hazaar mahino se behtar hai — taaq raaton me ibaadat me lag jao.',
  'Zakat aur sadqa: Ramzan me diya hua sadqa dil ko paak karta hai aur maal me barkat lata hai.',
  'Akhlak sudharo: rozah gusse par qaboo sikhata hai — narmi ikhtiyar karo.',
  'Aakhri din: Ramzan ja raha hai, magar uski adaat — namaz, Quran, dua — saal bhar saath rakho.',
];
