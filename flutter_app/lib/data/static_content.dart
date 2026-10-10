class Faq {
  final String qEn;
  final String aEn;
  final String qUr;
  final String aUr;

  const Faq({
    required this.qEn,
    required this.aEn,
    required this.qUr,
    required this.aUr,
  });
}

const List<Faq> faqs = [
  Faq(
    qEn: 'Does the app work offline?',
    aEn:
        'Yes. After downloading, all 611 pages of the 15-line Hifzi mushaf can be read without the internet. The surah index, juz index, bookmarks and your settings also work offline. Audio recitation and page images need the internet the first time you view or listen to them.',
    qUr: 'کیا ایپ آف لائن چلتی ہے؟',
    aUr:
        'جی ہاں۔ ڈاؤن لوڈ کے بعد 15 لائن حفصی مصحف کے تمام 611 صفحات بغیر انٹرنیٹ کے پڑھے جا سکتے ہیں۔ سورہ انڈیکس، جز انڈیکس، بک مارکس اور آپ کی سیٹنگز بھی آف لائن کام کرتی ہیں۔ آڈیو تلاوت اور پیج امیجز کو پہلی بار دیکھنے یا سننے کے لیے انٹرنیٹ درکار ہوتا ہے۔',
  ),
  Faq(
    qEn: 'How are prayer times calculated?',
    aEn:
        'Prayer times are calculated on-device from your GPS location. Calculation method, Fajr/Isha angles and the Asr juristic method can be changed in Settings > Prayer Times (default: Muslim World League). Notification permission is required for the azan alarm.',
    qUr: 'نماز کے اوقات کیسے حساب ہوتے ہیں؟',
    aUr:
        'نماز کے اوقات آپ کی GPS لوکیشن سے ڈیوائس پر ہی حساب ہوتے ہیں۔ حساب کا طریقہ، فجر اور عشاء کے زاویے اور عصر کا فقہی طریقہ Settings > Prayer Times میں بدلا جا سکتا ہے (ڈیفالٹ: مسلم ورلڈ لیگ)۔ اذان الارم کے لیے نوٹیفکیشن کی اجازت ضروری ہے۔',
  ),
  Faq(
    qEn: 'How do I calibrate the Qibla compass?',
    aEn:
        'In Settings > Qiblah there is a calibration slider. Place your phone on a flat surface and move it in a figure-8 motion 2–3 times to calibrate the magnetometer. Then use the slider to fine-tune the needle to match your known Qibla direction.',
    qUr: 'قبلہ کمپاس کیلیبریٹ کیسے کروں؟',
    aUr:
        'Settings > Qiblah میں کیلیبریشن سلائیڈر موجود ہے۔ اپنا فون ہموار سطح پر رکھیں اور میگنیٹومیٹر کیلیبریٹ کرنے کے لیے فون کو 8 کی شکل میں 2-3 بار گھمائیں۔ پھر سلائیڈر سے سوئی کو اپنی معلوم قبلہ سمت سے ملا کر ٹھیک کریں۔',
  ),
  Faq(
    qEn: 'How does Backup & Restore work?',
    aEn:
        'In Settings > Backup you can create a backup file of your bookmarks, last-read position, preferences and prayer settings. The file is saved on your phone — you can restore it on a new phone via Restore. No account or cloud login is needed.',
    qUr: 'بیک اپ اور ریسٹور کیسے کام کرتا ہے؟',
    aUr:
        'Settings > Backup میں آپ اپنے بک مارکس، آخری پڑھی گئی جگہ، ترجیحات اور نماز سیٹنگز کی بیک اپ فائل بنا سکتے ہیں۔ یہ فائل آپ کے فون پر محفوظ ہوتی ہے — نئے فون پر Restore سے اسے واپس لا سکتے ہیں۔ کوئی اکاؤنٹ یا کلاؤڈ لاگ اِن درکار نہیں۔',
  ),
  Faq(
    qEn: 'How much data does audio recitation use?',
    aEn:
        'Audio recitation streams over the internet, so listening on mobile data uses data. Download surah or juz audio over Wi-Fi first from the Download Center, then listen offline.',
    qUr: 'آڈیو تلاوت میں کتنا ڈیٹا لگتا ہے؟',
    aUr:
        'آڈیو تلاوت انٹرنیٹ سے سٹریم ہوتی ہے، اس لیے موبائل ڈیٹا پر سننے سے ڈیٹا خرچ ہوتا ہے۔ پہلے ڈاؤن لوڈ سینٹر سے وائی فائی پر سورہ یا جز کی آڈیو ڈاؤن لوڈ کر لیں، پھر آف لائن سنیں۔',
  ),
  Faq(
    qEn: 'Are my bookmarks private?',
    aEn:
        '100% private. All bookmarks, last-read pages and preferences are saved only on your device. There is no account, no server upload and no analytics — your data never leaves your phone.',
    qUr: 'کیا میرے بک مارکس نجی ہیں؟',
    aUr:
        '100 فیصد نجی۔ تمام بک مارکس، آخری پڑھے گئے صفحات اور ترجیحات صرف آپ کے ڈیوائس پر محفوظ ہوتی ہیں۔ کوئی اکاؤنٹ، سرور اپ لوڈ یا اینالیٹکس نہیں — آپ کا ڈیٹا آپ کے فون سے باہر نہیں جاتا۔',
  ),
  Faq(
    qEn: 'How do I use the ayah repeat / loop feature?',
    aEn:
        'In Audio Studio, turn on repeat mode on any ayah to listen to it again and again — very useful for hifz (memorization). You can also select a surah range and put it on loop.',
    qUr: 'آیت ریپیٹ / لوپ فیچر کیسے استعمال کروں؟',
    aUr:
        'آڈیو اسٹوڈیو میں کسی بھی آیت پر ریپیٹ موڈ آن کر کے اس آیت کو بار بار سنا جا سکتا ہے — حفظ (یاد کرنے) کے لیے بہت مفید ہے۔ آپ سورہ کی رینج منتخب کر کے بھی لوپ پر لگا سکتے ہیں۔',
  ),
  Faq(
    qEn: 'What themes and display options are there?',
    aEn:
        'Preferences offers Light, Dark and Sepia themes, plus Arabic font size, translation on/off and transliteration display options. In Page view the 15-line Hifzi layout looks just like the authentic mushaf.',
    qUr: 'تھیمز اور ڈسپلے آپشنز کیا ہیں؟',
    aUr:
        'ترجیحات میں لائٹ، ڈارک اور سیپیا تھیمز کے ساتھ عربی فونٹ سائز، ترجمہ آن/آف اور نقل حرفی ڈسپلے کے آپشنز موجود ہیں۔ پیج ویو میں 15 لائن حفصی لے آؤٹ اصل مصحف جیسا نظر آتا ہے۔',
  ),
  Faq(
    qEn: 'What is the Download Center for?',
    aEn:
        'From the Download Center you can download all Quran page images, audio recitations (12 qaris) and translations at once and keep them offline — ideal for travel or low-network areas.',
    qUr: 'ڈاؤن لوڈ سینٹر کس لیے ہے؟',
    aUr:
        'ڈاؤن لوڈ سینٹر سے آپ قرآن کے تمام پیج امیجز، آڈیو تلاوت (12 قاری) اور تراجم ایک ساتھ ڈاؤن لوڈ کر کے آف لائن رکھ سکتے ہیں — سفر یا کم نیٹ ورک والی جگہوں کے لیے بہترین۔',
  ),
  Faq(
    qEn: 'Where do I report a bug?',
    aEn:
        'On the About screen there is a "Report an Issue" option. Please write the app version, device model and the issue details there so we can fix it quickly. Your feedback is valuable to us.',
    qUr: 'کوئی مسئلہ (بگ) ہو تو کہاں رپورٹ کروں؟',
    aUr:
        'About سکرین پر "Report an Issue" کا آپشن موجود ہے۔ وہاں ایپ کا ورژن، ڈیوائس ماڈل اور مسئلے کی تفصیل لکھیں تاکہ ہم جلد اصلاح کر سکیں۔ آپ کی آراء ہمارے لیے قیمتی ہیں۔',
  ),
];

/// Per-version highlights shown in About's "What's New" section.
/// Keyed by app version; keep the newest entries up to date with each release.
const Map<String, String> aboutChangelog = {
  '1.0.51':
      '• Ayah highlight boundaries corrected across all 6236 ayahs (visual measurement) — 5 bogus line assignments removed\n'
      '• Tapped ayah and audio highlight now line up exactly with the mushaf page',
  '1.0.50':
      '• 2,213 shared-line ayah highlight boundary corrections via visual marker detection\n'
      '• Ayah tap, audio highlight and drawing overlays aligned with the page images',
};

const Map<String, String> aboutChangelogUr = {
  '1.0.51':
      '• تمام 6236 آیات میں آیت ہائی لائٹ کی حدود درست کر دی گئیں (بصری پیمائش) — 5 غلط لائن تفویضات ہٹا دی گئیں\n'
      '• ٹیپ کی گئی آیت اور آڈیو ہائی لائٹ اب مصحف کے صفحے کے بالکل مطابق ہیں',
  '1.0.50':
      '• بصری مارکر ڈیٹیکشن کے ذریعے 2,213 مشترکہ لائن آیت ہائی لائٹ باؤنڈری کی اصلاحات\n'
      '• آیت ٹیپ، آڈیو ہائی لائٹ اور ڈرائنگ اوورلے پیج امیجز کے ساتھ ہم آہنگ',
};

/// Returns the "What's New" text for [version], falling back to the newest
/// known entry when the version has no changelog entry.
String aboutFeaturesFor(String version) =>
    aboutChangelog[version] ?? aboutChangelog['1.0.51']!;

/// Language-aware variant of [aboutFeaturesFor].
String aboutFeaturesForLang(String version, bool isUrdu) {
  final map = isUrdu ? aboutChangelogUr : aboutChangelog;
  return map[version] ?? map['1.0.51']!;
}

const String aboutIntroEn =
    'Nur-ul-Quran — the 15-line South-Asian Hifzi mushaf, digitally. '
    'All 611 pages in the authentic Hifzi layout, just as you read in the printed mushaf. '
    'This app is built for tilawat, hifz and understanding — without unnecessary features, '
    'with a clean and peaceful reading experience.';

const String aboutIntroUr =
    'نور القرآن — 15 لائن جنوبی ایشیائی حفصی مصحف کا ڈیجیٹل تجربہ۔ '
    'تمام 611 صفحات مستند حفصی لے آؤٹ میں، بالکل ویسے جیسے آپ چھپے ہوئے مصحف میں پڑھتے ہیں۔ '
    'یہ ایپ تلاوت، حفظ اور سمجھنے کے لیے بنائی گئی ہے — غیر ضروری فیچرز کے بغیر، '
    'صاف اور پُرسکون مطالعے کے تجربے کے ساتھ۔';

const String aboutSourcesEn =
    '• Mushaf pages: 15-line Hifzi layout images\n'
    '• Quran text: Tanzil (Uthmani script)\n'
    '• Urdu translation: Kanzul Iman — Imam Ahmad Raza Khan Barelvi (Tanzil)\n'
    '• English translation: Saheeh International\n'
    '• Audio: mp3quran.net (surah recitations), everyayah.com (ayah recitations)\n'
    '• Prayer times: on-device astronomical calculation';

const String aboutSourcesUr =
    '• مصحف صفحات: 15 لائن حفصی لے آؤٹ امیجز\n'
    '• قرآن کا متن: تنزیل (عثمانی رسم الخط)\n'
    '• اردو ترجمہ: کنزالایمان — امام احمد رضا خان بریلوی (تنزیل)\n'
    '• انگریزی ترجمہ: صحیح انٹرنیشنل\n'
    '• آڈیو: mp3quran.net (سورہ تلاوت)، everyayah.com (آیت تلاوت)\n'
    '• نماز کے اوقات: ڈیوائس پر فلکیاتی حساب';

const String aboutLicensesEn =
    'This app is built with Flutter (BSD 3-Clause). The following open-source packages are used: '
    'just_audio, audio_service, audio_session, provider, shared_preferences, path_provider, '
    'google_fonts, share_plus, url_launcher, cached_network_image, timezone, android_alarm_manager_plus, '
    'geolocator, flutter_compass, speech_to_text, app_links, flutter_local_notifications.\n\n'
    'Fonts: Noto Sans Arabic and Amiri Quran (SIL Open Font License 1.1) are bundled with the app.\n\n'
    'The Quranic text and translations are included for educational purposes.';

const String aboutLicensesUr =
    'یہ ایپ Flutter (BSD 3-Clause) سے بنائی گئی ہے۔ درج ذیل اوپن سورس پیکجز استعمال ہوئے ہیں: '
    'just_audio, audio_service, audio_session, provider, shared_preferences, path_provider, '
    'google_fonts, share_plus, url_launcher, cached_network_image, timezone, android_alarm_manager_plus, '
    'geolocator, flutter_compass, speech_to_text, app_links, flutter_local_notifications۔\n\n'
    'فونٹس: Noto Sans Arabic اور Amiri Quran (SIL Open Font License 1.1) ایپ میں شامل ہیں۔\n\n'
    'قرآن کا متن اور تراجم تعلیمی مقصد کے لیے شامل کیے گئے ہیں۔';


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
