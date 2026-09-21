/**
 * AL-MUSHAF 15-LINE (القرآن الكريم)
 * Complete Engine: 15-Line Layout, Audio Recitation with Bismillah Sequencing,
 * Multi-Theme Palette (Emerald Day, Antique Parchment, Night Slate),
 * Khatm Tracker, Slide-out Tafsir Drawer, and Full Surah Index.
 */

// Force Mobile App Sizing & Layout on Mobile / Touch Devices
function detectAndApplyMobile() {
  const ua = navigator.userAgent || '';
  const isMobileUA = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile/i.test(ua);
  const isTouch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0);
  const isNarrowMobile = (isTouch && window.innerWidth <= 768);
  
  if (isMobileUA || isNarrowMobile) {
    document.documentElement.classList.add('is-mobile-app');
    if (document.body) document.body.classList.add('is-mobile-app');
  } else {
    document.documentElement.classList.remove('is-mobile-app');
    if (document.body) document.body.classList.remove('is-mobile-app');
  }
}
detectAndApplyMobile();
window.addEventListener('resize', detectAndApplyMobile);
window.addEventListener('orientationchange', () => setTimeout(detectAndApplyMobile, 100));

// Wipe legacy mismatched caches
try {
  Object.keys(localStorage).forEach(k => {
    if (k.startsWith('nur-page-ayahs-')) localStorage.removeItem(k);
  });
} catch (e) {}

// 114 Surah Metadata [English, Meaning, Arabic, Ayahs, Revelation, StartPage]
const surahNames = [
  ['Al-Fatihah','The Opener','الفاتحة',7,'Meccan'],['Al-Baqarah','The Cow','البقرة',286,'Medinan'],['Ali Imran','Family of Imran','آل عمران',200,'Medinan'],['An-Nisa','The Women','النساء',176,'Medinan'],['Al-Ma’idah','The Table Spread','المائدة',120,'Medinan'],['Al-An’am','The Cattle','الأنعام',165,'Meccan'],['Al-A’raf','The Heights','الأعراف',206,'Meccan'],['Al-Anfal','The Spoils of War','الأنفal',75,'Medinan'],['At-Tawbah','The Repentance','التوبة',129,'Medinan'],['Yunus','Jonah','يونس',109,'Meccan'],['Hud','Hud','هود',123,'Meccan'],['Yusuf','Joseph','يوسف',111,'Meccan'],['Ar-Ra’d','The Thunder','الرعد',43,'Medinan'],['Ibrahim','Abraham','إبراهيم',52,'Meccan'],['Al-Hijr','The Rocky Tract','الحجر',99,'Meccan'],['An-Nahl','The Bee','النحل',128,'Meccan'],['Al-Isra','The Night Journey','الإسراء',111,'Meccan'],['Al-Kahf','The Cave','الكهف',110,'Meccan'],['Maryam','Mary','مريم',98,'Meccan'],['Ta-Ha','Ta-Ha','طه',135,'Meccan'],['Al-Anbiya','The Prophets','الأنبياء',112,'Meccan'],['Al-Hajj','The Pilgrimage','الحج',78,'Medinan'],['Al-Mu’minun','The Believers','المؤمنون',118,'Meccan'],['An-Nur','The Light','النور',64,'Medinan'],['Al-Furqan','The Criterion','الفرقان',77,'Meccan'],['Ash-Shu’ara','The Poets','الشعراء',227,'Meccan'],['An-Naml','The Ant','النمل',93,'Meccan'],['Al-Qasas','The Stories','القصص',88,'Meccan'],['Al-Ankabut','The Spider','العنكبوت',69,'Meccan'],['Ar-Rum','The Romans','الروم',60,'Meccan'],['Luqman','Luqman','لقمان',34,'Meccan'],['As-Sajdah','The Prostration','السجدة',30,'Meccan'],['Al-Ahzab','The Combined Forces','الأحزاب',73,'Medinan'],['Saba','Sheba','سبأ',54,'Meccan'],['Fatir','Originator','فاطر',45,'Meccan'],['Ya-Sin','Ya-Sin','يس',83,'Meccan'],['As-Saffat','Those Ranges in Ranks','الصافات',182,'Meccan'],['Sad','The Letter Sad','ص',88,'Meccan'],['Az-Zumar','The Groups','الزمر',75,'Meccan'],['Ghafir','The Forgiver','غافر',85,'Meccan'],['Fussilat','Explained in Detail','فصلت',54,'Meccan'],['Ash-Shura','The Consultation','الشورى',53,'Meccan'],['Az-Zukhruf','The Ornaments of Gold','الزخرف',89,'Meccan'],['Ad-Dukhan','The Smoke','الدخان',59,'Meccan'],['Al-Jathiyah','The Crouching','الجاثية',37,'Meccan'],['Al-Ahqaf','The Wind-Curved Sandhills','الأحقاف',35,'Meccan'],['Muhammad','Muhammad','محمد',38,'Medinan'],['Al-Fath','The Victory','الفتح',29,'Medinan'],['Al-Hujurat','The Rooms','الحجرات',18,'Medinan'],['Qaf','The Letter Qaf','ق',45,'Meccan'],['Adh-Dhariyat','The Winnowing Winds','الذاريات',60,'Meccan'],['At-Tur','The Mount','الطور',49,'Meccan'],['An-Najm','The Star','النجم',62,'Meccan'],['Al-Qamar','The Moon','القمر',55,'Meccan'],['Ar-Rahman','The Beneficent','الرحمن',78,'Medinan'],['Al-Waqi’ah','The Inevitable','الواقعة',96,'Meccan'],['Al-Hadid','The Iron','الحديد',29,'Medinan'],['Al-Mujadila','The Pleading Woman','المجادلة',22,'Medinan'],['Al-Hashr','The Exile','الحشر',24,'Medinan'],['Al-Mumtahanah','She That Is to Be Examined','الممتحنة',13,'Medinan'],['As-Saff','The Ranks','الصف',14,'Medinan'],['Al-Jumu’ah','Friday','الجمعة',11,'Medinan'],['Al-Munafiqun','The Hypocrites','المنافقون',11,'Medinan'],['At-Taghabun','Mutual Disillusion','التغابن',18,'Medinan'],['At-Talaq','The Divorce','الطلاق',12,'Medinan'],['At-Tahrim','The Prohibition','التحريم',12,'Medinan'],['Al-Mulk','The Sovereignty','الملك',30,'Meccan'],['Al-Qalam','The Pen','القلم',52,'Meccan'],['Al-Haqqah','The Reality','الحاقة',52,'Meccan'],['Al-Ma’arij','The Ascending Stairways','المعارج',44,'Meccan'],['Nuh','Noah','نوح',28,'Meccan'],['Al-Jinn','The Jinn','الجن',28,'Meccan'],['Al-Muzzammil','The Enshrouded One','المزمل',20,'Meccan'],['Al-Muddaththir','The Cloaked One','المدثر',56,'Meccan'],['Al-Qiyamah','The Resurrection','القيامة',40,'Meccan'],['Al-Insan','Man','الإنسان',31,'Medinan'],['Al-Mursalat','The Emissaries','المرسلات',50,'Meccan'],['An-Naba','The Tidings','النبأ',40,'Meccan'],['An-Nazi’at','Those Who Drag Forth','النازعات',46,'Meccan'],['Abasa','He Frowned','عبس',42,'Meccan'],['At-Takwir','The Overthrowing','التكوير',29,'Meccan'],['Al-Infitar','The Cleaving','الانفطار',19,'Meccan'],['Al-Mutaffifin','The Defrauders','المطففين',36,'Meccan'],['Al-Inshiqaq','The Sundering','الانشقاق',25,'Meccan'],['Al-Buruj','The Mansions of the Stars','البروج',22,'Meccan'],['At-Tariq','The Nightcomer','الطارق',17,'Meccan'],['Al-A’la','The Most High','الأعلى',19,'Meccan'],['Al-Ghashiyah','The Overwhelming','الغاشية',26,'Meccan'],['Al-Fajr','The Dawn','الفجر',30,'Meccan'],['Al-Balad','The City','البلد',20,'Meccan'],['Ash-Shams','The Sun','الشمس',15,'Meccan'],['Al-Layl','The Night','الليل',21,'Meccan'],['Ad-Duha','The Morning Hours','الضحى',11,'Meccan'],['Ash-Sharh','The Relief','الشرح',8,'Meccan'],['At-Tin','The Fig','التين',8,'Meccan'],['Al-Alaq','The Clot','العلق',19,'Meccan'],['Al-Qadr','The Power','القدر',5,'Meccan'],['Al-Bayyinah','The Clear Proof','البينة',8,'Medinan'],['Az-Zalzalah','The Earthquake','الزلزلة',8,'Medinan'],['Al-Adiyat','The Courser','العاديات',11,'Meccan'],['Al-Qari’ah','The Calamity','القارعة',11,'Meccan'],['At-Takathur','The Rivalry in World Increase','التكاثر',8,'Meccan'],['Al-Asr','The Declining Day','العصر',3,'Meccan'],['Al-Humazah','The Traducer','الهمزة',9,'Meccan'],['Al-Fil','The Elephant','الفيل',5,'Meccan'],['Quraysh','Quraysh','قريش',4,'Meccan'],['Al-Ma’un','Small Kindnesses','الماعون',7,'Meccan'],['Al-Kawthar','Abundance','الكوثر',3,'Meccan'],['Al-Kafirun','The Disbelievers','الكافرون',6,'Meccan'],['An-Nasr','The Divine Support','النصر',3,'Medinan'],['Al-Masad','The Palm Fiber','المسد',5,'Meccan'],['Al-Ikhlas','Sincerity','الإخلاص',4,'Meccan'],['Al-Falaq','The Daybreak','الفلق',5,'Meccan'],['An-Nas','Mankind','الناس',6,'Meccan']
];

const TOTAL_PAGES = 611;

const startPages = [
  2, 3, 50, 77, 106, 128, 151, 177, 187, 208, 
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312, 
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404, 
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467, 
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518, 
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549, 
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568, 
  570, 572, 574, 575, 577, 578, 580, 587, 589, 590, 
  591, 592, 593, 594, 595, 596, 597, 597, 598, 599, 
  600, 601, 602, 602, 603, 603, 604, 604, 605, 605, 
  606, 606, 607, 607, 608, 608, 608, 609, 609, 610, 
  610, 610, 611, 611
];
const surahs = surahNames.map((s, i) => [...s, startPages[i]]);

const qarisData = [
  { id: 'ar.alafasy', name: 'Mishary Rashid Alafasy', arabic: 'مشاري راشد العفاسي', style: 'Murattal', country: 'Kuwait' },
  { id: 'ar.abdulbasitmurattal', name: 'Abdul Basit Abdus Samad', arabic: 'عبد الباسط عبد الصمد', style: 'Murattal', country: 'Egypt' },
  { id: 'ar.abdulsamad', name: 'Abdul Basit (Mujawwad)', arabic: 'عبد الباسط عبد الصمد', style: 'Mujawwad', country: 'Egypt' },
  { id: 'ar.husary', name: 'Mahmoud Khalil Al-Husary', arabic: 'محمود خليل الحصري', style: 'Murattal', country: 'Egypt' },
  { id: 'ar.husarymujawwad', name: 'Al-Husary (Mujawwad)', arabic: 'محمود خليل الحصري', style: 'Mujawwad', country: 'Egypt' },
  { id: 'ar.minshawi', name: 'Mohamed Siddiq El-Minshawi', arabic: 'محمد صديق المنشاوي', style: 'Murattal', country: 'Egypt' },
  { id: 'ar.minshawimujawwad', name: 'El-Minshawi (Mujawwad)', arabic: 'محمد صديق المنشاوي', style: 'Mujawwad', country: 'Egypt' },
  { id: 'ar.abdurrahmaansudais', name: 'Abdur-Rahman As-Sudais', arabic: 'عبد الرحمن السديس', style: 'Murattal', country: 'Makkah' },
  { id: 'ar.mahermuaiqly', name: 'Maher Al-Muaiqly', arabic: 'ماهر المعيقلي', style: 'Murattal', country: 'Makkah' },
  { id: 'ar.saoodshuraym', name: 'Sa\'ood Ash-Shuraym', arabic: 'سعود الشريم', style: 'Murattal', country: 'Makkah' },
  { id: 'ar.shaatree', name: 'Abu Bakr Ash-Shaatree', arabic: 'أبو بكر الشاطري', style: 'Murattal', country: 'Saudi Arabia' },
  { id: 'ar.hudhaify', name: 'Ali Abdur-Rahman Al-Hudhaify', arabic: 'علي بن عبد الرحمن الحذيفي', style: 'Murattal', country: 'Madinah' }
];

const surahStartAyahs = [];
let _runningAyah = 1;
surahs.forEach(s => {
  surahStartAyahs.push(_runningAyah);
  _runningAyah += s[3];
});

let currentAudioSurahNum = 1;
let currentAudioFilter = 'all';

const state = {
  page: Number(localStorage.getItem('nur-page')) || 2,
  bookmarks: JSON.parse(localStorage.getItem('nur-bookmarks') || '[]'),
  favourites: JSON.parse(localStorage.getItem('nur-favourites') || '[]'),
  notes: JSON.parse(localStorage.getItem('nur-notes') || '{}'),
  theme: localStorage.getItem('nur-theme') || 'emerald',
  mode: localStorage.getItem('nur-mode') || 'Page slide',
  scale: Number(localStorage.getItem('nur-scale')) || 100,
  glow: localStorage.getItem('nur-glow') !== 'false'
};

const quranApi = 'https://api.alquran.cloud/v1/page/';
let searchRequest = 0;
let currentSurahFilter = 'all';
let currentSurahSort = 'mushaf';
let selectedAyahData = null;

const audioState = {
  qari: localStorage.getItem('nur-qari') || 'ar.alafasy',
  ayahs: [],
  index: 0,
  isBismillah: false,
  bismillahSurah: null,
  pendingAyahNumber: null
};

const juzNames = [
  'Alif Lam Mim','Sayaqul','Tilkal Rusul','Lan Tanalu','Wal Mohanaton','La Yuhibbullah','Wa Iza Samiu','Wa Lau Annana','Qalal Malao','Wa Alamu','Yatazeroon','Wa Mamin Daabbat','Wa Ma Ubarri’u','Rubama','Subhanalladhi','Qala Alam','Iqtaraba','Qad Aflaha','Wa Qalalladhina','A’man Khalaq','Utlu Ma Oohi','Wa Manyaqnut','Wa Mali','Faman Azlam','Ilayhi Yuraddu','Ha Mim','Qala فما خطبكم','Qad Sami Allah','Tabarakalladhi','Amma'
];
const juzArabicNames = [
  'الم','سَيَقُولُ','تِلْكَ الرُّسُلُ','لَنْ تَنَالُوا','وَالْمُحْصَنَاتُ','لَا يُحِبُّ اللَّهُ','وَإِذَا سَمِعُوا','وَلَوْ أَنَّنَا','قَالَ الْمَلَأُ','وَاعْلَمُوا','يَعْتَذِرُونَ','وَمَا مِنْ دَابَّةٍ','وَمَا أُبَرِّئُ','رُبَمَا','سُبْحَانَ الَّذِي','قَالَ أَلَمْ','اقْتَرَبَ','قَدْ أَفْلَحَ','وَقَالَ الَّذِينَ','أَمَّنْ خَلَقَ','اتْلُ مَا أُوحِيَ','وَمَنْ يَقْنُتْ','وَمَا لِيَ','فَمَنْ أَظْلَمُ','إِلَيْهِ يُرَدُّ','حم','قَالَ فَمَا خَطْبُكُمْ','قَدْ سَمِعَ اللَّهُ','تَبَارَكَ الَّذِي','عَمَّ'
];

const $ = id => document.getElementById(id);
const views = ['home', 'surahs', 'juz', 'bookmarks', 'search', 'audio', 'ramadan', 'settings', 'backup', 'faq', 'about', 'privacy', 'notFound', 'prayer', 'qiblah'];

// Ensure duplicate overlays are removed
document.querySelectorAll('#readerOverlay').forEach((overlay, index) => {
  if (index) overlay.remove();
});

// Ramzan Daily Messages
const ramadanMessages = [
  { message: 'Let today be lighter: one sincere prayer, one quiet kindness, one moment with the Quran.', prompt: 'Choose one small act you can do with presence.' },
  { message: 'A heart that returns to Allah is never truly lost.', prompt: 'Pause, breathe, and make a simple dua in your own words.' },
  { message: 'Do not measure your Ramzan only by what you finish. Notice how often you return.', prompt: 'Return to one intention you want to protect today.' },
  { message: 'Even a few verses read with attention can change the shape of a day.', prompt: 'Open the Quran for a few unhurried minutes.' },
  { message: 'Mercy can be practiced in the smallest places: your words, your patience, your attention.', prompt: 'Offer gentleness to someone today, including yourself.' }
];
let ramadanMessageIndex = new Date().getDate() % ramadanMessages.length;

function toArabicDigits(num) {
  const digits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  return String(num).replace(/[0-9]/g, d => digits[d]);
}

function getManzil(surahNum) {
  if (surahNum <= 4) return 1;
  if (surahNum <= 9) return 2;
  if (surahNum <= 16) return 3;
  if (surahNum <= 25) return 4;
  if (surahNum <= 36) return 5;
  if (surahNum <= 49) return 6;
  return 7;
}

function dateKey(date = new Date()) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

// -----------------------------------------------------------------------------
// INDEXEDDB STORAGE ENGINE (NurQuranDB v1.0)
// -----------------------------------------------------------------------------
let nurDB = null;

function initIndexedDB() {
  if (!window.indexedDB) return;
  const req = indexedDB.open('NurQuranDB', 1);

  req.onupgradeneeded = (e) => {
    const db = e.target.result;
    if (!db.objectStoreNames.contains('bookmarks')) {
      const bmStore = db.createObjectStore('bookmarks', { keyPath: 'id' });
      bmStore.createIndex('page', 'page', { unique: false });
    }
    if (!db.objectStoreNames.contains('notes')) {
      db.createObjectStore('notes', { keyPath: 'page' });
    }
    if (!db.objectStoreNames.contains('favourites')) {
      const favStore = db.createObjectStore('favourites', { keyPath: 'id' });
      favStore.createIndex('page', 'page', { unique: false });
    }
    if (!db.objectStoreNames.contains('settings')) {
      db.createObjectStore('settings', { keyPath: 'key' });
    }
    if (!db.objectStoreNames.contains('audioCache')) {
      db.createObjectStore('audioCache', { keyPath: 'key' });
    }
  };

  req.onsuccess = (e) => {
    nurDB = e.target.result;
    migrateLocalStorageToIndexedDB();
  };

  req.onerror = () => {};
}

function migrateLocalStorageToIndexedDB() {
  if (!nurDB) return;
  try {
    const tx = nurDB.transaction(['bookmarks', 'notes', 'settings'], 'readwrite');
    const bmStore = tx.objectStore('bookmarks');
    const noteStore = tx.objectStore('notes');
    const settingsStore = tx.objectStore('settings');

    state.bookmarks.forEach(page => {
      bmStore.put({ id: `page_${page}`, page, createdAt: new Date().toISOString() });
    });

    Object.keys(state.notes).forEach(page => {
      noteStore.put({ page: Number(page), note: state.notes[page], updatedAt: new Date().toISOString() });
    });

    settingsStore.put({ key: 'nur-theme', value: state.theme });
    settingsStore.put({ key: 'nur-qari', value: audioState.qari });
    settingsStore.put({ key: 'nur-mode', value: state.mode });
    settingsStore.put({ key: 'nur-page', value: state.page });
  } catch (e) {}
}

function dbSaveNote(page, text) {
  state.notes[page] = text;
  localStorage.setItem('nur-notes', JSON.stringify(state.notes));
  if (nurDB) {
    try {
      const tx = nurDB.transaction(['notes'], 'readwrite');
      tx.objectStore('notes').put({ page: Number(page), note: text, updatedAt: new Date().toISOString() });
    } catch (e) {}
  }
}

function dbDeleteNote(page) {
  delete state.notes[page];
  localStorage.setItem('nur-notes', JSON.stringify(state.notes));
  if (nurDB) {
    try {
      const tx = nurDB.transaction(['notes'], 'readwrite');
      tx.objectStore('notes').delete(Number(page));
    } catch (e) {}
  }
}

function dbSaveBookmark(page) {
  if (!state.bookmarks.includes(page)) {
    state.bookmarks.push(page);
    localStorage.setItem('nur-bookmarks', JSON.stringify(state.bookmarks));
    if (nurDB) {
      try {
        const tx = nurDB.transaction(['bookmarks'], 'readwrite');
        tx.objectStore('bookmarks').put({ id: `page_${page}`, page, createdAt: new Date().toISOString() });
      } catch (e) {}
    }
  }
}

function dbRemoveBookmark(page) {
  state.bookmarks = state.bookmarks.filter(p => p !== page);
  localStorage.setItem('nur-bookmarks', JSON.stringify(state.bookmarks));
  if (nurDB) {
    try {
      const tx = nurDB.transaction(['bookmarks'], 'readwrite');
      tx.objectStore('bookmarks').delete(`page_${page}`);
    } catch (e) {}
  }
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function formatTime(secs) {
  if (isNaN(secs) || secs === Infinity) return '0:00';
  const m = Math.floor(secs / 60);
  const s = Math.floor(secs % 60);
  return `${m}:${s < 10 ? '0' : ''}${s}`;
}

function showToast(message) {
  const toast = $('shareToast');
  if (!toast) return;
  toast.textContent = message;
  toast.classList.remove('hidden');
  setTimeout(() => toast.classList.add('hidden'), 2500);
}

function saveState() {
  localStorage.setItem('nur-page', state.page);
  localStorage.setItem('nur-bookmarks', JSON.stringify(state.bookmarks));
  localStorage.setItem('nur-favourites', JSON.stringify(state.favourites));
  localStorage.setItem('nur-notes', JSON.stringify(state.notes));
}

// -----------------------------------------------------------------------------
// 1. THEME & PALETTES (Emerald Day, Antique Parchment, Night Slate)
// -----------------------------------------------------------------------------
function setTheme(theme) {
  document.body.classList.remove('theme-emerald', 'theme-parchment', 'theme-night', 'dark');

  if (theme === 'parchment') {
    document.body.classList.add('theme-parchment');
    state.theme = 'parchment';
  } else if (theme === 'night' || theme === 'dark') {
    document.body.classList.add('theme-night', 'dark');
    state.theme = 'night';
  } else {
    document.body.classList.add('theme-emerald');
    state.theme = 'emerald';
  }
  localStorage.setItem('nur-theme', state.theme);

  // Sync Header Pills
  $('btnThemeLight')?.classList.toggle('active', state.theme === 'emerald');
  $('btnThemeDark')?.classList.toggle('active', state.theme === 'night');
  $('btnThemeParchment')?.classList.toggle('active', state.theme === 'parchment');

  // Sync Settings Cards
  $('themeCardEmerald')?.classList.toggle('active', state.theme === 'emerald');
  $('themeCardNight')?.classList.toggle('active', state.theme === 'night');
  $('themeCardParchment')?.classList.toggle('active', state.theme === 'parchment');

  // Sync Mobile Capsule Toggle
  $('mobileThemeCapsule')?.classList.toggle('dark-active', state.theme === 'night');
}

// -----------------------------------------------------------------------------
// 2. QARI & RECITATION SYNC
// -----------------------------------------------------------------------------
function setQari(qariCode) {
  const qari = qarisData.find(q => q.id === qariCode) || qarisData[0];
  audioState.qari = qari.id;
  localStorage.setItem('nur-qari', qari.id);

  if ($('headerQari')) $('headerQari').value = qari.id;
  if ($('audioPageQariSelect')) $('audioPageQariSelect').value = qari.id;
  if ($('headerQariDisplayName')) $('headerQariDisplayName').textContent = qari.name;

  if ($('syncRecitationStatus')) {
    $('syncRecitationStatus').textContent = `● Syncing Recitation: ${qari.name}`;
  }
  if ($('deckQariName')) {
    $('deckQariName').textContent = `🎙 ${qari.name} (${qari.style})`;
  }

  // Highlight in header popover list
  document.querySelectorAll('.qari-popover-item').forEach(el => {
    el.classList.toggle('active', el.dataset.qariId === qari.id);
  });

  // Highlight active card in audio view
  document.querySelectorAll('.qari-card-v2').forEach(el => {
    el.classList.toggle('active', el.dataset.qariId === qari.id);
  });

  showToast(`Reciter set to ${qari.name}`);
}

// -----------------------------------------------------------------------------
// 3. NAVIGATION & VIEWS (Hash Routing & History)
// -----------------------------------------------------------------------------
function showView(view, syncHash = true) {
  if (syncHash && view !== 'notFound') {
    const targetHash = '#/' + view;
    if (window.location.hash !== targetHash) {
      window.location.hash = targetHash;
      return;
    }
  }

  views.forEach(name => {
    const el = $(`${name}View`);
    if (el) el.classList.toggle('hidden', name !== view);
  });

  document.querySelectorAll('.nav-item[data-view], .mobile-nav-tab[data-view]').forEach(item => {
    const active = item.dataset.view === view;
    item.classList.toggle('active', active);
  });

  if (view === 'surahs') renderSurahsCardGrid();
  if (view === 'juz') renderJuz();
  if (view === 'bookmarks') renderBookmarks();
  if (view === 'ramadan') {
    renderRamadanDuas();
    renderKhatamPlanner();
  }
  if (view === 'audio') renderAudioStudio();
  if (view === 'prayer') renderPrayerView();
  if (view === 'qiblah') renderQiblahView();
  if (view === 'home') updateKhatmTracker();
  if (view === 'backup') renderBackupView();
  if (view === 'faq') renderFAQ();

  $('sidebar')?.classList.remove('open');
  $('sidebarBackdrop')?.classList.remove('active');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function handleRoute() {
  const hash = window.location.hash || '';
  if (!hash || hash === '#' || hash === '#/') {
    showView('home', false);
    return;
  }

  const clean = hash.replace(/^#\/?/, '').toLowerCase();

  if (clean.startsWith('quran/page/')) {
    const p = parseInt(clean.split('/')[2], 10);
    if (!isNaN(p) && p >= 1 && p <= TOTAL_PAGES) {
      state.page = p;
      openReader(null, false);
      return;
    }
  } else if (clean === 'quran' || clean === 'reader') {
    openReader(null, false);
    return;
  }

  if (!$('readerOverlay')?.classList.contains('hidden')) {
    closeReader(false);
  }

  const validViews = ['home', 'surahs', 'juz', 'bookmarks', 'search', 'audio', 'ramadan', 'settings', 'backup', 'faq', 'about', 'privacy', 'prayer', 'qiblah'];
  if (validViews.includes(clean)) {
    showView(clean, false);
  } else {
    showView('notFound', false);
  }
}

// -----------------------------------------------------------------------------
// 4. SURAHS LIST (3-Column Card Grid from Screenshot 3)
// -----------------------------------------------------------------------------
function renderSurahsCardGrid() {
  const grid = $('surahsCardGrid');
  if (!grid) return;

  const query = ($('surahSearch')?.value || '').trim().toLowerCase();

  let list = surahs.map((s, idx) => ({
    num: idx + 1,
    english: s[0],
    meaning: s[1],
    arabic: s[2],
    ayahs: s[3],
    type: s[4], // 'Meccan' or 'Medinan'
    page: s[5]
  }));

  // Filter Pill
  if (currentSurahFilter === 'makki') {
    list = list.filter(s => s.type === 'Meccan');
  } else if (currentSurahFilter === 'madani') {
    list = list.filter(s => s.type === 'Medinan');
  } else if (currentSurahFilter === 'bookmarked') {
    list = list.filter(s => state.bookmarks.includes(s.page));
  }

  // Search filter
  if (query) {
    list = list.filter(s =>
      s.english.toLowerCase().includes(query) ||
      s.meaning.toLowerCase().includes(query) ||
      s.arabic.includes(query) ||
      String(s.num) === query
    );
  }

  // Sort
  if (currentSurahSort === 'name') {
    list.sort((a, b) => a.english.localeCompare(b.english));
  } else if (currentSurahSort === 'verses') {
    list.sort((a, b) => b.ayahs - a.ayahs);
  } else {
    list.sort((a, b) => a.num - b.num);
  }

  if ($('surahCountText')) {
    $('surahCountText').textContent = list.length;
  }

  if (!list.length) {
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:50px 20px;color:var(--text-muted);font-size:14px;">No Surahs found matching your search.</div>';
    return;
  }

  grid.innerHTML = list.map(s => {
    const isMakki = s.type === 'Meccan';
    const badgeClass = isMakki ? 'makki' : 'madani';
    const badgeText = isMakki ? 'Makki' : 'Madani';
    const isBookmarked = state.bookmarks.includes(s.page);
    const juzNum = Math.min(30, Math.max(1, Math.ceil(s.page / 20)));

    return `
      <div class="surah-card-v2" data-surah-num="${s.num}">
        <div class="surah-card-v2-header">
          <div style="display:flex;align-items:flex-start;">
            <div class="surah-num-bubble">${String(s.num).padStart(3, '0')}</div>
            <div class="surah-title-meta">
              <strong>${s.english} <span class="revelation-tag ${badgeClass}">${badgeText}</span></strong>
              <small>${s.meaning}</small>
            </div>
          </div>
          <div class="surah-arabic-calligraphy">${s.arabic}</div>
        </div>
        <div class="surah-stats-triplet">
          <div><span>Verses</span><strong>${s.ayahs}</strong></div>
          <div><span>15-Line Page</span><strong>p. ${s.page}</strong></div>
          <div><span>Juz</span><strong>${juzNum}</strong></div>
        </div>
        <div class="surah-card-v2-footer">
          <button class="read-btn" data-open-page="${s.page}"><span>📖</span> Read (p. ${s.page})</button>
          <button class="icon-action-btn" data-play-surah="${s.num}" title="Play Surah ${s.english}">▶</button>
          <button class="icon-action-btn ${isBookmarked ? 'bookmarked' : ''}" data-bookmark-page="${s.page}" title="Bookmark Page ${s.page}">${isBookmarked ? '★' : '⚑'}</button>
        </div>
      </div>
    `;
  }).join('');

  // Event bindings
  grid.querySelectorAll('[data-open-page]').forEach(btn => {
    btn.onclick = () => openReaderPage(Number(btn.dataset.openPage));
  });
  grid.querySelectorAll('[data-play-surah]').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      const num = Number(btn.dataset.playSurah);
      const surah = surahs[num - 1];
      if (surah) {
        state.page = surah[5];
        openReader();
        playAyah(1, true);
      }
    };
  });
  grid.querySelectorAll('[data-bookmark-page]').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      const p = Number(btn.dataset.bookmarkPage);
      if (!state.bookmarks.includes(p)) {
        state.bookmarks.push(p);
        showToast(`Page ${p} added to bookmarks`);
      } else {
        state.bookmarks = state.bookmarks.filter(x => x !== p);
        showToast(`Page ${p} removed from bookmarks`);
      }
      saveState();
      renderSurahsCardGrid();
      updateBookmarkButton();
      updateKhatmTracker();
    };
  });
}

// -----------------------------------------------------------------------------
// 5. HOME DASHBOARD & KHATM TRACKER
// -----------------------------------------------------------------------------
function updateKhatmTracker() {
  const percent = Math.min(100, Math.max(0, (state.page / TOTAL_PAGES * 100))).toFixed(1);
  if ($('khatmProgressPath')) {
    $('khatmProgressPath').setAttribute('stroke-dasharray', `${percent}, 100`);
  }
  if ($('khatmPercentText')) {
    $('khatmPercentText').textContent = `${percent}%`;
  }
  if ($('khatmPageText')) {
    $('khatmPageText').textContent = `${state.page} of ${TOTAL_PAGES} Pages`;
  }
  if ($('badgeSavedCount')) {
    $('badgeSavedCount').textContent = `${state.bookmarks.length} Saved`;
  }

  const surah = surahs.reduce((selected, item) => state.page >= item[5] ? item : selected, surahs[0]);
  if ($('homeResumeSurah')) {
    $('homeResumeSurah').innerHTML = `Surah ${surah[0]} <span class="arabic-name" id="homeResumeArabic">سُورَةُ ${surah[2]}</span>`;
  }
  if ($('homeResumeMeta')) {
    const juzNum = Math.min(30, Math.max(1, Math.ceil(state.page / 20)));
    $('homeResumeMeta').textContent = `Page ${state.page} • Juz ${juzNum} • ${surah[1]} (${surah[4]})`;
  }
  if ($('homeContinueBtn')) {
    $('homeContinueBtn').innerHTML = `<span>📖</span> Continue Reading (Page ${state.page})`;
  }

  // Update Reading rhythm
  updateStreak();
}

function updateStreak() {
  const today = dateKey();
  const dates = new Set(JSON.parse(localStorage.getItem('nur-reading-days') || '[]'));
  dates.add(today);
  const saved = [...dates].sort().slice(-90);
  localStorage.setItem('nur-reading-days', JSON.stringify(saved));

  let streak = 0;
  let cursor = new Date(`${today}T00:00:00`);
  while (saved.includes(dateKey(cursor))) {
    streak++;
    cursor.setDate(cursor.getDate() - 1);
  }

  if ($('badgeStreak')) {
    $('badgeStreak').textContent = `Streak: ${streak}d`;
  }
  if ($('streakCount')) $('streakCount').textContent = streak;
}

// -----------------------------------------------------------------------------
// 6. 15-LINE QURAN READER (Screenshot 1)
// -----------------------------------------------------------------------------
function openReader(surahIndex = null, syncHash = true) {
  // Always close mobile sidebar drawer and backdrop
  $('sidebar')?.classList.remove('open');
  $('sidebarBackdrop')?.classList.remove('active');

  if (surahIndex !== null) {
    const surah = surahs[surahIndex];
    if (surah) state.page = surah[5];
  }
  if (syncHash) {
    const targetHash = '#/quran/page/' + state.page;
    if (window.location.hash !== targetHash) {
      window.location.hash = targetHash;
      return;
    }
  }
  // Ensure Tafsir commentary drawer is closed so the Quran page opens full screen
  toggleTafsirDrawer(false);

  $('readerOverlay')?.classList.remove('hidden');
  document.body.style.overflow = 'hidden';
  syncResume();
  updateBookmarkButton();
  updateFavouriteButton();
  saveState();
  loadQuranPage(state.page);
}

function openReaderPage(page) {
  if (typeof saveCurrentPageAnnotation === 'function') {
    saveCurrentPageAnnotation();
  }
  state.page = Math.min(TOTAL_PAGES, Math.max(1, Number(page)));
  openReader(null, true);
}

function closeReader(syncHash = true) {
  if (typeof saveCurrentPageAnnotation === 'function') {
    saveCurrentPageAnnotation();
  }
  if (typeof toggleAnnotationSuite === 'function') {
    toggleAnnotationSuite(false);
  }
  $('readerOverlay')?.classList.add('hidden');
  document.body.style.overflow = '';
  updateKhatmTracker();
  if (syncHash && window.location.hash.includes('quran')) {
    window.location.hash = '/home';
  }
}

function navigatePage(step) {
  if (typeof saveCurrentPageAnnotation === 'function') {
    saveCurrentPageAnnotation();
  }
  state.page = Math.min(TOTAL_PAGES, Math.max(1, state.page + step));
  const mode = state.mode;
  const overlay = $('readerOverlay');
  if (overlay) {
    overlay.classList.remove('turn-next', 'turn-prev');
    if (mode === 'Page turn') {
      void overlay.offsetWidth;
      overlay.classList.add(step > 0 ? 'turn-next' : 'turn-prev');
    }
  }
  if (window.location.hash.startsWith('#/quran')) {
    history.replaceState(null, '', `#/quran/page/${state.page}`);
  }
  openReader(null, false);
}

function setReadingMode(mode) {
  state.mode = mode;
  localStorage.setItem('nur-mode', mode);
  $('btnModeSingle')?.classList.toggle('active', mode === 'Page slide');
  $('btnModeScroll')?.classList.toggle('active', mode === 'Scroll');
  $('btnModeTurn')?.classList.toggle('active', mode === 'Page turn');

  const overlay = $('readerOverlay');
  if (overlay) {
    overlay.setAttribute('data-mode', mode.toLowerCase().replace(' ', '-'));
  }
  showToast(`Reading Mode: ${mode}`);
}

function setFontScale(scale) {
  state.scale = scale;
  localStorage.setItem('nur-scale', scale);
  if ($('scaleSlider')) $('scaleSlider').value = scale;
  if ($('fontScaleDisplay')) $('fontScaleDisplay').textContent = `${scale}%`;

  const preview = $('scalePreview');
  if (preview) {
    preview.style.fontSize = `${26 * (scale / 100)}px`;
  }
  const frame = $('mushafBorderedFrame');
  if (frame) {
    frame.style.fontSize = `${scale}%`;
  }
}

const offlineFallbackPages = {
  1: {
    number: 1,
    ayahs: [
      { number: 1, text: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", numberInSurah: 1, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 2, text: "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ", numberInSurah: 2, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 3, text: "ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", numberInSurah: 3, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 4, text: "مَٰلِكِ يَوْمِ ٱلدِّينِ", numberInSurah: 4, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 5, text: "إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ", numberInSurah: 5, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 6, text: "ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ", numberInSurah: 6, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } },
      { number: 7, text: "صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ ٱلْمَغْضُوبِ عَلَيْهِمْ وَلَا ٱلضَّآلِّينَ", numberInSurah: 7, juz: 1, ruku: 1, surah: { number: 1, name: "سُورَةُ الفَاتِحَةِ", englishName: "Al-Fatihah" } }
    ]
  },
  2: {
    number: 2,
    ayahs: [
      { number: 8, text: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ", numberInSurah: 1, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } },
      { number: 9, text: "الٓمٓ", numberInSurah: 1, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } },
      { number: 10, text: "ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ ۛ هُدًۭى لِّلْمُتَّقِينَ", numberInSurah: 2, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } },
      { number: 11, text: "ٱلَّذِينَ يُؤْمِنُونَ بِٱلْغَيْبِ وَيُقِيمُونَ ٱلصَّلَوٰةَ وَمِمَّا رَزَقْنَٰهُمْ يُنفِقُونَ", numberInSurah: 3, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } },
      { number: 12, text: "وَٱلَّذِينَ يُؤْمِنُونَ بِمَآ أُنزِلَ إِلَيْكَ وَمَآ أُنزِلَ مِن قَبْلِكَ وَبِٱلْـَٔاخِرَةِ هُمْ يُوقِنُونَ", numberInSurah: 4, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } },
      { number: 13, text: "أُو۟لَٰٓئِكَ عَلَىٰ هُدًۭى مِّن رَّبِّهِمْ ۖ وَأُو۟لَٰٓئِكَ هُمُ ٱلْمُفْلِحُونَ", numberInSurah: 5, juz: 1, ruku: 1, surah: { number: 2, name: "سُورَةُ البَقَرَةِ", englishName: "Al-Baqarah" } }
    ]
  }
};

function updateReaderDeckUI() {
  const audio = $('quranAudio');
  const isPlaying = audio && !audio.paused;

  const playIcon = $('deckPlayIcon');
  const playLabel = $('deckPlayLabel');
  if (playIcon) {
    const playSvg = '<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" style="margin-left:2px;display:block;"><polygon points="6 4 20 12 6 20 6 4"/></svg>';
    const pauseSvg = '<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor" style="display:block;"><rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/></svg>';
    playIcon.innerHTML = isPlaying ? pauseSvg : playSvg;
  }
  if (playLabel) playLabel.textContent = isPlaying ? 'Pause' : 'Play';

  const speedVal = $('deckSpeedVal');
  if (speedVal && audio) {
    speedVal.textContent = `${audio.playbackRate || 1}x`;
  }

  const repeatNum = $('deckRepeatNum');
  if (repeatNum) {
    const r = $('audioRepeat')?.value || 'off';
    repeatNum.textContent = r === 'ayah' ? '1' : (r === 'page' ? 'P' : '0');
  }
}

async function loadQuranPage(page) {
  page = Math.min(TOTAL_PAGES, Math.max(1, Number(page) || 1));
  state.page = page;

  const pageImg = $('mushafPageImage');
  const pageSlider = $('pageSlider');
  const pageNumber = $('pageNumber');
  const pageBadge = $('readerPageBadge');
  const ribbon = $('mushafRibbonBookmark');

  // 1. Instant Authentic 15-Line Page Image Loading
  if (pageImg) {
    pageImg.classList.add('loading');
    pageImg.src = `assets/pages/${page}.webp`;
    pageImg.onload = () => {
      pageImg.classList.remove('loading');
      resizeAnnotationCanvas();
      loadPageAnnotation(page);
    };
    if (pageImg.complete) {
      pageImg.classList.remove('loading');
      resizeAnnotationCanvas();
      loadPageAnnotation(page);
    }
  }

  // Preload adjacent pages for zero-latency page flips
  if (page < TOTAL_PAGES) {
    const nextImg = new Image();
    nextImg.src = `assets/pages/${page + 1}.webp`;
  }
  if (page > 1) {
    const prevImg = new Image();
    prevImg.src = `assets/pages/${page - 1}.webp`;
  }

  // 2. Update Slider & Page Counters
  if (pageSlider) {
    pageSlider.max = TOTAL_PAGES;
    pageSlider.value = page;
  }
  if (pageNumber) pageNumber.textContent = page;
  if (pageBadge) pageBadge.textContent = `Page ${page} of ${TOTAL_PAGES}`;

  // 3. Ribbon Bookmark State
  const isBookmarked = state.bookmarks.includes(page);
  ribbon?.classList.toggle('bookmarked', isBookmarked);

  // 4. Update Khatm Tracker
  updateKhatmTracker();

  // 5. Update Surah & Juz Badges
  const currentJuz = getJuzForPage(page);
  const currentSurah = getSurahForPage(page);

  if ($('readerSurahBadge')) {
    $('readerSurahBadge').textContent = `سُورَةُ ${currentSurah.name} | ${currentSurah.englishName}`;
  }
  if ($('readerJuzBadge')) {
    $('readerJuzBadge').textContent = `Juz ${currentJuz.num}`;
  }
  if ($('readerRukuBadge')) {
    $('readerRukuBadge').textContent = `Ruku 1`;
  }

  // 6. Sync Bottom Audio Deck Track Info
  if ($('playerSurahNum')) $('playerSurahNum').textContent = toArabicDigits(currentSurah.number);
  if ($('playerSurahTitle')) $('playerSurahTitle').textContent = `سُورَةُ ${currentSurah.name}`;
  if ($('audioAyahLabel')) $('audioAyahLabel').textContent = `Surah ${currentSurah.englishName} · Page ${page}`;
  updateReaderDeckUI();

  // 7. Render Interactive 15-Line Ayah Overlay & Quick Selector Bar
  renderPageAyahOverlay(page);
}

const pageAyahsCache = {};

async function fetchAyahsForPage(page) {
  if (pageAyahsCache[page]) return pageAyahsCache[page];

  // 1. First Priority: Use authentic 611-page 15-line dataset from window.MUSHAF_15LINES_PAGES
  let rawList = null;
  if (typeof window !== 'undefined' && window.MUSHAF_15LINES_PAGES && window.MUSHAF_15LINES_PAGES[page]) {
    rawList = window.MUSHAF_15LINES_PAGES[page];
  } else {
    try {
      const res = await fetch('assets/data/page_ayahs_15lines.json');
      if (res.ok) {
        window.MUSHAF_15LINES_PAGES = await res.json();
        rawList = window.MUSHAF_15LINES_PAGES[page];
      }
    } catch (e) {}
  }

  if (rawList && rawList.length) {
    const mapped = rawList.map(item => {
      const sMeta = surahs[item.surah - 1] || [];
      return {
        number: item.id,
        numberInSurah: item.ayah,
        lines: item.lines || [],
        segments: item.segments || [],
        verseKey: item.verseKey || `${item.surah}:${item.ayah}`,
        text: '',
        surah: {
          number: item.surah,
          name: sMeta[2] ? sMeta[2].replace(/^سُورَةُ\s*/, '') : '',
          englishName: sMeta[0] || `Surah ${item.surah}`
        }
      };
    });
    pageAyahsCache[page] = mapped;
    return mapped;
  }

  // 2. Second Priority: Live API fetch for IndoPak 15-lines (Mushaf 6)
  if (page >= 2 && page <= 611) {
    const mushafPage = page - 1;
    try {
      const res = await fetch(`https://api.qurancdn.com/api/qdc/verses/by_page/${mushafPage}?mushaf=6&words=true&per_page=50`);
      if (res.ok) {
        const json = await res.json();
        if (json.verses && json.verses.length) {
          const mapped = json.verses.map(v => {
            const parts = (v.verse_key || '').split(':');
            const sNum = parseInt(parts[0], 10) || 1;
            const aNum = parseInt(parts[1], 10) || 1;
            const sMeta = surahs[sNum - 1] || [];
            const lines = [...new Set(v.words.map(w => w.line_number).filter(Boolean))].sort((a, b) => a - b);
            return {
              number: v.id,
              numberInSurah: aNum,
              lines: lines,
              verseKey: v.verse_key,
              text: '',
              surah: {
                number: sNum,
                name: sMeta[2] ? sMeta[2].replace(/^سُورَةُ\s*/, '') : '',
                englishName: sMeta[0] || `Surah ${sNum}`
              }
            };
          });
          pageAyahsCache[page] = mapped;
          return mapped;
        }
      }
    } catch (e) {}
  }

  // 3. Fallback to Surah ayahs
  const currentSurah = getSurahForPage(page);
  return [{
    number: surahStartAyahs[currentSurah.number - 1] || 1,
    numberInSurah: 1,
    lines: [1],
    verseKey: `${currentSurah.number}:1`,
    text: '',
    surah: { number: currentSurah.number, name: currentSurah.name, englishName: currentSurah.englishName }
  }];
}

function updatePlayingAyahProgress() {
  const audio = $('quranAudio');
  if (!audio || !audio.duration) return;
  const rawProgress = (audio.currentTime / audio.duration);
  if (isNaN(rawProgress)) return;

  const activeSegments = Array.from(document.querySelectorAll('.ayah-segment.playing, .lauh-cartouche-bismillah.playing, .ayah-line-band.playing'));
  if (!activeSegments.length) return;

  if (activeSegments.length === 1) {
    const pct = Math.min(100, Math.max(0, rawProgress * 100));
    activeSegments[0].style.setProperty('--prog', `${pct.toFixed(1)}%`);
    return;
  }

  // Multiple segments across lines - sort by line number ascending
  activeSegments.sort((a, b) => Number(a.dataset.line || 0) - Number(b.dataset.line || 0));

  const weights = activeSegments.map(el => {
    const wStr = el.style.width || '100%';
    const wVal = parseFloat(wStr) || 100;
    return Math.max(5, wVal);
  });
  const totalWeight = weights.reduce((acc, w) => acc + w, 0);

  let accumulated = 0;
  for (let i = 0; i < activeSegments.length; i++) {
    const startFrac = accumulated / totalWeight;
    accumulated += weights[i];
    const endFrac = accumulated / totalWeight;

    let segProg = 0;
    if (rawProgress >= endFrac) {
      segProg = 100;
    } else if (rawProgress <= startFrac) {
      segProg = 0;
    } else {
      segProg = ((rawProgress - startFrac) / (endFrac - startFrac)) * 100;
    }
    activeSegments[i].style.setProperty('--prog', `${Math.min(100, Math.max(0, segProg)).toFixed(1)}%`);
  }
}

function highlightPlayingAyah(number) {
  audioState.currentPlayingAyah = number;

  // Cleanly remove previous highlights from ALL elements and reset progress
  document.querySelectorAll('.playing').forEach(el => {
    el.classList.remove('playing');
    el.style.removeProperty('--prog');
  });

  if (!number) return;

  // 1. Highlight in the Ayah Quick Selector Bar
  const activePills = document.querySelectorAll(`.ayah-pill[data-ayah="${number}"]`);
  activePills.forEach(el => {
    el.classList.add('playing');
    el.scrollIntoView({ behavior: 'smooth', inline: 'nearest', block: 'nearest' });
  });

  // 2. Find and highlight exact sub-line ayah segments on the 15-line page
  const activeSegments = document.querySelectorAll(`.ayah-segment[data-ayah="${number}"]`);
  if (activeSegments.length) {
    activeSegments.forEach(el => {
      el.classList.add('playing');
      el.style.setProperty('--prog', '0%');
    });
  } else {
    // Fallback to line bands only if sub-line segments do not exist for this ayah
    const currentAyahObj = (audioState.ayahs || []).find(a => a.number === number);
    if (currentAyahObj && currentAyahObj.lines && currentAyahObj.lines.length) {
      currentAyahObj.lines.forEach(lineNum => {
        const bands = document.querySelectorAll(`.ayah-line-band[data-line="${lineNum}"]`);
        bands.forEach(b => {
          b.classList.add('playing');
          b.style.setProperty('--prog', '0%');
        });
      });
    }
  }

  // Initial progress update
  updatePlayingAyahProgress();
}

async function renderPageAyahOverlay(page) {
  const overlay = $('mushafAyahOverlay');
  const ayahBar = $('mushafAyahBar');
  if (!overlay) return;

  overlay.innerHTML = '';
  if (ayahBar) ayahBar.innerHTML = '';

  const ayahs = await fetchAyahsForPage(page);
  if (!ayahs || !ayahs.length) return;

  // Sync to audioState so recitation knows all ayahs on this page
  audioState.ayahs = ayahs;

  // Update Surah and Juz badges to reflect the actual starting ayah of this page
  if (ayahs[0] && ayahs[0].surah) {
    if ($('readerSurahBadge')) {
      $('readerSurahBadge').textContent = `سُورَةُ ${ayahs[0].surah.name} | ${ayahs[0].surah.englishName}`;
    }
    if ($('playerSurahTitle')) {
      $('playerSurahTitle').textContent = `سُورَةُ ${ayahs[0].surah.name}`;
    }
    if ($('playerSurahNum')) {
      $('playerSurahNum').textContent = toArabicDigits(ayahs[0].surah.number);
    }
  }

  // Title pages (page 1) don't have Quran ayahs
  if (page === 1) return;

  // Special Handling for Ornamental Frontispiece (Lauh) Opening Pages: Page 2 & Page 3
  if (page === 2 || page === 3) {
    overlay.classList.add('page-lauh-overlay');

    // 1. Line 0: Bismillah cartouche in the upper arch
    const bismillahLine = document.createElement('div');
    bismillahLine.className = 'mushaf-line-row lauh-bismillah-row';
    bismillahLine.dataset.line = '0';

    if (page === 2) {
      // For Surah Al-Fatihah, Bismillah is Ayah 1
      const ayah1 = ayahs.find(a => a.numberInSurah === 1);
      if (ayah1) {
        const segDiv = document.createElement('div');
        segDiv.className = 'ayah-segment lauh-cartouche-bismillah';
        segDiv.dataset.line = '0';
        segDiv.dataset.ayah = ayah1.number;
        segDiv.dataset.ayahInSurah = '1';
        segDiv.dataset.surah = '1';
        segDiv.style.right = '0%';
        segDiv.style.width = '100%';
        segDiv.title = `Ayah 1 (Bismillah) - Tap to play`;
        segDiv.addEventListener('click', (e) => {
          if (typeof annotState !== 'undefined' && annotState.isActive) return;
          e.stopPropagation();
          populateTafsirAyah(ayah1);
          highlightPlayingAyah(ayah1.number);
          playAyah(ayah1.number, true);
        });
        bismillahLine.appendChild(segDiv);
      }
    } else if (page === 3) {
      // For Surah Al-Baqarah, Bismillah is the opening invocation
      const segDiv = document.createElement('div');
      segDiv.className = 'ayah-segment lauh-cartouche-bismillah';
      segDiv.dataset.line = '0';
      segDiv.dataset.surah = '2';
      segDiv.style.right = '0%';
      segDiv.style.width = '100%';
      segDiv.title = `Bismillah - Surah Al-Baqarah`;
      segDiv.addEventListener('click', (e) => {
        if (typeof annotState !== 'undefined' && annotState.isActive) return;
        e.stopPropagation();
        const ayah1 = ayahs.find(a => a.numberInSurah === 1);
        if (ayah1) {
          populateTafsirAyah(ayah1);
          highlightPlayingAyah(ayah1.number);
          playAyah(ayah1.number, true);
        }
      });
      bismillahLine.appendChild(segDiv);
    }
    overlay.appendChild(bismillahLine);

    // 2. Lines 1 to 6 inside the lower bordered box
    for (let l = 1; l <= 6; l++) {
      const lineRow = document.createElement('div');
      lineRow.className = `mushaf-line-row lauh-line-row lauh-line-${l}`;
      lineRow.dataset.line = l;

      const segsOnLine = [];
      ayahs.forEach(ayah => {
        if (ayah.segments && ayah.segments.length) {
          ayah.segments.filter(s => s.line === l).forEach(s => {
            segsOnLine.push({ ayah, segment: s });
          });
        } else if (ayah.lines && ayah.lines.includes(l)) {
          segsOnLine.push({ ayah, segment: { line: l, right: 0, width: 100 } });
        }
      });

      if (!segsOnLine.length) {
        const emptyBand = document.createElement('div');
        emptyBand.className = 'ayah-segment empty-line';
        emptyBand.dataset.line = l;
        lineRow.appendChild(emptyBand);
      } else {
        segsOnLine.sort((a, b) => a.segment.right - b.segment.right);
        segsOnLine.forEach(({ ayah, segment }) => {
          const segDiv = document.createElement('div');
          segDiv.className = 'ayah-segment';
          segDiv.dataset.line = l;
          segDiv.dataset.ayah = ayah.number;
          segDiv.dataset.ayahInSurah = ayah.numberInSurah;
          segDiv.style.right = `${segment.right}%`;
          segDiv.style.width = `${segment.width}%`;
          segDiv.title = `Ayah ${ayah.numberInSurah} (${ayah.surah?.englishName || ''}) - Tap to play`;

          segDiv.addEventListener('click', (e) => {
            if (typeof annotState !== 'undefined' && annotState.isActive) return;
            e.stopPropagation();
            populateTafsirAyah(ayah);
            highlightPlayingAyah(ayah.number);
            playAyah(ayah.number, true);
          });

          lineRow.appendChild(segDiv);
        });
      }
      overlay.appendChild(lineRow);
    }
  } else {
    // Standard 15-line layout for pages 4 to 611
    overlay.classList.remove('page-lauh-overlay');

    for (let l = 1; l <= 15; l++) {
      const lineRow = document.createElement('div');
      lineRow.className = 'mushaf-line-row';
      lineRow.dataset.line = l;

      // Collect all ayah segments on line l
      const segsOnLine = [];
      ayahs.forEach(ayah => {
        if (ayah.segments && ayah.segments.length) {
          ayah.segments.filter(s => s.line === l).forEach(s => {
            segsOnLine.push({ ayah, segment: s });
          });
        } else if (ayah.lines && ayah.lines.includes(l)) {
          segsOnLine.push({ ayah, segment: { line: l, right: 0, width: 100 } });
        }
      });

      if (!segsOnLine.length) {
        // Empty decorative row (e.g. Surah title / Bismillah banner line)
        const emptyBand = document.createElement('div');
        emptyBand.className = 'ayah-segment empty-line';
        emptyBand.dataset.line = l;
        lineRow.appendChild(emptyBand);
      } else {
        // Sort segments from right (0%) to left
        segsOnLine.sort((a, b) => a.segment.right - b.segment.right);
        segsOnLine.forEach(({ ayah, segment }) => {
          const segDiv = document.createElement('div');
          segDiv.className = 'ayah-segment';
          segDiv.dataset.line = l;
          segDiv.dataset.ayah = ayah.number;
          segDiv.dataset.ayahInSurah = ayah.numberInSurah;
          segDiv.style.right = `${segment.right}%`;
          segDiv.style.width = `${segment.width}%`;
          segDiv.title = `Ayah ${ayah.numberInSurah} (${ayah.surah?.englishName || ''}) - Tap to play`;

          segDiv.addEventListener('click', (e) => {
            // If annotation mode is active, do not trigger audio click
            if (typeof annotState !== 'undefined' && annotState.isActive) return;
            e.stopPropagation();
            populateTafsirAyah(ayah);
            highlightPlayingAyah(ayah.number);
            playAyah(ayah.number, true);
          });

          lineRow.appendChild(segDiv);
        });
      }

      overlay.appendChild(lineRow);
    }
  }

  // Create interactive Quick Ayah Selector Pills
  if (ayahBar) {
    ayahs.forEach((ayah) => {
      const pill = document.createElement('button');
      pill.className = 'ayah-pill';
      pill.dataset.ayah = ayah.number;
      pill.dataset.ayahInSurah = ayah.numberInSurah;
      pill.innerHTML = `<span>Ayah ${ayah.numberInSurah}</span>`;
      pill.title = `Play Ayah ${ayah.numberInSurah} of ${ayah.surah?.englishName || ''}`;

      pill.addEventListener('click', (e) => {
        e.stopPropagation();
        populateTafsirAyah(ayah);
        highlightPlayingAyah(ayah.number);
        playAyah(ayah.number, true);
      });

      ayahBar.appendChild(pill);
    });
  }

  // Highlight currently playing ayah if already active
  if (audioState.currentPlayingAyah) {
    highlightPlayingAyah(audioState.currentPlayingAyah);
  }
}

// -----------------------------------------------------------------------------
// 7. AYAH CLICK INTERACTION & TAFSIR DRAWER
// -----------------------------------------------------------------------------
function renderAudioAyahControls() {
  document.querySelectorAll('.mushaf-ayah').forEach(el => {
    el.onclick = () => {
      const ayahNum = Number(el.dataset.ayah);
      const ayahObj = audioState.ayahs.find(a => a.number === ayahNum);
      if (ayahObj) {
        populateTafsirAyah(ayahObj);
        showAyahBubble(ayahObj, el);
      }
      playAyah(ayahNum, true);
    };
  });

  document.querySelectorAll('.ayah-marker').forEach(el => {
    el.onclick = (e) => {
      e.stopPropagation();
      const ayahNum = Number(el.dataset.ayah);
      const ayahObj = audioState.ayahs.find(a => a.number === ayahNum);
      if (ayahObj) {
        populateTafsirAyah(ayahObj);
        showAyahBubble(ayahObj, el);
      }
      playAyah(ayahNum, true);
    };
  });

  document.querySelectorAll('.bismillah-play').forEach(button => {
    button.onclick = (e) => {
      e.stopPropagation();
      playBismillah(Number(button.dataset.surah || 1), Number(button.dataset.ayah || 1));
    };
  });

  document.querySelectorAll('.lauh-cartouche-bismillah').forEach(el => {
    el.onclick = () => {
      playBismillah(Number(el.dataset.surah || 1), Number(el.dataset.ayah || 1));
    };
  });

  if (typeof loadPageAnnotation === 'function') {
    loadPageAnnotation(page);
  }
}

function showAyahBubble(ayah, targetEl) {
  const bubble = $('ayahActionBubble');
  if (!bubble || !targetEl) return;
  selectedAyahData = ayah;

  bubble.classList.remove('hidden');
  const targetOffset = targetEl.offsetTop;
  bubble.style.top = `${Math.max(10, targetOffset - 40)}px`;
  bubble.style.left = '50%';
  bubble.style.transform = 'translateX(-50%)';
}

function hideAyahBubble() {
  $('ayahActionBubble')?.classList.add('hidden');
}

function toggleTafsirDrawer(open = null) {
  const drawer = $('tafsirDrawer');
  if (!drawer) return;
  if (open === true) drawer.classList.remove('collapsed');
  else if (open === false) drawer.classList.add('collapsed');
  else drawer.classList.toggle('collapsed');
}

function populateTafsirAyah(ayah) {
  if (!ayah) return;
  selectedAyahData = ayah;

  const sName = ayah.surah ? (ayah.surah.englishName || ayah.surah.name) : '';
  if ($('tafsirTitle')) {
    $('tafsirTitle').textContent = `● Ayah Commentary · Surah ${sName} ${ayah.surah?.number || ''}:${ayah.numberInSurah}`;
  }
  if ($('tafsirArabicAyah')) {
    $('tafsirArabicAyah').textContent = ayah.text || '';
  }
  if ($('tafsirSummaryText')) {
    $('tafsirSummaryText').textContent = `Ayah ${ayah.numberInSurah} of Surah ${sName}. Classical Tafsir Al-Jalalayn highlights divine wisdom, providing timeless moral guidance, spiritual tranquility, and steadfast adherence to divine guidance.`;
  }
  if ($('noteText')) {
    const existing = state.notes[state.page] || '';
    $('noteText').value = existing;
  }
}

// -----------------------------------------------------------------------------
// 8. AUDIO RECITATION ENGINE WITH BISMILLAH SEQUENCING & MEDIA SESSION API
// -----------------------------------------------------------------------------
const bismillahAudioCache = {};

function updateMediaSession(title, artist, album) {
  if ('mediaSession' in navigator) {
    try {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: title || 'Al-Quran Al-Kareem',
        artist: artist || 'Qari Recitation',
        album: album || 'Holy Quran 15-Line Mushaf',
        artwork: [
          { src: 'icons/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icons/icon-512.png', sizes: '512x512', type: 'image/png' }
        ]
      });

      navigator.mediaSession.setActionHandler('play', () => {
        const audio = $('quranAudio');
        if (audio) {
          audio.play();
          if ($('audioPlay')) $('audioPlay').textContent = 'Ⅱ';
        }
      });
      navigator.mediaSession.setActionHandler('pause', () => {
        const audio = $('quranAudio');
        if (audio) {
          audio.pause();
          if ($('audioPlay')) $('audioPlay').textContent = '▶';
        }
      });
      navigator.mediaSession.setActionHandler('previoustrack', () => {
        if (audioState.index > 0) {
          playAyah(audioState.ayahs[audioState.index - 1].number, false);
        }
      });
      navigator.mediaSession.setActionHandler('nexttrack', () => {
        if (audioState.index < audioState.ayahs.length - 1) {
          playAyah(audioState.ayahs[audioState.index + 1].number, true);
        }
      });
      navigator.mediaSession.setActionHandler('seekto', (details) => {
        const audio = $('quranAudio');
        if (audio && details.seekTime !== undefined) {
          audio.currentTime = details.seekTime;
        }
      });
    } catch (e) {}
  }
}

async function getBismillahAudio(qari) {
  if (bismillahAudioCache[qari]) return bismillahAudioCache[qari];
  try {
    const res = await fetch(`https://api.alquran.cloud/v1/ayah/1/${qari}`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.data && data.data.audio) {
        bismillahAudioCache[qari] = data.data.audio;
        return data.data.audio;
      }
    }
  } catch (e) {}

  let fallback = `https://cdn.islamic.network/quran/audio/128/${qari}/1.mp3`;
  if (qari === 'ar.abdulbasitmurattal') {
    fallback = 'https://cdn.islamic.network/quran/audio/192/ar.abdulbasitmurattal/1.mp3';
  } else if (qari === 'ar.abdulsamad') {
    fallback = 'https://cdn.islamic.network/quran/audio/64/ar.abdulsamad/1.mp3';
  }
  bismillahAudioCache[qari] = fallback;
  return fallback;
}

async function playBismillah(surahNumber, thenAyahNumber) {
  audioState.isBismillah = true;
  audioState.bismillahSurah = surahNumber;
  audioState.pendingAyahNumber = thenAyahNumber;

  const surah = surahs[surahNumber - 1];
  const surahName = surah ? surah[0] : '';
  const qariObj = qarisData.find(q => q.id === audioState.qari);
  const qariName = qariObj ? qariObj.name : 'Al-Quran Audio';
  $('audioBar')?.classList.remove('hidden');

  if ($('audioAyahLabel')) $('audioAyahLabel').textContent = `Bismillah · Surah ${surahName}`;
  if ($('playerSurahTitle')) $('playerSurahTitle').textContent = `سُورَةُ ${surah ? surah[2] : ''}`;
  if ($('playerSurahNum')) $('playerSurahNum').textContent = toArabicDigits(surahNumber);

  document.querySelectorAll('.mushaf-ayah.playing, .bismillah-banner.playing, .lauh-cartouche-bismillah.playing').forEach(el => el.classList.remove('playing'));
  document.querySelectorAll(`.bismillah-banner[data-surah="${surahNumber}"], .lauh-cartouche-bismillah[data-surah="${surahNumber}"]`).forEach(el => el.classList.add('playing'));

  updateMediaSession(`Bismillah · Surah ${surahName}`, qariName, `Holy Quran · 15-Line Mushaf`);

  try {
    const bismillahUrl = await getBismillahAudio(audioState.qari);
    const audio = $('quranAudio');
    audio.src = bismillahUrl;
    audio.playbackRate = Number($('audioSpeed')?.value || 1);
    await audio.play();
    if ($('audioPlay')) $('audioPlay').textContent = 'Ⅱ';
  } catch (error) {
    audioState.isBismillah = false;
    if (thenAyahNumber) playAyah(thenAyahNumber, false);
  }
}

async function playAyah(number, withBismillah = true) {
  const current = audioState.ayahs.findIndex(a => a.number === number);
  if (current >= 0) audioState.index = current;
  const targetAyah = audioState.ayahs[current] || null;

  // Bismillah Auto-Play Rule:
  // Surah 1: Ayah 1 is Bismillah -> plays directly
  // Surahs 2 to 114 (except Surah 9): Ayah 1 auto-plays Bismillah first!
  // Surah 9: No Bismillah -> plays directly
  if (withBismillah && targetAyah && targetAyah.numberInSurah === 1 && targetAyah.surah && targetAyah.surah.number !== 1 && targetAyah.surah.number !== 9) {
    playBismillah(targetAyah.surah.number, number);
    return;
  }

  audioState.isBismillah = false;
  audioState.pendingAyahNumber = null;
  $('audioBar')?.classList.remove('hidden');

  if ($('audioAyahLabel')) $('audioAyahLabel').textContent = 'Loading recitation...';

  try {
    const response = await fetch(`https://api.alquran.cloud/v1/ayah/${number}/${audioState.qari}`);
    if (!response.ok) throw new Error('Audio unavailable');
    const result = await response.json();
    const audio = $('quranAudio');
    audio.src = result.data.audio;
    audio.playbackRate = Number($('audioSpeed')?.value || 1);
    await audio.play();

    const qariObj = qarisData.find(q => q.id === audioState.qari);
    const qariName = qariObj ? qariObj.name : 'Al-Quran Audio';

    if ($('audioAyahLabel')) $('audioAyahLabel').textContent = `Ayah ${result.data.numberInSurah} · ${result.data.surah.englishName}`;
    if ($('playerSurahTitle')) $('playerSurahTitle').textContent = `سُورَةُ ${(result.data.surah.name || '').replace(/^سُورَةُ\s*/, '')}`;
    if ($('playerSurahNum')) $('playerSurahNum').textContent = toArabicDigits(result.data.surah.number);
    if ($('audioPlay')) $('audioPlay').textContent = 'Ⅱ';

    highlightPlayingAyah(number);

    updateMediaSession(`Ayah ${result.data.numberInSurah} · ${result.data.surah.englishName}`, qariName, `Surah ${result.data.surah.englishName} (${result.data.surah.name})`);
  } catch (error) {
    if ($('audioAyahLabel')) $('audioAyahLabel').textContent = 'Audio unavailable. Try again.';
  }
}

async function handleAudioEnded() {
  const repeat = $('audioRepeat');
  const mode = repeat ? repeat.value : 'off';

  if (audioState.isBismillah) {
    audioState.isBismillah = false;
    const target = audioState.pendingAyahNumber;
    audioState.pendingAyahNumber = null;
    if (target) {
      playAyah(target, false);
      return;
    }
  }

  if (mode === 'ayah' && audioState.ayahs[audioState.index]) {
    playAyah(audioState.ayahs[audioState.index].number, false);
    return;
  }

  if (mode === 'page' && audioState.ayahs.length) {
    const next = audioState.index < audioState.ayahs.length - 1 ? audioState.index + 1 : 0;
    playAyah(audioState.ayahs[next].number, true);
    return;
  }

  // Continuous Recitation: Play next ayah on current page
  if (audioState.index < audioState.ayahs.length - 1) {
    playAyah(audioState.ayahs[audioState.index + 1].number, true);
  } else {
    // Current page ended: Automatically advance to the next page and continue playing!
    if (state.page < TOTAL_PAGES) {
      const nextPage = state.page + 1;
      const isReaderOpen = !$('readerOverlay')?.classList.contains('hidden');
      if (isReaderOpen) {
        navigatePage(1);
      } else {
        state.page = nextPage;
        saveState();
      }
      const nextAyahs = await fetchAyahsForPage(nextPage);
      if (nextAyahs && nextAyahs.length) {
        audioState.ayahs = nextAyahs;
        audioState.index = 0;
        playAyah(nextAyahs[0].number, true);
      } else {
        if ($('audioPlay')) $('audioPlay').textContent = '▶';
        highlightPlayingAyah(null);
      }
    } else {
      if ($('audioPlay')) $('audioPlay').textContent = '▶';
      highlightPlayingAyah(null);
    }
  }
}

// -----------------------------------------------------------------------------
// 8B. QURAN AUDIO STUDIO ENGINE (Screenshots 1 & 2 Fixes)
// -----------------------------------------------------------------------------
function initHeaderQariPopover() {
  const trigger = $('headerQariTrigger');
  const popover = $('headerQariPopover');
  const list = $('headerQariList');
  if (!trigger || !popover || !list) return;

  list.innerHTML = qarisData.map(q => `
    <div class="qari-popover-item ${q.id === audioState.qari ? 'active' : ''}" data-qari-id="${q.id}">
      <div class="qari-popover-avatar">🎙</div>
      <div class="qari-popover-info">
        <div class="qari-popover-name">${q.name}</div>
        <div class="qari-popover-sub"><span>${q.country}</span> • <b>${q.style}</b></div>
      </div>
      <div class="qari-popover-check">✓</div>
    </div>
  `).join('');

  list.querySelectorAll('.qari-popover-item').forEach(item => {
    item.onclick = (e) => {
      e.stopPropagation();
      setQari(item.dataset.qariId);
      popover.classList.add('hidden');
      trigger.classList.remove('open');
    };
  });

  trigger.onclick = (e) => {
    e.stopPropagation();
    const isOpen = !popover.classList.contains('hidden');
    if (isOpen) {
      popover.classList.add('hidden');
      trigger.classList.remove('open');
    } else {
      popover.classList.remove('hidden');
      trigger.classList.add('open');
    }
  };

  document.addEventListener('click', (e) => {
    if (!trigger.contains(e.target)) {
      popover.classList.add('hidden');
      trigger.classList.remove('open');
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      popover.classList.add('hidden');
      trigger.classList.remove('open');
    }
  });
}

function initReaderMoreSheet() {
  const sheet = $('readerMoreSheet');
  const backdrop = $('readerMoreBackdrop');
  const closeBtn = $('closeReaderMore');
  const moreBtn = $('deckMoreBtn');
  const grid = $('readerMoreQariGrid');
  const slider = $('readerMorePageSlider');
  const val = $('readerMorePageVal');
  const tafsirBtn = $('readerMoreTafsirBtn');
  const themeBtn = $('readerMoreThemeBtn');
  const exitBtn = $('readerMoreExitBtn');

  function openSheet() {
    if (!sheet || !backdrop) return;
    if (grid) {
      grid.innerHTML = qarisData.map(q => `
        <div class="reader-more-qari-card ${q.id === audioState.qari ? 'active' : ''}" data-qari-id="${q.id}">
          <div style="font-size:16px;">🎙️</div>
          <div style="flex:1;overflow:hidden;">
            <strong style="display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${q.name}</strong>
            <small style="color:var(--text-muted);font-size:10px;">${q.style}</small>
          </div>
        </div>
      `).join('');

      grid.querySelectorAll('.reader-more-qari-card').forEach(card => {
        card.onclick = () => {
          setQari(card.dataset.qariId);
          closeSheet();
        };
      });
    }

    if (slider && val) {
      slider.value = state.currentPage;
      val.textContent = `${state.currentPage} / 611`;
    }

    backdrop.classList.remove('hidden');
    sheet.classList.remove('hidden');
  }

  function closeSheet() {
    if (sheet) sheet.classList.add('hidden');
    if (backdrop) backdrop.classList.add('hidden');
  }

  moreBtn?.addEventListener('click', (e) => {
    e.stopPropagation();
    if (sheet && !sheet.classList.contains('hidden')) {
      closeSheet();
    } else {
      openSheet();
    }
  });

  closeBtn?.addEventListener('click', closeSheet);
  backdrop?.addEventListener('click', closeSheet);

  slider?.addEventListener('input', (e) => {
    if (val) val.textContent = `${e.target.value} / 611`;
  });

  slider?.addEventListener('change', (e) => {
    loadPage(Number(e.target.value));
    closeSheet();
  });

  tafsirBtn?.addEventListener('click', () => {
    closeSheet();
    toggleTafsirDrawer();
  });

  themeBtn?.addEventListener('click', () => {
    const nextTheme = state.theme === 'light' ? 'dark' : (state.theme === 'dark' ? 'parchment' : 'light');
    setTheme(nextTheme);
  });

  exitBtn?.addEventListener('click', () => {
    closeSheet();
    closeReader();
  });
}

function renderAudioStudio() {
  renderQariCards();
  updateMasterDeck(currentAudioSurahNum);
  renderAudioSurahs();
  bindAudioStudioControls();
}

function renderQariCards() {
  const grid = $('qariCardsGrid');
  if (!grid) return;

  grid.innerHTML = qarisData.map(q => `
    <div class="qari-card-v2 ${q.id === audioState.qari ? 'active' : ''}" data-qari-id="${q.id}">
      <div class="qari-card-avatar">🎙</div>
      <div class="qari-card-body">
        <div class="qari-card-name">${q.name}</div>
        <div class="qari-card-meta">
          <span class="qari-style-tag">${q.style}</span>
          <span>${q.country}</span>
        </div>
      </div>
    </div>
  `).join('');

  grid.querySelectorAll('.qari-card-v2').forEach(card => {
    card.onclick = () => {
      setQari(card.dataset.qariId);
    };
  });
}

function updateMasterDeck(surahNum) {
  currentAudioSurahNum = Math.min(114, Math.max(1, surahNum));
  const s = surahs[currentAudioSurahNum - 1];
  if (!s) return;

  const qari = qarisData.find(q => q.id === audioState.qari) || qarisData[0];

  if ($('deckSurahBadge')) $('deckSurahBadge').textContent = String(currentAudioSurahNum).padStart(3, '0');
  if ($('deckArabicTitle')) $('deckArabicTitle').textContent = `سُورَةُ ${s[2]}`;
  if ($('deckEnglishTitle')) {
    $('deckEnglishTitle').innerHTML = `${s[0]} <span class="deck-meaning-text" id="deckMeaningText">• ${s[1]}</span>`;
  }
  if ($('deckRevelationTag')) {
    const isMakki = s[4] === 'Meccan';
    $('deckRevelationTag').className = `revelation-tag ${isMakki ? 'makki' : 'madani'}`;
    $('deckRevelationTag').textContent = isMakki ? 'Makki' : 'Madani';
  }
  if ($('deckVersesCount')) $('deckVersesCount').textContent = `${s[3]} Verses`;
  if ($('deckPageNum')) $('deckPageNum').textContent = `Page ${s[5]}`;
  if ($('deckQariName')) $('deckQariName').textContent = `🎙 ${qari.name} (${qari.style})`;

  const audio = $('quranAudio');
  const isPlaying = audio && !audio.paused;
  if ($('deckPlayPause')) {
    $('deckPlayPause').textContent = isPlaying ? 'Ⅱ Pause Recitation' : '▶ Play Recitation';
  }
}

async function playSurahByNumber(surahNum) {
  surahNum = Math.min(114, Math.max(1, surahNum));
  currentAudioSurahNum = surahNum;
  updateMasterDeck(surahNum);

  const s = surahs[surahNum - 1];
  const qari = qarisData.find(q => q.id === audioState.qari) || qarisData[0];
  const startAyah = surahStartAyahs[surahNum - 1] || 1;

  if ($('deckStatusText')) {
    $('deckStatusText').textContent = `Preparing Surah ${s[0]} (${qari.name})...`;
  }

  try {
    const res = await fetch(`https://api.alquran.cloud/v1/surah/${surahNum}/${audioState.qari}`);
    if (res.ok) {
      const data = await res.json();
      if (data && data.data && data.data.ayahs && data.data.ayahs.length) {
        audioState.ayahs = data.data.ayahs;
        audioState.index = 0;
      }
    }
  } catch (e) {
    // Falls back to single-ayah fetch in playAyah
  }

  playAyah(startAyah, true);

  if ($('deckStatusText')) {
    $('deckStatusText').textContent = `Now Playing: Surah ${s[0]} · ${s[3]} Verses · ${qari.name}`;
  }
  if ($('deckPlayPause')) {
    $('deckPlayPause').textContent = 'Ⅱ Pause Recitation';
  }
}

function togglePlaySurah(surahNum) {
  const audio = $('quranAudio');
  if (audio && !audio.paused && currentAudioSurahNum === surahNum) {
    audio.pause();
    if ($('audioPlay')) $('audioPlay').textContent = '▶';
    if ($('deckPlayPause')) $('deckPlayPause').textContent = '▶ Resume Recitation';
    if ($('deckStatusText')) $('deckStatusText').textContent = 'Recitation paused.';
  } else {
    playSurahByNumber(surahNum);
  }
}

function renderAudioSurahs() {
  const grid = $('audioSurahsGrid');
  if (!grid) return;

  const query = ($('audioSurahSearch')?.value || '').trim().toLowerCase();

  let list = surahs.map((s, idx) => ({
    num: idx + 1,
    english: s[0],
    meaning: s[1],
    arabic: s[2],
    ayahs: s[3],
    type: s[4],
    page: s[5]
  }));

  if (currentAudioFilter === 'popular') {
    const popularNums = [1, 2, 18, 36, 55, 56, 67];
    list = list.filter(s => popularNums.includes(s.num));
  } else if (currentAudioFilter === 'juzAmma') {
    list = list.filter(s => s.num >= 78 && s.num <= 114);
  } else if (currentAudioFilter === 'makki') {
    list = list.filter(s => s.type === 'Meccan');
  } else if (currentAudioFilter === 'madani') {
    list = list.filter(s => s.type === 'Medinan');
  }

  if (query) {
    list = list.filter(s =>
      s.english.toLowerCase().includes(query) ||
      s.meaning.toLowerCase().includes(query) ||
      s.arabic.includes(query) ||
      String(s.num) === query
    );
  }

  if ($('audioSurahCount')) {
    $('audioSurahCount').textContent = list.length;
  }

  if (!list.length) {
    grid.innerHTML = '<div style="grid-column:1/-1;text-align:center;padding:40px 20px;color:var(--text-muted);font-size:14px;">No Surahs found matching your search.</div>';
    return;
  }

  grid.innerHTML = list.map(s => {
    const isMakki = s.type === 'Meccan';
    const badgeClass = isMakki ? 'makki' : 'madani';
    const badgeText = isMakki ? 'Makki' : 'Madani';
    const juzNum = Math.min(30, Math.max(1, Math.ceil(s.page / 20)));

    return `
      <div class="surah-card-v2" data-audio-surah="${s.num}">
        <div class="surah-card-v2-header">
          <div style="display:flex;align-items:flex-start;">
            <div class="surah-num-bubble">${String(s.num).padStart(3, '0')}</div>
            <div class="surah-title-meta">
              <strong>${s.english} <span class="revelation-tag ${badgeClass}">${badgeText}</span></strong>
              <small>${s.meaning}</small>
            </div>
          </div>
          <div class="surah-arabic-calligraphy">${s.arabic}</div>
        </div>
        <div class="surah-stats-triplet">
          <div><span>Verses</span><strong>${s.ayahs}</strong></div>
          <div><span>15-Line Page</span><strong>p. ${s.page}</strong></div>
          <div><span>Juz</span><strong>${juzNum}</strong></div>
        </div>
        <div class="surah-card-v2-footer">
          <button class="read-btn" onclick="openReaderPage(${s.page})"><span>📖</span> Read (p. ${s.page})</button>
          <button class="play-pill-btn" onclick="playSurahByNumber(${s.num})"><span>▶</span> Play Surah</button>
        </div>
      </div>
    `;
  }).join('');
}

let audioControlsBound = false;
function bindAudioStudioControls() {
  if (audioControlsBound) return;
  audioControlsBound = true;

  $('deckPlayPause')?.addEventListener('click', () => togglePlaySurah(currentAudioSurahNum));
  $('deckPrevSurah')?.addEventListener('click', () => {
    const prev = currentAudioSurahNum > 1 ? currentAudioSurahNum - 1 : 114;
    playSurahByNumber(prev);
  });
  $('deckNextSurah')?.addEventListener('click', () => {
    const next = currentAudioSurahNum < 114 ? currentAudioSurahNum + 1 : 1;
    playSurahByNumber(next);
  });
  $('deckReadMushaf')?.addEventListener('click', () => {
    const s = surahs[currentAudioSurahNum - 1];
    if (s) openReaderPage(s[5]);
  });

  $('audioSurahSearch')?.addEventListener('input', () => {
    renderAudioSurahs();
  });

  document.querySelectorAll('#audioSurahFilterPills .filter-pill').forEach(pill => {
    pill.onclick = () => {
      document.querySelectorAll('#audioSurahFilterPills .filter-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentAudioFilter = pill.dataset.audioFilter || 'all';
      renderAudioSurahs();
    };
  });
}

// -----------------------------------------------------------------------------
// 9. JUZ (PARAS), BOOKMARKS & RAMZAN DUAS ENGINE
// -----------------------------------------------------------------------------
const juzData = [
  { num: 1, arabic: 'الم', name: 'Alif Lam Mim', page: 1, surahs: 'Al-Fatihah 1 - Al-Baqarah 141' },
  { num: 2, arabic: 'سَيَقُولُ', name: 'Sayaqul', page: 23, surahs: 'Al-Baqarah 142 - Al-Baqarah 252' },
  { num: 3, arabic: 'تِلْكَ الرُّسُلُ', name: 'Tilkal Rusul', page: 43, surahs: 'Al-Baqarah 253 - Ali \'Imran 92' },
  { num: 4, arabic: 'لَنْ تَنَالُوا', name: 'Lan Tanalu', page: 63, surahs: 'Ali \'Imran 93 - An-Nisa 23' },
  { num: 5, arabic: 'وَالْمُحْصَنَاتُ', name: 'Wal Muhsanat', page: 83, surahs: 'An-Nisa 24 - An-Nisa 147' },
  { num: 6, arabic: 'لَا يُحِبُّ اللَّهُ', name: 'La Yuhibbullah', page: 103, surahs: 'An-Nisa 148 - Al-Ma\'idah 81' },
  { num: 7, arabic: 'وَإِذَا سَمِعُوا', name: 'Wa Iza Sami\'u', page: 123, surahs: 'Al-Ma\'idah 82 - Al-An\'am 110' },
  { num: 8, arabic: 'وَلَوْ أَنَّنَا', name: 'Wa Lau Annana', page: 143, surahs: 'Al-An\'am 111 - Al-A\'raf 87' },
  { num: 9, arabic: 'قَالَ الْمَلَأُ', name: 'Qalal Mala\'u', page: 163, surahs: 'Al-A\'raf 88 - Al-Anfal 40' },
  { num: 10, arabic: 'وَاعْلَمُوا', name: 'Wa\'lamu', page: 183, surahs: 'Al-Anfal 41 - At-Tawbah 92' },
  { num: 11, arabic: 'يَعْتَذِرُونَ', name: 'Ya\'taziroon', page: 203, surahs: 'At-Tawbah 93 - Hud 5' },
  { num: 12, arabic: 'وَمَا مِنْ دَابَّةٍ', name: 'Wa Ma Min Dabbah', page: 223, surahs: 'Hud 6 - Yusuf 52' },
  { num: 13, arabic: 'وَمَا أُبَرِّئُ', name: 'Wa Ma Ubarri\'u', page: 243, surahs: 'Yusuf 53 - Ibrahim 52' },
  { num: 14, arabic: 'رُبَمَا', name: 'Rubama', page: 263, surahs: 'Al-Hijr 1 - An-Nahl 128' },
  { num: 15, arabic: 'سُبْحَانَ الَّذِي', name: 'Subhanalladhi', page: 283, surahs: 'Al-Isra 1 - Al-Kahf 74' },
  { num: 16, arabic: 'قَالَ أَلَمْ', name: 'Qala Alam', page: 303, surahs: 'Al-Kahf 75 - Ta-Ha 135' },
  { num: 17, arabic: 'اقْتَرَبَ', name: 'Iqtaraba', page: 323, surahs: 'Al-Anbiya 1 - Al-Hajj 78' },
  { num: 18, arabic: 'قَدْ أَفْلَحَ', name: 'Qad Aflaha', page: 343, surahs: 'Al-Mu\'minun 1 - Al-Furqan 20' },
  { num: 19, arabic: 'وَقَالَ الَّذِينَ', name: 'Wa Qalalladhina', page: 363, surahs: 'Al-Furqan 21 - An-Naml 55' },
  { num: 20, arabic: 'أَمَّنْ خَلَقَ', name: 'Amman Khalaqa', page: 383, surahs: 'An-Naml 56 - Al-\'Ankabut 45' },
  { num: 21, arabic: 'اتْلُ مَا أُوحِيَ', name: 'Utlu Ma Oohiya', page: 403, surahs: 'Al-\'Ankabut 46 - Al-Ahzab 30' },
  { num: 22, arabic: 'وَمَنْ يَقْنُتْ', name: 'Wa Manyaqnut', page: 423, surahs: 'Al-Ahzab 31 - Ya-Sin 27' },
  { num: 23, arabic: 'وَمَا لِيَ', name: 'Wa Maliya', page: 443, surahs: 'Ya-Sin 28 - Az-Zumar 31' },
  { num: 24, arabic: 'فَمَنْ أَظْلَمُ', name: 'Faman Azlamu', page: 463, surahs: 'Az-Zumar 32 - Fussilat 46' },
  { num: 25, arabic: 'إِلَيْهِ يُرَدُّ', name: 'Ilayhi Yuraddu', page: 483, surahs: 'Fussilat 47 - Al-Jathiyah 37' },
  { num: 26, arabic: 'حم', name: 'Ha Mim', page: 503, surahs: 'Al-Ahqaf 1 - Adh-Dhariyat 30' },
  { num: 27, arabic: 'قَالَ فَمَا خَطْبُكُمْ', name: 'Qala Fama Khatbukum', page: 523, surahs: 'Adh-Dhariyat 31 - Al-Hadid 29' },
  { num: 28, arabic: 'قَدْ سَمِعَ اللَّهُ', name: 'Qad Sami\'allah', page: 543, surahs: 'Al-Mujadila 1 - At-Tahrim 12' },
  { num: 29, arabic: 'تَبَارَكَ الَّذِي', name: 'Tabarakalladhi', page: 563, surahs: 'Al-Mulk 1 - Al-Mursalat 50' },
  { num: 30, arabic: 'عَمَّ', name: 'Amma', page: 587, surahs: 'An-Naba 1 - An-Nas 6' }
];

function getJuzForPage(page) {
  for (let i = juzData.length - 1; i >= 0; i--) {
    if (page >= juzData[i].page) {
      return juzData[i];
    }
  }
  return juzData[0];
}

function getSurahForPage(page) {
  for (let i = startPages.length - 1; i >= 0; i--) {
    if (page >= startPages[i]) {
      const s = surahs[i];
      return {
        number: i + 1,
        englishName: s[0],
        meaning: s[1],
        name: s[2].replace(/^سُورَةُ\s*/, ''),
        ayahs: s[3],
        type: s[4]
      };
    }
  }
  return {
    number: 1,
    englishName: 'Al-Fatihah',
    meaning: 'The Opener',
    name: 'الفاتحة',
    ayahs: 7,
    type: 'Meccan'
  };
}

let currentJuzFilter = 'all';

function renderJuz() {
  const grid = $('juzGrid');
  if (!grid) return;

  const query = ($('juzSearch')?.value || '').trim().toLowerCase();

  let list = [...juzData];

  if (currentJuzFilter === 'part1') {
    list = list.filter(j => j.num >= 1 && j.num <= 10);
  } else if (currentJuzFilter === 'part2') {
    list = list.filter(j => j.num >= 11 && j.num <= 20);
  } else if (currentJuzFilter === 'part3') {
    list = list.filter(j => j.num >= 21 && j.num <= 30);
  }

  if (query) {
    list = list.filter(j =>
      j.name.toLowerCase().includes(query) ||
      j.arabic.includes(query) ||
      String(j.num) === query ||
      j.surahs.toLowerCase().includes(query)
    );
  }

  if ($('juzCountText')) {
    $('juzCountText').textContent = list.length;
  }

  grid.innerHTML = list.map(j => {
    const isBookmarked = state.bookmarks.includes(j.page);
    return `
      <div class="juz-card-v2" data-juz-num="${j.num}">
        <div class="juz-card-v2-header">
          <div style="display:flex;align-items:flex-start;">
            <div class="juz-num-bubble">${String(j.num).padStart(2, '0')}</div>
            <div class="juz-title-meta">
              <strong>Juz ${j.num} <small style="font-weight:normal;color:var(--text-muted);">(Para ${j.num})</small></strong>
              <small>${j.name}</small>
            </div>
          </div>
          <div class="juz-arabic-calligraphy">${j.arabic}</div>
        </div>
        <div class="juz-stats-triplet">
          <div><span>Start Page</span><strong>p. ${j.page}</strong></div>
          <div><span>Length</span><strong>20 Pages</strong></div>
          <div><span>Ahzab</span><strong>2 Hizb</strong></div>
        </div>
        <div style="font-size:11px;color:var(--text-secondary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
          📖 ${j.surahs}
        </div>
        <div class="juz-card-v2-footer">
          <button class="read-btn" data-open-juz-page="${j.page}"><span>📖</span> Read Juz (p. ${j.page})</button>
          <button class="icon-action-btn" data-play-juz-page="${j.page}" title="Listen Juz ${j.num}">▶</button>
          <button class="icon-action-btn ${isBookmarked ? 'bookmarked' : ''}" data-bookmark-juz-page="${j.page}" title="Bookmark Page ${j.page}">${isBookmarked ? '★' : '⚑'}</button>
        </div>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('[data-open-juz-page]').forEach(btn => {
    btn.onclick = () => openReaderPage(Number(btn.dataset.openJuzPage));
  });
  grid.querySelectorAll('[data-play-juz-page]').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      openReaderPage(Number(btn.dataset.playJuzPage));
      setTimeout(() => {
        if (audioState.ayahs.length) playAyah(audioState.ayahs[0].number, true);
      }, 500);
    };
  });
  grid.querySelectorAll('[data-bookmark-juz-page]').forEach(btn => {
    btn.onclick = (e) => {
      e.stopPropagation();
      const p = Number(btn.dataset.bookmarkJuzPage);
      if (!state.bookmarks.includes(p)) {
        state.bookmarks.push(p);
        showToast(`Juz start page ${p} bookmarked`);
      } else {
        state.bookmarks = state.bookmarks.filter(x => x !== p);
        showToast(`Page ${p} removed from bookmarks`);
      }
      saveState();
      renderJuz();
      updateBookmarkButton();
      updateKhatmTracker();
    };
  });
}

function openJuz(juz) {
  const item = juzData[juz - 1];
  if (item) {
    openReaderPage(item.page);
  } else {
    openReaderPage(1);
  }
}

// -----------------------------------------------------------------------------
// BOOKMARKS & SAVED ENGINE
// -----------------------------------------------------------------------------
let currentBookmarkFilter = 'all';

function renderBookmarks() {
  const list = $('bookmarkList');
  const empty = $('bookmarkEmpty');
  if (!list) return;

  const countPages = state.bookmarks.length;
  const notesCount = Object.keys(state.notes || {}).length;
  const totalCount = countPages + notesCount;

  if ($('badgeTotalBookmarks')) $('badgeTotalBookmarks').textContent = `⚑ ${countPages} Saved Pages`;
  if ($('badgeTotalNotes')) $('badgeTotalNotes').textContent = `📝 ${notesCount} Private Notes`;
  if ($('countBookmarksAll')) $('countBookmarksAll').textContent = totalCount;
  if ($('countBookmarksPages')) $('countBookmarksPages').textContent = countPages;
  if ($('countBookmarksNotes')) $('countBookmarksNotes').textContent = notesCount;

  let displayPages = [...state.bookmarks];
  if (currentBookmarkFilter === 'notes') {
    displayPages = Object.keys(state.notes).map(Number);
  } else if (currentBookmarkFilter === 'pages') {
    displayPages = [...state.bookmarks];
  } else {
    displayPages = [...new Set([...state.bookmarks, ...Object.keys(state.notes).map(Number)])];
  }
  displayPages.sort((a, b) => a - b);

  if (!displayPages.length) {
    if (empty) empty.classList.remove('hidden');
    list.classList.add('hidden');
    return;
  }

  if (empty) empty.classList.add('hidden');
  list.classList.remove('hidden');

  list.innerHTML = displayPages.map(page => {
    const surah = surahs.reduce((selected, item) => page >= item[5] ? item : selected, surahs[0]);
    const juzNum = Math.min(30, Math.max(1, Math.ceil(page / 20)));
    const note = state.notes[page];

    return `
      <div class="bookmark-card-v2">
        <div class="bookmark-card-header">
          <div>
            <span class="bookmark-page-badge">PAGE ${page}</span>
            <strong style="font-size:15px;display:block;margin-top:6px;color:var(--text-primary);">${surah[0]}</strong>
            <small style="color:var(--text-muted);">${surah[4]} · Juz ${juzNum}</small>
          </div>
          <div style="font-family:'Amiri',serif;font-size:22px;color:var(--primary);">${surah[2]}</div>
        </div>
        ${note ? `<div class="bookmark-note-preview">“${escapeHtml(note)}”</div>` : ''}
        <div style="display:flex;justify-content:space-between;align-items:center;padding-top:10px;border-top:1px solid var(--border-line);">
          <button class="btn-primary-green" style="padding:6px 14px;font-size:12px;" data-open-bm="${page}"><span>📖</span> Open Page ${page}</button>
          <button class="btn-outline-green" style="padding:6px 12px;font-size:11px;color:var(--accent-coral);border-color:var(--border-line);" data-delete-bm="${page}" title="Remove Bookmark">🗑 Remove</button>
        </div>
      </div>
    `;
  }).join('');

  list.querySelectorAll('[data-open-bm]').forEach(btn => {
    btn.onclick = () => openReaderPage(Number(btn.dataset.openBm));
  });
  list.querySelectorAll('[data-delete-bm]').forEach(btn => {
    btn.onclick = () => {
      const p = Number(btn.dataset.deleteBm);
      state.bookmarks = state.bookmarks.filter(x => x !== p);
      delete state.notes[p];
      saveState();
      renderBookmarks();
      updateBookmarkButton();
      updateKhatmTracker();
      showToast(`Page ${p} removed`);
    };
  });
}

function updateBookmarkButton() {
  const btn = $('readerBookmark');
  if (!btn) return;
  const isSaved = state.bookmarks.includes(state.page);
  btn.classList.toggle('saved', isSaved);
  btn.textContent = isSaved ? '★' : '⚑';
}

function updateFavouriteButton() {
  const btn = $('readerFavourite');
  if (!btn) return;
  const isSaved = state.favourites.includes(state.page);
  btn.classList.toggle('saved', isSaved);
}

// -----------------------------------------------------------------------------
// RAMZAN & SACRED DUAS ENGINE
// -----------------------------------------------------------------------------
const sacredDuas = [
  {
    id: 1,
    category: 'fasting',
    title: 'Sehri Ki Dua (Fasting Intention)',
    tag: 'Sehri / Suhoor',
    arabic: 'وَبِصَوْمِ غَدٍ نَّوَيْتُ مِنْ شَهْرِ رَمَضَانَ',
    transliteration: 'Wa bisawmi ghadin nawaytu min shahri ramadan.',
    translation: '“And I intend to keep the fast tomorrow for the month of Ramadan.”',
    pageRef: null
  },
  {
    id: 2,
    category: 'fasting',
    title: 'Iftar Ki Dua (Breaking the Fast)',
    tag: 'Iftar Time',
    arabic: 'اللَّهُمَّ إِنِّي لَكَ صُمْتُ وَبِكَ آمَنْتُ وَعَلَيْكَ تَوَكَّلْتُ وَعَلَىٰ رِزْقِكَ أَفْطَرْتُ',
    transliteration: 'Allahumma inni laka sumtu wa bika aamantu wa \'alayka tawakkaltu wa \'ala rizqika aftartu.',
    translation: '“O Allah, I fasted for You and I believe in You and I put my trust in You and with Your sustenance I break my fast.”',
    pageRef: null
  },
  {
    id: 3,
    category: 'ashra',
    title: '1st Ashra Dua (Days 1–10 • Pehla Ashra - Rahmat)',
    tag: 'Mercy • رحمت',
    arabic: 'رَبِّ اغْفِرْ وَارْحَمْ وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
    transliteration: 'Rabbighfir warham wa Anta khayrur-rahimeen.',
    translation: '“My Lord, forgive and have mercy, and You are the best of the merciful.” (Surah Al-Mu\'minun 23:118)',
    pageRef: 349
  },
  {
    id: 4,
    category: 'ashra',
    title: '2nd Ashra Dua (Days 11–20 • Dusra Ashra - Maghfirat)',
    tag: 'Forgiveness • مغفرت',
    arabic: 'أَسْتَغْفِرُ اللَّهَ رَبِّي مِنْ كُلِّ ذَنْبٍ وَأَتُوبُ إِلَيْهِ',
    transliteration: 'Astaghfirullah Rabbi min kulli dhambinw-wa atoobu ilayh.',
    translation: '“I ask forgiveness of Allah, my Lord, from every sin, and I turn to Him in repentance.”',
    pageRef: null
  },
  {
    id: 5,
    category: 'ashra',
    title: '3rd Ashra Dua (Days 21–30 • Teesra Ashra - Nijat)',
    tag: 'Safety • نجات',
    arabic: 'اللَّهُمَّ أَجِرْنِي مِنَ النَّارِ',
    transliteration: 'Allahumma ajirni minan-naar.',
    translation: '“O Allah, protect and save me from the fire of Hell.”',
    pageRef: null
  },
  {
    id: 6,
    category: 'ashra',
    title: 'Laylatul Qadr Special Dua (شبِ قدر)',
    tag: 'Night of Decree',
    arabic: 'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    transliteration: 'Allahumma innaka \'Afuwwun tuhibbul-\'afwa fa\'fu \'anni.',
    translation: '“O Allah, You are Most Forgiving, and You love forgiveness; so forgive me.” (Sunan al-Tirmidhi 3513)',
    pageRef: null
  },
  {
    id: 7,
    category: 'quranic',
    title: 'Rabbana Dua: Goodness in Both Worlds',
    tag: 'Surah Al-Baqarah 2:201',
    arabic: 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    transliteration: 'Rabbana aatina fid-dunya hasanatanw-wa fil-akhirati hasanatanw-wa qina \'adhaban-naar.',
    translation: '“Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire.”',
    pageRef: 31
  },
  {
    id: 8,
    category: 'quranic',
    title: 'Rabbana Dua: Protection of Guidance',
    tag: 'Surah Ali \'Imran 3:8',
    arabic: 'رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
    transliteration: 'Rabbana la tuzigh quloobana ba\'da idh hadaytana wa hab lana mil-ladunka rahmah, innaka Antal-Wahhab.',
    translation: '“Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower.”',
    pageRef: 50
  }
];

let currentDuaTab = 'all';

function renderRamadanDuas() {
  const grid = $('duasGrid');
  const planner = $('khatamPlannerSection');
  if (!grid) return;

  if (currentDuaTab === 'planner') {
    grid.classList.add('hidden');
    if (planner) planner.classList.remove('hidden');
    renderKhatamPlanner();
    return;
  }

  grid.classList.remove('hidden');
  if (planner) planner.classList.add('hidden');

  const filtered = currentDuaTab === 'all'
    ? sacredDuas
    : sacredDuas.filter(d => d.category === currentDuaTab);

  grid.innerHTML = filtered.map(d => `
    <div class="dua-card-v2">
      <div class="dua-header-tag">
        <strong style="font-size:14px;color:var(--text-primary);">${d.title}</strong>
        <span class="dua-badge-tag">${d.tag}</span>
      </div>
      <div class="dua-arabic-box">${d.arabic}</div>
      <div class="dua-transliteration">${d.transliteration}</div>
      <div class="dua-translation">${d.translation}</div>
      <div class="dua-card-footer">
        <button class="btn-outline-green" style="padding:5px 12px;font-size:11px;" data-copy-dua="${d.id}">📋 Copy Dua</button>
        ${d.pageRef ? `<button class="btn-primary-green" style="padding:5px 12px;font-size:11px;" data-open-dua-page="${d.pageRef}">📖 Read in Quran (p. ${d.pageRef})</button>` : ''}
      </div>
    </div>
  `).join('');

  grid.querySelectorAll('[data-copy-dua]').forEach(btn => {
    btn.onclick = () => {
      const id = Number(btn.dataset.copyDua);
      const dua = sacredDuas.find(d => d.id === id);
      if (dua && navigator.clipboard) {
        navigator.clipboard.writeText(`${dua.arabic}\n\n${dua.transliteration}\n\n${dua.translation}`);
        showToast('Dua copied to clipboard');
      }
    };
  });

  grid.querySelectorAll('[data-open-dua-page]').forEach(btn => {
    btn.onclick = () => openReaderPage(Number(btn.dataset.openDuaPage));
  });
}

function renderKhatamPlanner() {
  const grid = $('plannerDaysGrid');
  if (!grid) return;

  const completedDays = JSON.parse(localStorage.getItem('nur-ramadan-planner') || '[]');
  if ($('plannerCompletedCount')) {
    $('plannerCompletedCount').textContent = `${completedDays.length} / 30`;
  }

  grid.innerHTML = Array.from({ length: 30 }, (_, i) => {
    const day = i + 1;
    const juz = juzData[i];
    const isDone = completedDays.includes(day);
    const startP = juz.page;
    const endP = day === 30 ? TOTAL_PAGES : juzData[i + 1].page - 1;

    return `
      <div class="planner-day-card ${isDone ? 'completed' : ''}" data-planner-day="${day}">
        <div class="planner-day-top">
          <span>Day ${day}</span>
          <span style="font-weight:bold;">${isDone ? '✔' : '○'}</span>
        </div>
        <strong>Juz ${day} (${juz.arabic})</strong>
        <small>p. ${startP}–${endP}</small>
      </div>
    `;
  }).join('');

  grid.querySelectorAll('[data-planner-day]').forEach(card => {
    card.onclick = () => {
      const day = Number(card.dataset.plannerDay);
      let list = JSON.parse(localStorage.getItem('nur-ramadan-planner') || '[]');
      if (list.includes(day)) list = list.filter(d => d !== day);
      else list.push(day);
      localStorage.setItem('nur-ramadan-planner', JSON.stringify(list));
      renderKhatamPlanner();
      showToast(`Day ${day} ${list.includes(day) ? 'marked completed' : 'unmarked'}`);
    };
  });
}

async function handleSearch(query) {
  const request = ++searchRequest;
  const resultsEl = $('searchResults');
  if (!resultsEl) return;

  if (!query || query.length < 3) {
    resultsEl.classList.add('hidden');
    return;
  }

  resultsEl.classList.remove('hidden');
  resultsEl.innerHTML = '<div style="padding:20px;text-align:center;color:var(--text-muted);">Searching verified Quran text...</div>';

  try {
    const response = await fetch(`https://api.alquran.cloud/v1/search/${encodeURIComponent(query)}/all/quran-uthmani`);
    if (request !== searchRequest) return;
    if (!response.ok) throw new Error('Search unavailable');
    const result = await response.json();
    const matches = result.data && result.data.matches || [];

    if (!matches.length) {
      resultsEl.innerHTML = '<div style="padding:20px;text-align:center;color:var(--text-muted);">No verses found.</div>';
      return;
    }

    resultsEl.innerHTML = matches.slice(0, 30).map(match => `
      <button class="search-result" data-search-surah="${match.surah.number}" data-search-ayah="${match.numberInSurah}">
        <span class="search-result-meta">${match.surah.englishName} (${match.surah.name}) · Ayah ${match.numberInSurah}</span>
        <strong>${escapeHtml(match.text)}</strong>
      </button>
    `).join('');

    resultsEl.querySelectorAll('[data-search-surah]').forEach(btn => {
      btn.onclick = () => {
        const sNum = Number(btn.dataset.searchSurah);
        const surah = surahs[sNum - 1];
        if (surah) {
          openReaderPage(surah[5]);
        }
      };
    });
  } catch (err) {
    if (request !== searchRequest) return;
    resultsEl.innerHTML = '<div style="padding:20px;text-align:center;color:var(--accent-coral);">Search could not connect. Check network.</div>';
  }
}

// -----------------------------------------------------------------------------
// 10. BACKUP & DATA PORTABILITY
// -----------------------------------------------------------------------------
function exportBackup() {
  const backup = {
    format: 'nur-quran-backup',
    version: '2.4',
    createdAt: new Date().toISOString(),
    data: {
      page: state.page,
      bookmarks: state.bookmarks,
      favourites: state.favourites,
      notes: state.notes,
      theme: state.theme,
      mode: state.mode,
      qari: audioState.qari,
      scale: state.scale,
      readingDays: JSON.parse(localStorage.getItem('nur-reading-days') || '[]')
    }
  };

  const file = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(file);
  link.download = `nur-quran-backup-${dateKey()}.json`;
  link.click();
  URL.revokeObjectURL(link.href);
  showToast('Backup JSON exported successfully');
}

function restoreBackup(file) {
  const reader = new FileReader();
  reader.onload = () => {
    try {
      const backup = JSON.parse(reader.result);
      if (!backup.data) throw new Error('Invalid backup file');
      if (!confirm('Restore this backup and replace current reading data?')) return;

      const data = backup.data;
      state.page = Number(data.page) || 2;
      state.bookmarks = Array.isArray(data.bookmarks) ? data.bookmarks : [];
      state.favourites = Array.isArray(data.favourites) ? data.favourites : [];
      state.notes = data.notes && typeof data.notes === 'object' ? data.notes : {};
      state.theme = data.theme || 'emerald';
      state.mode = data.mode || 'Page slide';
      state.scale = Number(data.scale) || 100;
      audioState.qari = data.qari || 'ar.alafasy';

      saveState();
      setTheme(state.theme);
      setQari(audioState.qari);
      setReadingMode(state.mode);
      setFontScale(state.scale);
      updateKhatmTracker();

      showToast('Backup restored successfully!');
      setTimeout(() => location.reload(), 600);
    } catch (e) {
      showToast('Failed to restore: Invalid backup JSON');
    }
  };
  reader.readAsText(file);
}

function renderBackupView() {
  if ($('exportBmCount')) $('exportBmCount').textContent = state.bookmarks.length;
  if ($('exportNotesCount')) $('exportNotesCount').textContent = Object.keys(state.notes).length;
  if ($('exportFavsCount')) $('exportFavsCount').textContent = state.favourites.length;
  if ($('exportPageNum')) $('exportPageNum').textContent = `p. ${state.page}`;
}

function initBackupDropzone() {
  const dropzone = $('backupDropzone');
  const fileInput = $('dedicatedImportFile');
  if (!dropzone || !fileInput) return;

  ['dragenter', 'dragover'].forEach(eventName => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      dropzone.style.borderColor = 'var(--primary)';
      dropzone.style.background = 'var(--primary-subtle)';
    });
  });

  ['dragleave', 'drop'].forEach(eventName => {
    dropzone.addEventListener(eventName, (e) => {
      e.preventDefault();
      dropzone.style.borderColor = 'var(--border-line)';
      dropzone.style.background = 'var(--bg-card-subtle)';
    });
  });

  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    const dt = e.dataTransfer;
    if (dt && dt.files && dt.files.length > 0) {
      restoreBackup(dt.files[0]);
    }
  });

  fileInput.addEventListener('change', (e) => {
    if (e.target.files && e.target.files[0]) {
      restoreBackup(e.target.files[0]);
    }
  });
}

// -----------------------------------------------------------------------------
// FAQ DATA & ACCORDION
// -----------------------------------------------------------------------------
const faqs = [
  {
    q: "What makes the 15-line Quran format special?",
    a: "The 15-line Quran (Mushaf) is the gold standard used by Huffaz across Pakistan, India, Turkey, and South Asia. Every single page starts precisely at the beginning of an Ayah and ends at the end of an Ayah (known as Ayat-al-Hifz). It spans exactly 611 pages, with each Juz occupying roughly 20 pages, making memorization structured and predictable."
  },
  {
    q: "Why does Surah At-Tawbah (Surah 9) not have a Bismillah?",
    a: "Surah At-Tawbah does not begin with Bismillah as ordained by the Prophet Muhammad ﷺ and recorded by his companions. Scholars note that it begins with a declaration of disavowal toward treaty-breakers, whereas Bismillah is an invocation of divine mercy and peace. In Nūr Al-Quran, audio recitation respects this authenticity by omitting the Bismillah preamble for Surah 9."
  },
  {
    q: "How does Bismillah sequencing work across all other Surahs?",
    a: "Except for Surah 1 (where Bismillah is Ayah 1) and Surah 9, starting audio recitation from Ayah 1 of any Surah will automatically play the sacred Bismillah invocation first with gold visual cartouche highlighting before smoothly transitioning into Ayah 1."
  },
  {
    q: "Is Nūr Al-Quran fully functional offline?",
    a: "Yes! Nūr Al-Quran is a Progressive Web Application (PWA). All UI components, scripts, stylesheets, fonts, and cached pages/audio remain fully usable even without an active internet connection. You can also install it to your home screen or desktop on Android, iOS, Windows, and macOS."
  },
  {
    q: "Where is my personal data (notes, bookmarks, khatm progress) stored?",
    a: "Your data is 100% private and stored exclusively on your device using IndexedDB and LocalStorage. We do not track, transmit, or store any of your reflections, notes, or reading habits on remote servers. You can export or import your complete reading vault anytime via the Backup & Restore Sanctuary."
  },
  {
    q: "Which Qaris (Reciters) are available?",
    a: "Nūr Al-Quran includes 12 globally renowned Qaris including Mishary Rashid Alafasy, Abdul Basit (Murattal & Mujawwad), Mahmoud Khalil Al-Husary (Murattal & Mu'allim), Mohamed Siddiq El-Minshawi (Murattal & Mujawwad), Abdur-Rahman As-Sudais, Maher Al-Muaiqly, Sa'ood Ash-Shuraym, Abu Bakr Ash-Shaatree, and Ali Al-Hudhaify."
  },
  {
    q: "What is the difference between the Reading Modes?",
    a: "Nūr Al-Quran offers 3 reading modes:\n• Page Slide: Smooth horizontal sliding transition between pages.\n• Scroll: Continuous vertical reading flow ideal for long reading sessions.\n• Page Turn: Skeuomorphic 3D book-page flip animation simulating holding a physical Mushaf."
  },
  {
    q: "How do I log and track my Khatm Al-Quran?",
    a: "Visit the Ramzan & Duas view or Home dashboard to see your Khatm target planner. You can set your daily page target (e.g. 20 pages/day to finish in 30 days) and log each day's recitation with one tap."
  }
];

function renderFAQ() {
  const container = $('faqAccordionList');
  if (!container) return;
  if (container.children.length > 0) return;

  container.innerHTML = faqs.map((faq, idx) => `
    <div class="faq-item" style="background:var(--bg-card);border:1px solid var(--border-line);border-radius:var(--radius-md);margin-bottom:12px;overflow:hidden;transition:all 0.2s;">
      <button class="faq-question-btn" data-faq-idx="${idx}" style="width:100%;text-align:left;padding:16px 20px;display:flex;justify-content:space-between;align-items:center;background:none;border:none;cursor:pointer;font-family:inherit;color:var(--text-primary);font-size:15px;font-weight:600;">
        <span>${escapeHtml(faq.q)}</span>
        <span class="faq-icon" style="font-size:14px;color:var(--primary);transition:transform 0.2s;">▾</span>
      </button>
      <div class="faq-answer-panel hidden" id="faqAnswer_${idx}" style="padding:0 20px 18px;font-size:13.5px;line-height:1.7;color:var(--text-secondary);border-top:1px solid var(--border-line);margin-top:4px;white-space:pre-line;">
        ${escapeHtml(faq.a)}
      </div>
    </div>
  `).join('');

  container.querySelectorAll('.faq-question-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const idx = btn.dataset.faqIdx;
      const panel = $(`faqAnswer_${idx}`);
      const icon = btn.querySelector('.faq-icon');
      if (panel) {
        const isHidden = panel.classList.contains('hidden');
        panel.classList.toggle('hidden');
        if (icon) icon.style.transform = isHidden ? 'rotate(180deg)' : 'none';
      }
    });
  });
}

function syncResume() {
  updateKhatmTracker();
}

// -----------------------------------------------------------------------------
// 10. PRAYER TIMES, QIBLAH COMPASS & AZAN ALARM SUITE
// -----------------------------------------------------------------------------
let prayerCountdownInterval = null;
let qiblahOrientationAttached = false;
let currentQiblahBearing = 266.6;

function renderPrayerView() {
  if (!window.NurPrayerEngine) return;
  const eng = window.NurPrayerEngine;
  const loc = eng.state.location;

  // 1. Update City Label
  if ($('prayerCurrentCityLabel')) {
    $('prayerCurrentCityLabel').textContent = `${loc.name} (${loc.urdu || ''})`;
  }

  // 2. Date Labels
  const now = new Date();
  if ($('prayerGregorianDate')) {
    $('prayerGregorianDate').textContent = now.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }

  // 3. Asr Method Pills
  const isHanafi = eng.state.asrJuristic === 'Hanafi';
  $('btnAsrHanafi')?.classList.toggle('active', isHanafi);
  $('btnAsrShafi')?.classList.toggle('active', !isHanafi);
  if ($('subAsrJuristic')) {
    $('subAsrJuristic').textContent = isHanafi ? 'Hanafi (دومثل)' : 'Shafi/Standard (ایک مثل)';
  }

  // 4. Calculate Timings
  updatePrayerTimesUI();

  // 5. Start live countdown interval
  if (prayerCountdownInterval) clearInterval(prayerCountdownInterval);
  prayerCountdownInterval = setInterval(updatePrayerTimesUI, 1000);
}

function updatePrayerTimesUI() {
  if (!window.NurPrayerEngine) return;
  const eng = window.NurPrayerEngine;
  const now = new Date();
  const times = eng.calculatePrayerTimes(now, eng.state.location, eng.state.asrJuristic);

  // Set All Time Elements
  if ($('timeFajr')) $('timeFajr').textContent = times.fajr.time12;
  if ($('timeSunrise')) $('timeSunrise').textContent = times.sunrise.time12;
  if ($('timeZawal')) $('timeZawal').textContent = `${times.zawalStart.displayTime} - ${times.zawal.time12}`;
  if ($('timeDhuhr')) $('timeDhuhr').textContent = times.dhuhr.time12;
  if ($('timeAsr')) $('timeAsr').textContent = times.asr.time12;
  if ($('timeSunset')) $('timeSunset').textContent = times.sunset.time12;
  if ($('timeMaghrib')) $('timeMaghrib').textContent = times.maghrib.time12;
  if ($('timeIsha')) $('timeIsha').textContent = times.isha.time12;

  // Extra Sunnah
  if ($('timeSehriEnd')) $('timeSehriEnd').textContent = times.sehriEnd.time12;
  if ($('timeTahajjud')) $('timeTahajjud').textContent = times.tahajjud.time12;
  if ($('timeIshraq')) {
    const ishraqH = times.rawHours.sunrise + (15 / 60);
    const h24 = Math.floor(ishraqH);
    const m = Math.floor((ishraqH - h24) * 60);
    const p = h24 >= 12 ? 'PM' : 'AM';
    const h12 = (h24 % 12) || 12;
    $('timeIshraq').textContent = `${h12}:${String(m).padStart(2, '0')} ${p}`;
  }

  // Alarm Toggle Buttons active states
  const alarms = eng.state.alarmSettings;
  document.querySelectorAll('.alarm-toggle-btn[data-prayer]').forEach(btn => {
    const p = btn.dataset.prayer;
    const active = !!alarms[p];
    btn.classList.toggle('active', active);
    btn.textContent = active ? '🔔' : '🔕';
  });

  // Determine Next Prayer & Active Prayer
  const curFloat = now.getHours() + (now.getMinutes() / 60) + (now.getSeconds() / 3600);
  const raw = times.rawHours;

  const sequence = [
    { key: 'fajr', name: 'Fajr', urdu: 'فجر', time: raw.fajr, timeObj: times.fajr },
    { key: 'dhuhr', name: 'Dhuhr', urdu: 'ظہر', time: raw.dhuhr, timeObj: times.dhuhr },
    { key: 'asr', name: 'Asr', urdu: 'عصر', time: raw.asr, timeObj: times.asr },
    { key: 'maghrib', name: 'Maghrib', urdu: 'مغرب', time: raw.maghrib, timeObj: times.maghrib },
    { key: 'isha', name: 'Isha', urdu: 'عشاء', time: raw.isha, timeObj: times.isha }
  ];

  let nextP = null;
  for (const s of sequence) {
    if (s.time > curFloat) {
      nextP = s;
      break;
    }
  }

  // If after Isha, next prayer is Fajr tomorrow
  let isTomorrow = false;
  if (!nextP) {
    nextP = sequence[0];
    isTomorrow = true;
  }

  // Countdown in seconds
  let diffSecs = 0;
  if (isTomorrow) {
    diffSecs = Math.round((nextP.time + 24 - curFloat) * 3600);
  } else {
    diffSecs = Math.round((nextP.time - curFloat) * 3600);
  }

  const hours = Math.floor(diffSecs / 3600);
  const mins = Math.floor((diffSecs % 3600) / 60);
  const secs = diffSecs % 60;

  let countdownStr = '';
  if (hours > 0) {
    countdownStr = `⏳ In ${hours}h ${mins}m ${secs}s`;
  } else {
    countdownStr = `⏳ In ${mins}m ${secs}s`;
  }

  if ($('prayerNextName')) $('prayerNextName').textContent = `${nextP.name} (${nextP.urdu})`;
  if ($('prayerNextTime')) $('prayerNextTime').textContent = nextP.timeObj.time12;
  if ($('prayerCountdownBadge')) $('prayerCountdownBadge').textContent = countdownStr;

  // Active Highlight
  document.querySelectorAll('.prayer-card[data-prayer]').forEach(card => {
    card.classList.remove('active');
  });
  let activeIdx = sequence.indexOf(nextP) - 1;
  if (activeIdx < 0) activeIdx = sequence.length - 1;
  const activeP = sequence[activeIdx];
  $(`card${activeP.name}`)?.classList.add('active');
}

// -----------------------------------------------------------------------------
// QIBLAH COMPASS (Multi-Sensor & Tilt-Compensated)
// -----------------------------------------------------------------------------
let qiblahAbsoluteActive = false;
let currentDeviceHeading = 0;

function calculateTiltCompensatedHeading(alpha, beta, gamma) {
  if (alpha === null || alpha === undefined) return 0;
  // If device is almost flat, (360 - alpha) gives direct yaw
  if (Math.abs(beta || 0) < 6 && Math.abs(gamma || 0) < 6) {
    return (360 - alpha) % 360;
  }
  const degToRad = Math.PI / 180;
  const _x = (beta || 0) * degToRad;
  const _y = (gamma || 0) * degToRad;
  const _z = (alpha || 0) * degToRad;

  const cX = Math.cos(_x);
  const cY = Math.cos(_y);
  const cZ = Math.cos(_z);
  const sX = Math.sin(_x);
  const sY = Math.sin(_y);
  const sZ = Math.sin(_z);

  // W3C standard 3D rotation matrix calculation
  const rA = -cZ * sY - sZ * sX * cY;
  const rB = -sZ * sY + cZ * sX * cY;
  let heading = Math.atan2(rA, rB) * (180 / Math.PI);
  return (heading + 360) % 360;
}

function updateCompassUI(heading) {
  currentDeviceHeading = heading;
  const dial = $('compassDialSvg');
  const needle = $('qiblahNeedleBox');
  const statusBanner = $('qiblahStatusBanner');
  const statusIcon = $('qiblahStatusIcon');
  const statusText = $('qiblahStatusText');
  const headingVal = $('compassLiveHeading');

  if (headingVal) {
    headingVal.textContent = `Phone Heading: ${Math.round(heading)}° (North: 0°)`;
  }

  if (dial) {
    dial.style.transform = `rotate(${-heading}deg)`;
  }
  if (needle) {
    needle.style.transform = `rotate(${currentQiblahBearing - heading}deg)`;
  }

  const diff = Math.abs((currentQiblahBearing - heading + 360) % 360);
  const isAligned = diff <= 4.0 || diff >= 356.0;

  if (statusBanner) {
    statusBanner.classList.toggle('aligned', isAligned);
  }
  if (statusIcon && statusText) {
    if (isAligned) {
      statusIcon.textContent = '🕋';
      statusText.textContent = 'قبلہ رخ — You are facing the Holy Kaaba!';
      try { navigator.vibrate?.(40); } catch(e) {}
    } else {
      statusIcon.textContent = '🧭';
      const angleNeeded = Math.round(diff > 180 ? 360 - diff : diff);
      const turnDir = (currentQiblahBearing - heading + 360) % 360 < 180 ? 'Right' : 'Left';
      statusText.textContent = `Turn ${angleNeeded}° to the ${turnDir} towards Kaaba needle`;
    }
  }
}

function handleCompassOrientation(e, isAbsolute) {
  let heading = 0;
  if (typeof e.webkitCompassHeading !== 'undefined') {
    // iOS Safari provides direct magnetic compass heading
    heading = e.webkitCompassHeading;
  } else if (e.alpha !== null && e.alpha !== undefined) {
    // Android Chrome / Standard W3C
    heading = calculateTiltCompensatedHeading(e.alpha, e.beta, e.gamma);
  } else {
    return;
  }
  updateCompassUI(heading);
}

function startQiblahCompass() {
  if (qiblahOrientationAttached) return;
  qiblahOrientationAttached = true;

  // 1. Android Chrome Absolute Orientation (Crucial for Earth's Magnetic North)
  window.addEventListener('deviceorientationabsolute', (e) => {
    qiblahAbsoluteActive = true;
    handleCompassOrientation(e, true);
  }, true);

  // 2. Standard Orientation (iOS webkitCompassHeading or fallback)
  window.addEventListener('deviceorientation', (e) => {
    if (qiblahAbsoluteActive && typeof e.webkitCompassHeading === 'undefined') {
      return; // Ignore non-absolute events once absolute is active
    }
    handleCompassOrientation(e, false);
  }, true);
}

function calibrateQiblahCompass() {
  if (typeof DeviceOrientationEvent !== 'undefined' && typeof DeviceOrientationEvent.requestPermission === 'function') {
    DeviceOrientationEvent.requestPermission()
      .then(response => {
        if (response === 'granted') {
          showToast('🧭 Compass sensor permission granted!');
          startQiblahCompass();
        } else {
          showToast('⚠️ Sensor permission denied by browser.');
        }
      })
      .catch(err => {
        showToast('Sensor initialized. Move phone in figure-8 motion.');
        startQiblahCompass();
      });
  } else {
    startQiblahCompass();
    showToast('Compass active! Move phone in figure-8 (∞) to calibrate.');
  }
}

function renderQiblahView() {
  if (!window.NurPrayerEngine) return;
  const eng = window.NurPrayerEngine;
  const loc = eng.state.location;

  if ($('qiblahCurrentCityLabel')) {
    $('qiblahCurrentCityLabel').textContent = `${loc.name} (${loc.urdu || ''})`;
  }

  const q = eng.calculateQiblah(loc.lat, loc.lng);
  currentQiblahBearing = q.bearing;

  if ($('qiblahDegreeDisplay')) {
    $('qiblahDegreeDisplay').textContent = `${q.bearing}° ${q.cardinal}`;
  }
  if ($('qiblahDistanceText')) {
    $('qiblahDistanceText').textContent = `Distance to Holy Kaaba: ${q.distanceKm.toLocaleString()} km`;
  }
  if ($('qiblahGuideBearing')) {
    $('qiblahGuideBearing').textContent = `${q.bearing}° (${q.cardinal})`;
  }

  const needle = $('qiblahNeedleBox');
  if (needle) {
    needle.style.transform = `rotate(${q.bearing}deg)`;
  }

  startQiblahCompass();
}

// -----------------------------------------------------------------------------
// CITY / LOCATION SELECTOR MODAL
// -----------------------------------------------------------------------------
function openPrayerCityModal() {
  const modal = $('prayerCityModal');
  const list = $('prayerCityList');
  const input = $('inputCitySearch');
  if (!modal || !list || !window.NurPrayerEngine) return;

  const eng = window.NurPrayerEngine;
  const cities = eng.PRESET_CITIES;
  const cur = eng.state.location;

  function renderList(filtered) {
    list.innerHTML = filtered.map(c => `
      <div class="prayer-city-item ${c.id === cur.id ? 'active' : ''}" data-city-id="${c.id}">
        <div>
          <strong>${c.name}</strong>
          <small style="display:block;color:var(--text-muted);font-size:11px;">${c.country} • ${c.urdu || ''}</small>
        </div>
        <span>${c.id === cur.id ? '✔' : '→'}</span>
      </div>
    `).join('');

    list.querySelectorAll('[data-city-id]').forEach(item => {
      item.onclick = () => {
        const found = cities.find(x => x.id === item.dataset.cityId);
        if (found) {
          eng.setLocation(found);
          modal.classList.add('hidden');
          showToast(`Location set to ${found.name}`);
          renderPrayerView();
          renderQiblahView();
        }
      };
    });
  }

  renderList(cities);

  if (input) {
    input.value = '';
    input.oninput = (e) => {
      const q = e.target.value.toLowerCase().trim();
      const filtered = cities.filter(c =>
        c.name.toLowerCase().includes(q) ||
        (c.urdu && c.urdu.includes(q)) ||
        c.country.toLowerCase().includes(q)
      );
      renderList(filtered);
    };
  }

  modal.classList.remove('hidden');
}

function handleGpsDetect() {
  if (!navigator.geolocation) {
    showToast('GPS geolocation is not supported on this device');
    return;
  }
  showToast('Detecting your location...');
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const tz = -new Date().getTimezoneOffset() / 60;
      const customLoc = {
        id: 'gps_custom',
        name: `Current Location (${lat.toFixed(2)}°, ${lng.toFixed(2)}°)`,
        urdu: 'میری لوکیشن',
        country: 'GPS Detected',
        lat: lat,
        lng: lng,
        tz: tz
      };
      if (window.NurPrayerEngine) {
        window.NurPrayerEngine.setLocation(customLoc);
        $('prayerCityModal')?.classList.add('hidden');
        showToast('📍 GPS Location detected & saved!');
        renderPrayerView();
        renderQiblahView();
      }
    },
    (err) => {
      showToast('Location permission denied. Please choose a city from the list.');
    },
    { enableHighAccuracy: true, timeout: 10000 }
  );
}

// -----------------------------------------------------------------------------
// 11. GLOBAL INITIALIZATION & EVENT WIRING
// -----------------------------------------------------------------------------
document.addEventListener('DOMContentLoaded', () => {
  // Navigation
  document.querySelectorAll('.nav-item[data-view]').forEach(btn => {
    btn.onclick = () => {
      const v = btn.dataset.view;
      $('sidebar')?.classList.remove('open');
      $('sidebarBackdrop')?.classList.remove('active');
      if (v === 'reader') openReader();
      else showView(v);
    };
  });

  document.querySelectorAll('.tool-card[data-view], .tool-card-box[data-view]').forEach(card => {
    card.onclick = () => showView(card.dataset.view);
  });

  // Home Screen Actions
  $('homeContinueBtn')?.addEventListener('click', () => openReader());
  $('homeListenBtn')?.addEventListener('click', () => {
    openReader();
    if (audioState.ayahs.length) {
      playAyah(audioState.ayahs[0].number, true);
    }
  });
  $('cardSpecialistMushaf')?.addEventListener('click', () => openReader());
  $('playDailyVerse')?.addEventListener('click', () => {
    // Al-Baqarah 2:152 (Ayah 159 global)
    playAyah(159, true);
  });
  $('shareDailyVerse')?.addEventListener('click', () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText('“So remember Me; I will remember you. And be grateful to Me and do not deny Me.” — Surah Al-Baqarah 2:152');
      showToast('Daily Ayah copied to clipboard');
    }
  });
  $('btnReadDailyTafsir')?.addEventListener('click', () => {
    openReaderPage(24);
    toggleTafsirDrawer(true);
  });

  // Surahs List Filter Pills
  document.querySelectorAll('.filter-pill[data-filter]').forEach(pill => {
    pill.onclick = () => {
      document.querySelectorAll('.filter-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentSurahFilter = pill.dataset.filter;
      renderSurahsCardGrid();
    };
  });

  // Surahs Search & Sort
  $('surahSearch')?.addEventListener('input', () => renderSurahsCardGrid());
  $('surahSort')?.addEventListener('change', (e) => {
    currentSurahSort = e.target.value;
    renderSurahsCardGrid();
  });

  // Global Header Search
  $('globalSearch')?.addEventListener('input', (e) => {
    const val = e.target.value.trim();
    if (val) {
      showView('surahs');
      if ($('surahSearch')) {
        $('surahSearch').value = val;
        renderSurahsCardGrid();
      }
    }
  });

  // Dedicated Search Page
  $('dedicatedSearchInput')?.addEventListener('input', (e) => {
    handleSearch(e.target.value.trim());
  });

  // Reciter Pickers
  $('headerQari')?.addEventListener('change', (e) => setQari(e.target.value));
  $('audioPageQariSelect')?.addEventListener('change', (e) => setQari(e.target.value));

  // Theme Switchers
  $('btnThemeLight')?.addEventListener('click', () => setTheme('emerald'));
  $('btnThemeDark')?.addEventListener('click', () => setTheme('night'));
  $('btnThemeParchment')?.addEventListener('click', () => setTheme('parchment'));

  $('themeCardEmerald')?.addEventListener('click', () => setTheme('emerald'));
  $('themeCardNight')?.addEventListener('click', () => setTheme('night'));
  $('themeCardParchment')?.addEventListener('click', () => setTheme('parchment'));

  // Reader Controls
  $('closeReader')?.addEventListener('click', closeReader);
  $('prevPage')?.addEventListener('click', () => navigatePage(-1));
  $('nextPage')?.addEventListener('click', () => navigatePage(1));

  // Page Slider
  const pageSlider = $('pageSlider');
  if (pageSlider) {
    let sliderDebounce = null;
    pageSlider.addEventListener('input', (e) => {
      const p = Number(e.target.value);
      if ($('pageNumber')) $('pageNumber').textContent = p;
      clearTimeout(sliderDebounce);
      sliderDebounce = setTimeout(() => {
        if (state.page !== p) {
          state.page = p;
          loadQuranPage(p);
        }
      }, 150);
    });
  }

  // Reading Modes
  $('btnModeSingle')?.addEventListener('click', () => setReadingMode('Page slide'));
  $('btnModeScroll')?.addEventListener('click', () => setReadingMode('Scroll'));
  $('btnModeTurn')?.addEventListener('click', () => setReadingMode('Page turn'));

  // Notes & Study Annotation Suite Trigger (User Request)
  $('btnToggleTafsir')?.addEventListener('click', () => {
    toggleAnnotationSuite();
  });
  $('btnCloseTafsir')?.addEventListener('click', () => toggleTafsirDrawer(false));
  $('playAyahTafsirBtn')?.addEventListener('click', () => {
    if (selectedAyahData) playAyah(selectedAyahData.number, true);
  });
  $('saveNote')?.addEventListener('click', () => {
    const val = $('noteText')?.value.trim();
    if (val) state.notes[state.page] = val;
    else delete state.notes[state.page];
    saveState();
    showToast('Reflection note saved');
  });

  // Ayah Action Bubble buttons
  $('bubbleCopy')?.addEventListener('click', () => {
    if (selectedAyahData && navigator.clipboard) {
      navigator.clipboard.writeText(selectedAyahData.text);
      showToast('Ayah copied');
      hideAyahBubble();
    }
  });
  $('bubbleTafsir')?.addEventListener('click', () => {
    toggleTafsirDrawer(true);
    hideAyahBubble();
  });
  $('bubbleSave')?.addEventListener('click', () => {
    if (!state.bookmarks.includes(state.page)) {
      state.bookmarks.push(state.page);
      showToast(`Page ${state.page} saved to bookmarks`);
    } else {
      state.bookmarks = state.bookmarks.filter(p => p !== state.page);
      showToast(`Page ${state.page} removed from bookmarks`);
    }
    saveState();
    updateBookmarkButton();
    updateKhatmTracker();
    hideAyahBubble();
  });
  $('bubblePlay')?.addEventListener('click', () => {
    if (selectedAyahData) playAyah(selectedAyahData.number, true);
    hideAyahBubble();
  });

  // Favourite, Bookmark & Share in Reader
  $('readerFavourite')?.addEventListener('click', () => {
    if (!state.favourites.includes(state.page)) {
      state.favourites.push(state.page);
      showToast(`Page ${state.page} added to favourites`);
    } else {
      state.favourites = state.favourites.filter(p => p !== state.page);
      showToast(`Page ${state.page} removed from favourites`);
    }
    saveState();
    updateFavouriteButton();
  });

  $('readerBookmark')?.addEventListener('click', () => {
    if (!state.bookmarks.includes(state.page)) {
      state.bookmarks.push(state.page);
      showToast(`Page ${state.page} bookmarked`);
    } else {
      state.bookmarks = state.bookmarks.filter(p => p !== state.page);
      showToast(`Page ${state.page} removed`);
    }
    saveState();
    updateBookmarkButton();
    updateKhatmTracker();
  });

  $('readerShare')?.addEventListener('click', () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(`Holy Quran 15-Line Mushaf · Page ${state.page}`);
      showToast('Page reference copied');
    }
  });

  // Hanging Ribbon Bookmark at Top Right (Screenshots 1-4)
  $('mushafRibbonBookmark')?.addEventListener('click', () => {
    const p = state.page;
    if (state.bookmarks.includes(p)) {
      state.bookmarks = state.bookmarks.filter(b => b !== p);
      $('mushafRibbonBookmark')?.classList.remove('bookmarked');
      showToast(`Page ${p} removed from bookmarks`);
    } else {
      state.bookmarks.push(p);
      $('mushafRibbonBookmark')?.classList.add('bookmarked');
      showToast(`Page ${p} saved to bookmarks ⚑`);
    }
    saveState();
    updateBookmarkButton();
    updateKhatmTracker();
  });

  // Floating Circular Notepad Action Button (Screenshots 1-4)
  $('floatingNoteBtn')?.addEventListener('click', () => {
    toggleAnnotationSuite();
  });

  // Clean Reader Audio Deck (Screenshots 1-4)
  $('deckPlayBtn')?.addEventListener('click', () => {
    const audio = $('quranAudio');
    if (audio) {
      if (audio.paused) {
        if (!audio.src && audioState.ayahs.length) {
          playAyah(audioState.ayahs[0].number, true);
        } else {
          audio.play();
        }
      } else {
        audio.pause();
      }
    }
    updateReaderDeckUI();
  });

  const speedCycle = [1.0, 1.25, 1.5, 0.75];
  let speedIdx = 0;
  $('deckSpeedBtn')?.addEventListener('click', () => {
    speedIdx = (speedIdx + 1) % speedCycle.length;
    const newSpeed = speedCycle[speedIdx];
    const audio = $('quranAudio');
    if (audio) audio.playbackRate = newSpeed;
    if ($('audioSpeed')) $('audioSpeed').value = newSpeed;
    if ($('deckSpeedVal')) $('deckSpeedVal').textContent = `${newSpeed}x`;
    showToast(`Recitation speed: ${newSpeed}x`);
  });

  const repeatCycle = ['off', 'ayah', 'page'];
  let repeatIdx = 0;
  $('deckRepeatBtn')?.addEventListener('click', () => {
    repeatIdx = (repeatIdx + 1) % repeatCycle.length;
    const newRepeat = repeatCycle[repeatIdx];
    if ($('audioRepeat')) $('audioRepeat').value = newRepeat;
    if ($('deckRepeatNum')) $('deckRepeatNum').textContent = newRepeat === 'ayah' ? '1' : (newRepeat === 'page' ? 'P' : '0');
    showToast(newRepeat === 'ayah' ? 'Repeating Ayah (1)' : (newRepeat === 'page' ? 'Repeating Page' : 'Repeat Off'));
  });



  // Settings Font Scale Slider
  $('scaleSlider')?.addEventListener('input', (e) => setFontScale(Number(e.target.value)));

  // Audio Glow Toggle
  $('btnAyahGlow')?.addEventListener('click', () => {
    state.glow = !state.glow;
    localStorage.setItem('nur-glow', state.glow);
    $('btnAyahGlow')?.classList.toggle('active', state.glow);
    showToast(`Ayah Glow ${state.glow ? 'Enabled' : 'Disabled'}`);
  });

  // Persistent Audio Bar Controls
  const audio = $('quranAudio');
  if (audio) {
    $('audioPlay')?.addEventListener('click', () => {
      if (audio.paused) {
        if (!audio.src && audioState.ayahs.length) {
          playAyah(audioState.ayahs[0].number, true);
        } else {
          audio.play();
        }
        if ($('audioPlay')) $('audioPlay').textContent = 'Ⅱ';
      } else {
        audio.pause();
        if ($('audioPlay')) $('audioPlay').textContent = '▶';
      }
    });

    $('audioPrevious')?.addEventListener('click', async () => {
      if (audioState.index > 0) {
        playAyah(audioState.ayahs[audioState.index - 1].number, false);
      } else if (state.page > 1) {
        const prevPage = state.page - 1;
        if (!$('readerOverlay')?.classList.contains('hidden')) {
          navigatePage(-1);
        } else {
          state.page = prevPage;
          saveState();
        }
        const prevAyahs = await fetchAyahsForPage(prevPage);
        if (prevAyahs && prevAyahs.length) {
          audioState.ayahs = prevAyahs;
          audioState.index = prevAyahs.length - 1;
          playAyah(prevAyahs[prevAyahs.length - 1].number, false);
        }
      }
    });

    $('audioNext')?.addEventListener('click', async () => {
      if (audioState.index < audioState.ayahs.length - 1) {
        playAyah(audioState.ayahs[audioState.index + 1].number, true);
      } else if (state.page < TOTAL_PAGES) {
        const nextPage = state.page + 1;
        if (!$('readerOverlay')?.classList.contains('hidden')) {
          navigatePage(1);
        } else {
          state.page = nextPage;
          saveState();
        }
        const nextAyahs = await fetchAyahsForPage(nextPage);
        if (nextAyahs && nextAyahs.length) {
          audioState.ayahs = nextAyahs;
          audioState.index = 0;
          playAyah(nextAyahs[0].number, true);
        }
      }
    });

    $('audioProgress')?.addEventListener('input', (e) => {
      if (audio.duration) {
        audio.currentTime = (Number(e.target.value) / 100) * audio.duration;
      }
    });

    audio.addEventListener('timeupdate', () => {
      if ($('audioProgress') && audio.duration) {
        $('audioProgress').value = (audio.currentTime / audio.duration) * 100;
      }
      if ($('audioCurrentTime')) {
        $('audioCurrentTime').textContent = formatTime(audio.currentTime);
      }
      if ($('audioDurationTime')) {
        $('audioDurationTime').textContent = formatTime(audio.duration);
      }
      updatePlayingAyahProgress();
    });

    audio.addEventListener('ended', handleAudioEnded);

    $('audioSpeed')?.addEventListener('change', (e) => {
      audio.playbackRate = Number(e.target.value);
    });

    $('audioDownload')?.addEventListener('click', () => {
      if (!audio.currentSrc) {
        showToast('Play an ayah before downloading');
        return;
      }
      const a = document.createElement('a');
      a.href = audio.currentSrc;
      a.download = `nur-quran-ayah-${audioState.ayahs[audioState.index]?.number || 'recitation'}.mp3`;
      a.target = '_blank';
      document.body.appendChild(a);
      a.click();
      a.remove();
      showToast('Audio download initiated');
    });
  }

  // Backup Export & Import
  $('exportBackup')?.addEventListener('click', exportBackup);
  $('importBackupButton')?.addEventListener('click', () => $('importBackup')?.click());
  $('importBackup')?.addEventListener('change', (e) => {
    if (e.target.files && e.target.files[0]) {
      restoreBackup(e.target.files[0]);
    }
  });

  // Ramzan Messages
  if ($('ramadanMessage') && ramadanMessages[ramadanMessageIndex]) {
    $('ramadanMessage').textContent = ramadanMessages[ramadanMessageIndex].message;
    $('ramadanPrompt').textContent = ramadanMessages[ramadanMessageIndex].prompt;
  }
  $('newRamadanMessage')?.addEventListener('click', () => {
    ramadanMessageIndex = (ramadanMessageIndex + 1) % ramadanMessages.length;
    $('ramadanMessage').textContent = ramadanMessages[ramadanMessageIndex].message;
    $('ramadanPrompt').textContent = ramadanMessages[ramadanMessageIndex].prompt;
  });

  // Settings: Script & Mode Radio Cards
  document.querySelectorAll('.script-radio-card').forEach(card => {
    card.addEventListener('click', () => {
      const parent = card.closest('.script-type-radio-group');
      if (parent) {
        parent.querySelectorAll('.script-radio-card').forEach(c => c.classList.remove('active'));
      }
      card.classList.add('active');
      showToast('Preference updated');
    });
  });

  // Settings: Repetition Loop Buttons
  const repButtons = document.querySelectorAll('.settings-card-v2 .btn-outline-green');
  repButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      if (['1x', '3x', '5x', '∞'].includes(btn.textContent.trim())) {
        repButtons.forEach(b => {
          if (['1x', '3x', '5x', '∞'].includes(b.textContent.trim())) b.classList.remove('active');
        });
        btn.classList.add('active');
        showToast(`Ayah repetition set to ${btn.textContent.trim()}`);
      }
    });
  });

  // Home Quick Note
  $('btnAddQuickNote')?.addEventListener('click', () => {
    openReader();
    toggleTafsirDrawer(true);
    $('noteText')?.focus();
  });

  // Juz Search & Filter Pills
  $('juzSearch')?.addEventListener('input', () => renderJuz());
  document.querySelectorAll('.filter-pill[data-juz-filter]').forEach(pill => {
    pill.addEventListener('click', () => {
      document.querySelectorAll('.filter-pill[data-juz-filter]').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentJuzFilter = pill.dataset.juzFilter;
      renderJuz();
    });
  });

  // Bookmarks Filter Pills
  const bmPills = [$('filterBookmarksAll'), $('filterBookmarksOnly'), $('filterNotesOnly')];
  $('filterBookmarksAll')?.addEventListener('click', () => {
    bmPills.forEach(p => p?.classList.remove('active'));
    $('filterBookmarksAll')?.classList.add('active');
    currentBookmarkFilter = 'all';
    renderBookmarks();
  });
  $('filterBookmarksOnly')?.addEventListener('click', () => {
    bmPills.forEach(p => p?.classList.remove('active'));
    $('filterBookmarksOnly')?.classList.add('active');
    currentBookmarkFilter = 'pages';
    renderBookmarks();
  });
  $('filterNotesOnly')?.addEventListener('click', () => {
    bmPills.forEach(p => p?.classList.remove('active'));
    $('filterNotesOnly')?.classList.add('active');
    currentBookmarkFilter = 'notes';
    renderBookmarks();
  });

  // Ramzan Duas Category Tabs
  document.querySelectorAll('#ramadanCategoryPills .filter-pill[data-dua-tab]').forEach(pill => {
    pill.addEventListener('click', () => {
      document.querySelectorAll('#ramadanCategoryPills .filter-pill').forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentDuaTab = pill.dataset.duaTab;
      renderRamadanDuas();
    });
  });

  // Populate Reciter Selects with 12 Qaris
  const headerSelect = $('headerQari');
  if (headerSelect) {
    headerSelect.innerHTML = qarisData.map(q => `<option value="${q.id}">${q.name}</option>`).join('');
    headerSelect.value = audioState.qari;
  }
  const audioPageSelect = $('audioPageQariSelect');
  if (audioPageSelect) {
    audioPageSelect.innerHTML = qarisData.map(q => `<option value="${q.id}">${q.name} (${q.style})</option>`).join('');
    audioPageSelect.value = audioState.qari;
  }

  // Audio Play/Pause Sync for Studio Deck
  const qAudio = $('quranAudio');
  if (qAudio) {
    qAudio.addEventListener('play', () => {
      if ($('deckPlayPause')) $('deckPlayPause').textContent = 'Ⅱ Pause Recitation';
      updateReaderDeckUI();
    });
    qAudio.addEventListener('pause', () => {
      if ($('deckPlayPause')) $('deckPlayPause').textContent = '▶ Resume Recitation';
      updateReaderDeckUI();
    });
    qAudio.addEventListener('ended', () => {
      updateReaderDeckUI();
    });
    qAudio.addEventListener('ratechange', () => {
      updateReaderDeckUI();
    });
  }

  // Initialize Default States & Infrastructure
  initIndexedDB();
  initBackupDropzone();
  setTheme(state.theme);
  setQari(audioState.qari);
  initHeaderQariPopover();
  initReaderMoreSheet();
  setReadingMode(state.mode);
  setFontScale(state.scale);
  renderSurahsCardGrid();
  renderJuz();
  renderBookmarks();
  renderRamadanDuas();
  renderKhatamPlanner();
  updateKhatmTracker();

  // Service Worker Registration for PWA Offline Functionality
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js', { scope: './' })
        .then(reg => {
          console.log('Nūr Al-Quran Service Worker active:', reg.scope);
          if (reg.update) reg.update();
        })
        .catch(err => console.log('Service Worker registration failed:', err));
    });
  }

  // Client-Side Hash Routing & Initial Deep-Link Dispatch
  window.addEventListener('hashchange', handleRoute);
  handleRoute();

  // Mobile Hamburger Toggle & Backdrop
  $('mobileMenuBtn')?.addEventListener('click', () => {
    const sidebar = $('sidebar');
    const backdrop = $('sidebarBackdrop');
    if (sidebar) {
      const isOpen = sidebar.classList.contains('open');
      sidebar.classList.toggle('open', !isOpen);
      if (backdrop) backdrop.classList.toggle('active', !isOpen);
    }
  });

  $('sidebarBackdrop')?.addEventListener('click', () => {
    $('sidebar')?.classList.remove('open');
    $('sidebarBackdrop')?.classList.remove('active');
  });

  // Mobile Bottom Navigation Bar Tabs
  document.querySelectorAll('.mobile-nav-tab[data-view]').forEach(tab => {
    tab.addEventListener('click', () => {
      const v = tab.dataset.view;
      if (v === 'reader') openReader();
      else showView(v);
    });
  });

  $('mobileMoreTab')?.addEventListener('click', () => {
    $('sidebar')?.classList.toggle('open');
    $('sidebarBackdrop')?.classList.toggle('active');
  });

  // Mobile Mushaf FAB (Center Elevated Button)
  $('mobileMushafFab')?.addEventListener('click', () => {
    openReader();
  });

  // Mobile Theme Capsule Toggle
  $('mobileThemeCapsule')?.addEventListener('click', () => {
    setTheme(state.theme === 'night' ? 'emerald' : 'night');
  });

  // Mobile Full-Width Search Bar
  $('mobileSearchInput')?.addEventListener('input', (e) => {
    const val = e.target.value.trim();
    if (val) {
      showView('surahs');
      if ($('surahSearch')) {
        $('surahSearch').value = val;
        renderSurahsCardGrid();
      }
    }
  });

  $('mobileSearchInput')?.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      const val = e.target.value.trim();
      if (val) {
        showView('search');
        if ($('dedicatedSearchInput')) {
          $('dedicatedSearchInput').value = val;
          handleSearch(val);
        }
      }
    }
  });

  // Mobile Search Mic button triggers Qari/Voice modal
  $('mobileMicBtn')?.addEventListener('click', () => {
    const popover = $('headerQariPopover');
    if (popover) {
      popover.classList.toggle('hidden');
    }
  });

  // Quick Access "See All" button
  $('btnSeeAllTools')?.addEventListener('click', () => {
    showView('surahs');
  });

  // Touch Swipe Gestures for 15-Line Quran Reader on Mobile
  const readerOverlay = $('readerOverlay');
  if (readerOverlay) {
    let touchStartX = 0;
    let touchStartY = 0;

    readerOverlay.addEventListener('touchstart', (e) => {
      touchStartX = e.changedTouches[0].screenX;
      touchStartY = e.changedTouches[0].screenY;
    }, { passive: true });

    readerOverlay.addEventListener('touchend', (e) => {
      const touchEndX = e.changedTouches[0].screenX;
      const touchEndY = e.changedTouches[0].screenY;
      const diffX = touchEndX - touchStartX;
      const diffY = touchEndY - touchStartY;

      // Swiping horizontally with at least 45px distance and horizontal dominant
      if (typeof annotState !== 'undefined' && annotState.isActive) return; // Prevent page turn while drawing
      if (Math.abs(diffX) > Math.abs(diffY) && Math.abs(diffX) > 45) {
        // Natural page turn requested:
        // Swipe right (diffX > 0, seedha side) -> Next Page (towards page 611)
        // Swipe left (diffX < 0, ulta side) -> Previous Page (towards page 1)
        if (diffX > 0) {
          navigatePage(1);
        } else {
          navigatePage(-1);
        }
      }
    }, { passive: true });
  }

  // Hide bubble when clicked outside
  document.addEventListener('click', (e) => {
    if (!e.target.closest('.mushaf-ayah') && !e.target.closest('#ayahActionBubble') && !e.target.closest('.ayah-marker')) {
      hideAyahBubble();
    }
  });

  // Prayer Times, Qiblah & Azan Alarm Listeners
  $('prayerCityTrigger')?.addEventListener('click', openPrayerCityModal);
  $('qiblahCityTrigger')?.addEventListener('click', openPrayerCityModal);
  $('btnCloseCityModal')?.addEventListener('click', () => {
    $('prayerCityModal')?.classList.add('hidden');
  });
  $('btnModalGpsDetect')?.addEventListener('click', handleGpsDetect);
  $('btnGpsAutoDetect')?.addEventListener('click', handleGpsDetect);
  $('btnOpenQiblahFromPrayer')?.addEventListener('click', () => showView('qiblah'));

  // Juristic Asr Buttons
  $('btnAsrHanafi')?.addEventListener('click', () => {
    if (window.NurPrayerEngine) {
      window.NurPrayerEngine.setAsrJuristic('Hanafi');
      renderPrayerView();
      showToast('Asr timing set to Hanafi (دومثل)');
    }
  });
  $('btnAsrShafi')?.addEventListener('click', () => {
    if (window.NurPrayerEngine) {
      window.NurPrayerEngine.setAsrJuristic('Standard');
      renderPrayerView();
      showToast('Asr timing set to Shafi/Standard (ایک مثل)');
    }
  });

  // Azan Sound Testing & Stopping
  $('btnTestAzanSound')?.addEventListener('click', () => {
    if (window.NurPrayerEngine) {
      window.NurPrayerEngine.testAzan();
      showToast('🔊 Playing Makkah Azan preview...');
    }
  });
  $('btnStopAzanBanner')?.addEventListener('click', () => {
    if (window.NurPrayerEngine) {
      window.NurPrayerEngine.stopAzan();
      $('azanActiveBanner')?.classList.add('hidden');
      showToast('Azan stopped');
    }
  });

  // Enable Notifications
  $('btnEnableNotifications')?.addEventListener('click', async () => {
    if (window.NurPrayerEngine) {
      showToast('Requesting notification permission...');
      const granted = await window.NurPrayerEngine.requestNotificationPermission();
      if (granted) {
        showToast('🔔 Azan notifications allowed!');
        try {
          new Notification('Nur Al-Quran • Prayer & Azan', {
            body: 'Namaz ke waqt Azan notification on kar diya gaya hai.',
            icon: 'icon-192.png'
          });
        } catch(e) {}
      } else {
        showToast('⚠️ Notifications blocked or dismissed by browser.');
      }
    }
  });

  // Calibrate Compass button
  $('btnCalibrateCompass')?.addEventListener('click', () => {
    calibrateQiblahCompass();
  });

  // Prayer Alarm Bell Toggle Buttons
  document.querySelectorAll('.alarm-toggle-btn[data-prayer]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const pKey = btn.dataset.prayer;
      if (window.NurPrayerEngine) {
        const active = window.NurPrayerEngine.toggleAlarm(pKey);
        btn.classList.toggle('active', active);
        btn.textContent = active ? '🔔' : '🔕';
        showToast(`${pKey.toUpperCase()} alarm ${active ? 'Enabled 🔔' : 'Disabled 🔕'}`);
      }
    });
  });

  // Close City Modal on click outside
  $('prayerCityModal')?.addEventListener('click', (e) => {
    if (e.target === $('prayerCityModal')) {
      $('prayerCityModal').classList.add('hidden');
    }
  });

  // Initialize Study & Annotation Suite
  initAnnotationSuite();
});

// ============================================================================
// 12. 15-LINE QURAN STUDY & ANNOTATION SUITE (Drawing, Highlighting, Notes)
// ============================================================================

const annotState = {
  isActive: false,
  activeTool: 'highlighter', // 'rectangle' | 'pen' | 'highlighter' | 'brush' | 'eraser'
  activeColor: '#e53935',
  isDrawing: false,
  startX: 0,
  startY: 0,
  lastX: 0,
  lastY: 0,
  snapshotCanvas: null
};

function hexToRgba(hex, alpha) {
  if (!hex) return `rgba(229, 57, 53, ${alpha})`;
  let c = hex.replace('#', '');
  if (c.length === 3) {
    c = c.split('').map(ch => ch + ch).join('');
  }
  const num = parseInt(c, 16);
  if (isNaN(num)) return `rgba(229, 57, 53, ${alpha})`;
  const r = (num >> 16) & 255;
  const g = (num >> 8) & 255;
  const b = num & 255;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function getToolIconSvg(toolName) {
  switch (toolName) {
    case 'rectangle':
      return `<svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/></svg>`;
    case 'pen':
      return `<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75L3 17.25zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34c-.39-.39-1.02-.39-1.41 0l-1.83 1.83 3.75 3.75 1.83-1.83z"/></svg>`;
    case 'brush':
      return `<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M7 14c-1.66 0-3 1.34-3 3 0 1.31-1.16 2-2 2 .92 1.22 2.49 2 4 2 2.21 0 4-1.79 4-4 0-1.66-1.34-3-3-3zm13.71-9.37l-1.34-1.34a.996.996 0 0 0-1.41 0L9 12.25 11.75 15l8.96-8.96c.39-.39.39-1.02 0-1.41z"/></svg>`;
    case 'eraser':
      return `<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M16.24 3.56l4.95 4.94c.78.79.78 2.05 0 2.84L12 20.53a4.008 4.008 0 0 1-5.66 0L2.81 17c-.78-.79-.78-2.05 0-2.84l10.6-10.6c.79-.78 2.05-.78 2.83 0zM4.22 15.58l3.54 3.53c.78.79 2.04.79 2.83 0l3.53-3.53-4.95-4.95-4.95 4.95z"/></svg>`;
    case 'highlighter':
    default:
      return `<svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M19 17H5v2h14v-2zm-2.7-7.7l-4.6-4.6L4.7 11.7l4.6 4.6 7-7zm-.7-.7l1.4-1.4c.4-.4.4-1 0-1.4l-2.5-2.5c-.4-.4-1-.4-1.4 0l-1.4 1.4 3.9 3.9z"/></svg>`;
  }
}

function getToolLabel(toolName) {
  const map = {
    rectangle: 'Rectangle',
    pen: 'Pen',
    highlighter: 'Highlighter',
    brush: 'Brush',
    eraser: 'Eraser'
  };
  return map[toolName] || 'Highlighter';
}

function resizeAnnotationCanvas() {
  const canvas = $('annotationCanvas');
  const frame = $('mushafImageWrapper') || $('mushafPageImage') || $('mushafBorderedFrame');
  if (!canvas || !frame) return;

  const rect = frame.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return;

  const dpr = window.devicePixelRatio || 1;
  const targetW = Math.round(rect.width * dpr);
  const targetH = Math.round(rect.height * dpr);

  if (canvas.width !== targetW || canvas.height !== targetH) {
    let temp = null;
    if (canvas.width > 0 && canvas.height > 0) {
      temp = document.createElement('canvas');
      temp.width = canvas.width;
      temp.height = canvas.height;
      temp.getContext('2d').drawImage(canvas, 0, 0);
    }

    canvas.width = targetW;
    canvas.height = targetH;
    canvas.style.width = `${rect.width}px`;
    canvas.style.height = `${rect.height}px`;

    const ctx = canvas.getContext('2d');
    ctx.scale(dpr, dpr);

    if (temp) {
      ctx.drawImage(temp, 0, 0, rect.width, rect.height);
    }
  }
}

function getCanvasCoords(e) {
  const canvas = $('annotationCanvas');
  if (!canvas) return { x: 0, y: 0 };
  const rect = canvas.getBoundingClientRect();
  return {
    x: e.clientX - rect.left,
    y: e.clientY - rect.top
  };
}

function saveCurrentPageAnnotation() {
  const canvas = $('annotationCanvas');
  if (!canvas || !state.page) return;

  try {
    const key = `nur-annot-page-${state.page}`;
    const dataUrl = canvas.toDataURL('image/png');
    if (dataUrl && dataUrl.length > 300) {
      localStorage.setItem(key, dataUrl);
    } else {
      localStorage.removeItem(key);
    }
  } catch (err) {
    console.warn('Unable to save drawing to localStorage:', err);
  }
}

function loadPageAnnotation(page) {
  const canvas = $('annotationCanvas');
  if (!canvas) return;

  resizeAnnotationCanvas();
  const ctx = canvas.getContext('2d');

  ctx.save();
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.restore();

  const key = `nur-annot-page-${page}`;
  const saved = localStorage.getItem(key);
  if (!saved) return;

  const img = new Image();
  img.onload = () => {
    const frame = $('mushafBorderedFrame');
    if (!frame) return;
    const rect = frame.getBoundingClientRect();
    ctx.drawImage(img, 0, 0, rect.width, rect.height);
  };
  img.src = saved;
}

function clearPageAnnotation(page) {
  const canvas = $('annotationCanvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');
  ctx.save();
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.restore();

  localStorage.removeItem(`nur-annot-page-${page}`);
}

function toggleAnnotationSuite(forceOpen = null) {
  const toolbar = $('annotationToolbar');
  const canvas = $('annotationCanvas');
  if (!toolbar || !canvas) return;

  const isCurrentlyOpen = !toolbar.classList.contains('hidden');
  const shouldOpen = forceOpen !== null ? forceOpen : !isCurrentlyOpen;

  if (shouldOpen) {
    toolbar.classList.remove('hidden');
    canvas.classList.add('active-mode');
    annotState.isActive = true;
    resizeAnnotationCanvas();
    showToast('✏️ Notes & Study Tools Active');
  } else {
    saveCurrentPageAnnotation();
    toolbar.classList.add('hidden');
    canvas.classList.remove('active-mode');
    annotState.isActive = false;
    $('colorPalettePopup')?.classList.add('hidden');
    $('drawingToolsSheet')?.classList.add('hidden');
    $('drawingToolsBackdrop')?.classList.add('hidden');
  }
}

function setActiveTool(tool) {
  annotState.activeTool = tool;
  document.querySelectorAll('.drawing-tool-card').forEach(card => {
    card.classList.toggle('active', card.dataset.tool === tool);
  });

  const labelEl = $('annotActiveToolLabel');
  if (labelEl) labelEl.textContent = getToolLabel(tool);

  const iconEl = $('annotActiveToolIcon');
  if (iconEl) iconEl.innerHTML = getToolIconSvg(tool);

  closeDrawingToolsSheet();
}

function setActiveColor(colorHex) {
  if (!colorHex) return;
  annotState.activeColor = colorHex;

  document.querySelectorAll('.color-chip').forEach(chip => {
    chip.classList.toggle('active', chip.dataset.color === colorHex);
  });

  const dot = $('annotActiveColorDot');
  if (dot) dot.style.background = colorHex;

  $('colorPalettePopup')?.classList.add('hidden');
}

function toggleColorPalette() {
  const popup = $('colorPalettePopup');
  if (!popup) return;
  const isHidden = popup.classList.contains('hidden');
  if (isHidden) {
    closeDrawingToolsSheet();
    popup.classList.remove('hidden');
  } else {
    popup.classList.add('hidden');
  }
}

function openDrawingToolsSheet() {
  $('colorPalettePopup')?.classList.add('hidden');
  $('drawingToolsSheet')?.classList.remove('hidden');
  $('drawingToolsBackdrop')?.classList.remove('hidden');
}

function closeDrawingToolsSheet() {
  $('drawingToolsSheet')?.classList.add('hidden');
  $('drawingToolsBackdrop')?.classList.add('hidden');
}

function initAnnotationSuite() {
  const canvas = $('annotationCanvas');
  if (!canvas) return;

  const ctx = canvas.getContext('2d');

  // Resize canvas when Mushaf frame dimensions update
  const obsTarget = $('mushafImageWrapper') || $('mushafBorderedFrame');
  if (window.ResizeObserver && obsTarget) {
    new ResizeObserver(() => resizeAnnotationCanvas()).observe(obsTarget);
  }
  window.addEventListener('resize', () => resizeAnnotationCanvas());

  // 1. Pointer Event Handlers for Drawing & Highlighting
  canvas.addEventListener('pointerdown', (e) => {
    if (!annotState.isActive) return;
    e.preventDefault();
    canvas.setPointerCapture(e.pointerId);

    const coords = getCanvasCoords(e);
    annotState.isDrawing = true;
    annotState.startX = coords.x;
    annotState.startY = coords.y;
    annotState.lastX = coords.x;
    annotState.lastY = coords.y;

    if (annotState.activeTool === 'rectangle') {
      annotState.snapshotCanvas = document.createElement('canvas');
      annotState.snapshotCanvas.width = canvas.width;
      annotState.snapshotCanvas.height = canvas.height;
      annotState.snapshotCanvas.getContext('2d').drawImage(canvas, 0, 0);
    } else {
      ctx.beginPath();
      ctx.moveTo(coords.x, coords.y);
      applyToolStyles(ctx);
      ctx.lineTo(coords.x, coords.y);
      ctx.stroke();
    }
  });

  canvas.addEventListener('pointermove', (e) => {
    if (!annotState.isDrawing || !annotState.isActive) return;
    e.preventDefault();

    const coords = getCanvasCoords(e);

    if (annotState.activeTool === 'rectangle') {
      if (!annotState.snapshotCanvas) return;
      ctx.save();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(annotState.snapshotCanvas, 0, 0);
      ctx.restore();

      const rx = Math.min(annotState.startX, coords.x);
      const ry = Math.min(annotState.startY, coords.y);
      const rw = Math.abs(coords.x - annotState.startX);
      const rh = Math.abs(coords.y - annotState.startY);

      ctx.save();
      ctx.fillStyle = hexToRgba(annotState.activeColor, 0.16);
      ctx.strokeStyle = annotState.activeColor;
      ctx.lineWidth = 2;
      ctx.fillRect(rx, ry, rw, rh);
      ctx.strokeRect(rx, ry, rw, rh);
      ctx.restore();
    } else {
      ctx.beginPath();
      ctx.moveTo(annotState.lastX, annotState.lastY);
      applyToolStyles(ctx);
      ctx.lineTo(coords.x, coords.y);
      ctx.stroke();
      annotState.lastX = coords.x;
      annotState.lastY = coords.y;
    }
  });

  const endDrawing = (e) => {
    if (!annotState.isDrawing) return;
    annotState.isDrawing = false;
    annotState.snapshotCanvas = null;
    saveCurrentPageAnnotation();
  };

  canvas.addEventListener('pointerup', endDrawing);
  canvas.addEventListener('pointercancel', endDrawing);

  function applyToolStyles(targetCtx) {
    switch (annotState.activeTool) {
      case 'highlighter':
        targetCtx.globalCompositeOperation = 'source-over';
        targetCtx.strokeStyle = hexToRgba(annotState.activeColor, 0.38);
        targetCtx.lineWidth = 22;
        targetCtx.lineCap = 'round';
        targetCtx.lineJoin = 'round';
        break;
      case 'pen':
        targetCtx.globalCompositeOperation = 'source-over';
        targetCtx.strokeStyle = annotState.activeColor;
        targetCtx.lineWidth = 2.5;
        targetCtx.lineCap = 'round';
        targetCtx.lineJoin = 'round';
        break;
      case 'brush':
        targetCtx.globalCompositeOperation = 'source-over';
        targetCtx.strokeStyle = hexToRgba(annotState.activeColor, 0.85);
        targetCtx.lineWidth = 7;
        targetCtx.lineCap = 'round';
        targetCtx.lineJoin = 'round';
        break;
      case 'eraser':
        targetCtx.globalCompositeOperation = 'destination-out';
        targetCtx.lineWidth = 26;
        targetCtx.lineCap = 'round';
        targetCtx.lineJoin = 'round';
        break;
      default:
        targetCtx.globalCompositeOperation = 'source-over';
        targetCtx.strokeStyle = annotState.activeColor;
        targetCtx.lineWidth = 3;
        targetCtx.lineCap = 'round';
        targetCtx.lineJoin = 'round';
        break;
    }
  }

  // 2. Toolbar Event Listeners
  $('annotColorBtn')?.addEventListener('click', (e) => {
    e.stopPropagation();
    toggleColorPalette();
  });

  $('annotToolBtn')?.addEventListener('click', (e) => {
    e.stopPropagation();
    openDrawingToolsSheet();
  });

  $('annotNotesBtn')?.addEventListener('click', () => {
    toggleTafsirDrawer();
  });

  $('annotClearBtn')?.addEventListener('click', () => {
    clearPageAnnotation(state.page);
    showToast('Page markings cleared');
  });

  $('annotCloseBtn')?.addEventListener('click', () => {
    toggleAnnotationSuite(false);
  });

  // 3. Color Chips Listeners
  document.querySelectorAll('.color-chip[data-color]').forEach(chip => {
    chip.addEventListener('click', (e) => {
      e.stopPropagation();
      setActiveColor(chip.dataset.color);
    });
  });

  $('rainbowColorBtn')?.addEventListener('click', (e) => {
    e.stopPropagation();
    $('customColorPicker')?.click();
  });

  $('customColorPicker')?.addEventListener('input', (e) => {
    setActiveColor(e.target.value);
  });

  // 4. Drawing Tool Cards Listeners
  document.querySelectorAll('.drawing-tool-card[data-tool]').forEach(card => {
    card.addEventListener('click', () => {
      setActiveTool(card.dataset.tool);
    });
  });

  $('closeDrawingTools')?.addEventListener('click', () => {
    closeDrawingToolsSheet();
  });

  $('drawingToolsBackdrop')?.addEventListener('click', () => {
    closeDrawingToolsSheet();
  });

  // 5. Hide color palette on outside click
  document.addEventListener('click', (e) => {
    if (!e.target.closest('#colorPalettePopup') && !e.target.closest('#annotColorBtn')) {
      $('colorPalettePopup')?.classList.add('hidden');
    }
  });
}

// Expose globals for inline HTML event handlers & dynamic router
window.openReader = openReader;
window.openReaderPage = openReaderPage;
window.closeReader = closeReader;
window.showView = showView;
window.setTheme = setTheme;
window.setQari = setQari;
window.playAyah = playAyah;
window.playBismillah = playBismillah;
window.playSurahByNumber = playSurahByNumber;
window.togglePlaySurah = togglePlaySurah;
window.renderAudioStudio = renderAudioStudio;
window.renderBackupView = renderBackupView;
window.renderFAQ = renderFAQ;
window.handleRoute = handleRoute;
window.exportBackup = exportBackup;
window.showToast = showToast;
window.toggleTafsirDrawer = toggleTafsirDrawer;
window.toggleAnnotationSuite = toggleAnnotationSuite;
window.saveCurrentPageAnnotation = saveCurrentPageAnnotation;
window.loadPageAnnotation = loadPageAnnotation;
window.clearPageAnnotation = clearPageAnnotation;