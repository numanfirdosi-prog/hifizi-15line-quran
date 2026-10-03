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

const String aboutIntro =
    'Nur-ul-Quran — 15-line South-Asian Hifzi mushaf ka digital tajurba. '
    'Tamam 611 pages authentic Hifzi layout me, jaisa aap printed mushaf me parhte hain. '
    'Ye app tilawat, hifz aur samajhne ke liye banayi gayi hai — bila zaroorat ke features ke baghair, '
    'saaf aur pursukoon reading experience ke saath.';

const String aboutFeatures =
    '• 611-page 15-line Hifzi mushaf (page-turn aur scroll dono modes)\n'
    '• 114 surahs ka mukammal index, 30 ajza, aur full-text search (Arabic + English)\n'
    '• Har ayah par Urdu tarjuma — Kanzul Iman (Imam Ahmad Raza Khan)\n'
    '• 12 qaris ki audio recitations — surah suniye ya ayah-by-ayah, online ya download karke offline\n'
    '• Ayah par tap karke tilawat, musalsal ayah-by-ayah playback aur repeat\n'
    '• Namaz ke auqaat (GPS se), azan alarms, Qiblah compass\n'
    '• Khatm planner (30 din), bookmarks, reading progress, backup & restore\n'
    '• Ramzan duas, daily Ayah of the Day, aur kai themes (Night, Emerald, Parchment)';

const String aboutSources =
    '• Mushaf pages: 15-line Hifzi layout images\n'
    '• Quran text: Tanzil (Uthmani script)\n'
    '• Urdu tarjuma: Kanzul Iman — Imam Ahmad Raza Khan Barelvi (Tanzil)\n'
    '• English tarjuma: Saheeh International\n'
    '• Audio: mp3quran.net (surah recitations), everyayah.com (ayah recitations)\n'
    '• Namaz timings: on-device astronomical calculation';

const String aboutLicenses =
    'Ye app Flutter (BSD 3-Clause) se banayi gayi hai. Darj zail open-source packages istemal hue hain: '
    'just_audio, audio_service, audio_session, provider, shared_preferences, path_provider, '
    'google_fonts, share_plus, url_launcher, cached_network_image, timezone, android_alarm_manager_plus, '
    'geolocator, flutter_compass, speech_to_text, app_links, flutter_local_notifications.\n\n'
    'Fonts: Gulzar aur Amiri Quran (SIL Open Font License 1.1) app me bundled hain.\n\n'
    'Quran ka mutan (text) aur tarajim taleemi maqsad ke liye shaamil kiye gaye hain.';


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
