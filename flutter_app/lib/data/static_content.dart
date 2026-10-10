class Faq {
  final String q;
  final String a;

  const Faq(this.q, this.a);
}

/// English FAQs
const List<Faq> faqsEn = [
  Faq(
    'Does the app work offline?',
    'Yes. All 611 pages of the 15-line South-Asian Hifzi Mushaf are pre-bundled and work completely offline without internet. Surah index, Juz index, bookmarks, and settings are fully offline as well. Qari audio recitations can also be downloaded for offline listening in the Download Center.',
  ),
  Faq(
    'How are prayer times calculated?',
    'Prayer times are calculated on-device using precise astronomical algorithms based on your selected city or live device GPS. Calculation parameters, angles, and Asr juristic method (Hanafi / Shafi\'i) can be customized in Settings > Prayer Times. Notification permission is required for Azan alerts.',
  ),
  Faq(
    'How do I calibrate the Qiblah compass?',
    'Place your device on a flat surface and move it in a figure-8 motion 2 to 3 times to calibrate the magnetometer sensor. Keep away from metallic cases and magnetic phone mounts for optimal precision.',
  ),
  Faq(
    'How does Backup & Restore work?',
    'In Settings > Backup, you can generate a local backup file of your bookmarks, reading progress, and preferences. You can restore this file on any new device without requiring an account or cloud login.',
  ),
  Faq(
    'How much data does audio recitation consume?',
    'Streaming recitation uses standard mobile bandwidth. To conserve cellular data while traveling, you can download Surah or Qari audio packs over Wi-Fi in the Download Center for offline playback.',
  ),
  Faq(
    'Are my bookmarks and notes private?',
    '100% private. All your bookmarks, reading history, and notes are stored strictly on your local device. There are no user tracking, analytics, or third-party server uploads.',
  ),
  Faq(
    'How do I use the Ayah repeat / loop feature?',
    'Tap any Ayah on the Mushaf page, and use the repeat control in the bottom audio player to loop individual verses or select a custom range of Ayahs for memorization (Hifz).',
  ),
  Faq(
    'What reading themes and modes are available?',
    'You can choose between Night Slate (pure OLED dark mode), Antique Parchment, and Emerald Day themes. Reading modes include Page-Slide, Continuous Scroll, and Page-Turn.',
  ),
  Faq(
    'What is the Jump to Page / Parah feature?',
    'In the 3-dot reader menu, select "Jump to Page / Parah" to navigate either directly by Mushaf page (1 to 611) or by Parah number (1 to 30) and page within that Parah (1 to 20).',
  ),
  Faq(
    'Where can I report a bug or request a feature?',
    'Use the "Report an Issue" button on the About & Licenses screen, or email numanfirdosi@gmail.com directly. We review all feedback promptly.',
  ),
];

/// Urdu FAQs in authentic Urdu script
const List<Faq> faqsUr = [
  Faq(
    'کیا یہ ایپ انٹرنیٹ کے بغیر (آف لائن) کام کرتی ہے؟',
    'جی ہاں! ۱۵ سطری حفظی مصحف کے تمام ۶۱۱ صفحات ایپ میں شامل ہیں اور بغیر انٹرنیٹ مکمل آف لائن پڑھے جا سکتے ہیں۔ سورتوں اور پاروں کی فہرست، بُک مارکس اور ترتیبات بھی آف لائن دستیاب ہیں۔ تلاوتِ کلام پاک کی آڈیو بھی ڈاؤن لوڈ سینٹر سے آف لائن سننے کے لیے محفوظ کی جا سکتی ہے۔',
  ),
  Faq(
    'نماز کے اوقات کیسے شمار ہوتے ہیں؟',
    'نماز کے اوقات آپ کے منتخب کردہ شہر یا موبائل جی پی ایس (GPS) کے ذریعے خودکار فلکیاتی حساب سے طے پاتے ہیں۔ عصر کا طریقہ (حنفی / شافعی) سیٹنگز میں تبدیل کیا جا سکتا ہے۔ اذان کے الارم کے لیے نوٹیفکیشن کی اجازت ضروری ہے۔',
  ),
  Faq(
    'قبلہ کمپاس کی درستگی کیسے یقینی بنائیں؟',
    'اپنے موبائل کو کسی ہموار سطح پر رکھیں اور انگریزی ہندسے 8 کی شکل میں 2-3 بار گھمائیں تاکہ مقناطیسی سینسر درست ہو جائے۔ موبائل کور یا مقناطیسی ہولڈر سے دور رکھیں۔',
  ),
  Faq(
    'بیک اپ اور بحالی (Backup & Restore) کا طریقہ کیا ہے؟',
    'سیٹنگز میں بیک اپ کے ذریعے آپ اپنے بُک مارکس، مطالعے کی پیش رفت اور ترتیبات کی فائل محفوظ کر سکتے ہیں۔ نئے فون میں اسے باآسانی ری اسٹور کیا جا سکتا ہے۔ کسی آن لائن اکاؤنٹ کی ضرورت نہیں۔',
  ),
  Faq(
    'آڈیو تلاوت سننے میں کتنا انٹرنیٹ استعمال ہوتا ہے؟',
    'آن لائن سننے پر عام آڈیو اسٹریمنگ جتنا ڈیٹا لگتا ہے۔ موبائل ڈیٹا بچانے کے لیے آپ وائی فائی پر قاری کے آڈیو پیک ڈاؤن لوڈ کر کے مکمل آف لائن سن سکتے ہیں۔',
  ),
  Faq(
    'کیا میرے بُک مارکس اور ذاتی نوٹس محفوظ ہیں؟',
    'سو فیصد محفوظ اور پرائیویٹ۔ آپ کا تمام ڈیٹا صرف آپ کے موبائل میں محفوظ رہتا ہے اور کسی بیرونی سرور پر نہیں بھیجا جاتا۔',
  ),
  Faq(
    'آیت کو بار بار دہرانے (تکرار / لوپ) کا فیچر کیسے استعمال کریں؟',
    'مصحف کے صفحے پر کسی بھی آیت پر ٹیپ کر کے تلاوت شروع کریں، پھر پلیئر میں رپیٹ کا آپشن منتخب کر کے حفظ و تکرار کے لیے آیت کو بار بار سنیں۔',
  ),
  Faq(
    'ایپ میں کون سی تھیمز اور ڈسپلے موڈز ہیں؟',
    'آپ نائٹ موڈ (او ایل ای ڈی بلیک)، ایمرلڈ گرین اور پارچمنٹ (ہلکا زردی مائل) تھیمز منتخب کر سکتے ہیں۔ پڑھنے کے لیے پیج سلائیڈ، اسکرول اور پیج ٹرن کے طریقے دستیاب ہیں۔',
  ),
  Faq(
    'پارہ اور صفحہ پر جانے (Jump) کا آپشن کہاں ہے؟',
    'تلاوت والے صفحے پر تھری ڈاٹ مینیو میں "Jump to Page / Parah" منتخب کریں۔ یہاں آپ براہ راست صفحہ نمبر (۱ تا ۶۱۱) یا پارہ نمبر (۱ تا ۳۰) اور پارے کا صفحہ (۱ تا ۲۰) درج کر کے مطلوبہ صفحے پر جا سکتے ہیں۔',
  ),
  Faq(
    'کسی خرابی یا مسئلے کی اطلاع کیسے دیں؟',
    'ایپ کے About اسکرین پر "Report an Issue" پر ٹیپ کریں یا براہ راست numanfirdosi@gmail.com پر ای میل بھیجیں۔ ہم آپ کی تجاویز کا خیر مقدم کرتے ہیں۔',
  ),
];

/// Backwards compatibility default
const List<Faq> faqs = faqsEn;

List<Faq> getFaqs(String lang) => lang == 'ur' ? faqsUr : faqsEn;

const String aboutIntro =
    'Nur-ul-Quran (نور القرآن) brings the authentic 15-line South-Asian Hifzi Mushaf '
    'into a beautiful, distraction-free digital experience. All 611 pages are crafted '
    'in the traditional Hifzi layout familiar to students and reciters worldwide, '
    'accompanied by accurate prayer times, audio recitation, and comprehensive study tools.';

const String aboutFeatures =
    '• Complete 611-page 15-Line Indo-Pak Hifzi Mushaf (Page-turn and continuous scroll modes)\n'
    '• Tap any Ayah on the page for instant playback with pixel-perfect Ayah highlighting\n'
    '• Full Surah Index (114 Surahs) & Juz Index (30 Ajza) with bilingual introductions\n'
    '• Jump to any Page (1 to 611) or Parah (1 to 30) & page within Parah (1 to 20)\n'
    '• Precise Prayer Times calculated locally with Azan notifications and Qiblah Compass\n'
    '• Audio recitations by renowned international Qaris with Ayah repeating & looping\n'
    '• Khatm Planner, Reading Goals, Bookmarks, and Notes with full offline support\n'
    '• Night Mode, Parchment, and Emerald themes optimized for OLED and daytime reading\n'
    '• Daily Duas (including full authentic Taraweeh Dua) and Ayah of the Day';

const String aboutSources =
    '• Mushaf Pages: High-resolution 15-line South Asian Hifzi Mushaf\n'
    '• Quran Data & Verse Coordinates: Tanzil & EveryAyah open-source archives\n'
    '• Audio Recitations: mp3quran.net & everyayah.com\n'
    '• Prayer Times & Qibla: On-device astronomical and geomagnetic calculation';

const String aboutLicenses =
    'Nur-ul-Quran is built with Flutter and open-source software under respectful licenses.\n\n'
    'Key open-source dependencies include just_audio, audio_service, audio_session, '
    'provider, shared_preferences, path_provider, package_info_plus, geolocator, '
    'flutter_compass, timezone, and flutter_local_notifications.\n\n'
    'Arabic and Urdu Typography: Amiri Quran and Noto Sans Arabic under SIL Open Font License 1.1.';

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
