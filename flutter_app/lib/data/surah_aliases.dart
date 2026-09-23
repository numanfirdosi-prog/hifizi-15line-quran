// Map of 549+ popular search aliases (Hindi, English, Urdu phonetics, Ayat-ul-Kursi, Amma, etc.)
final Map<String, int> surahAliasesMap = {
  // Surah 1: Al-Fatihah
  'fatiha': 1, 'fateha': 1, 'fatehah': 1, 'fatihah': 1, 'al fatiha': 1, 'al fatihah': 1,
  'alhamd': 1, 'al-hamd': 1, 'al hamd': 1, 'alhamdulillah': 1, 'फातिहा': 1, 'फ़ातिहा': 1, 'अल्हमद': 1, 'अल्हम्दुलिल्लाह': 1,

  // Surah 2: Al-Baqarah
  'baqra': 2, 'baqara': 2, 'baqarah': 2, 'bakra': 2, 'al baqara': 2, 'al baqrah': 2,
  'kursi': 2, 'ayatul kursi': 2, 'ayatal kursi': 2, 'ayat al kursi': 2,
  'बकरा': 2, 'बक़रह': 2, 'कुर्सी': 2, 'आयतुल कुर्सी': 2, 'आयतुलकुर्सी': 2,

  // Surah 3: Ali 'Imran
  'imran': 3, 'ali imran': 3, 'ali \'imran': 3, 'aal e imran': 3, 'aal imran': 3, 'आले इमरान': 3, 'आल इमरान': 3, 'इमरान': 3,

  // Surah 4: An-Nisa
  'nisa': 4, 'an nisa': 4, 'aurat': 4, 'निसा': 4, 'अन निसा': 4,

  // Surah 5: Al-Ma'idah
  'maida': 5, 'maidah': 5, 'al maida': 5, 'al maidah': 5, 'माइदा': 5, 'मायदा': 5,

  // Surah 6: Al-An'am
  'anam': 6, 'al anam': 6, 'an\'am': 6, 'अनआम': 6,

  // Surah 7: Al-A'raf
  'araf': 7, 'al araf': 7, 'a\'raf': 7, 'आराफ': 7, 'अराफ': 7,

  // Surah 8: Al-Anfal
  'anfal': 8, 'al anfal': 8, 'अनफाल': 8,

  // Surah 9: At-Tawbah
  'tawbah': 9, 'tawba': 9, 'taubah': 9, 'at tawbah': 9, 'bara\'at': 9, 'तौबा': 9,

  // Surah 10: Yunus
  'yunus': 10, 'jonah': 10, 'यूनुस': 10, 'युनुस': 10,

  // Surah 11: Hud
  'hud': 11, 'हूद': 11, 'हुद': 11,

  // Surah 12: Yusuf
  'yusuf': 12, 'yousuf': 12, 'joseph': 12, 'यूसुफ': 12, 'युसुफ': 12,

  // Surah 13: Ar-Ra'd
  'rad': 13, 'ar rad': 13, 'ra\'d': 13, 'राद': 13,

  // Surah 14: Ibrahim
  'ibrahim': 14, 'abraham': 14, 'इब्राहीम': 14, 'इब्राहिम': 14,

  // Surah 15: Al-Hijr
  'hijr': 15, 'al hijr': 15, 'हिज्र': 15,

  // Surah 16: An-Nahl
  'nahl': 16, 'an nahl': 16, 'नहल': 16,

  // Surah 17: Al-Isra
  'isra': 17, 'al isra': 17, 'bani israel': 17, 'bani israil': 17, 'subhan': 17, 'subhanallazi': 17,
  'इसरा': 17, 'बनी इसराइल': 17, 'बनी इस्राईल': 17, 'सुब्हान': 17,

  // Surah 18: Al-Kahf
  'kahf': 18, 'al kahf': 18, 'kahaf': 18, 'al kahaf': 18, 'कहफ': 18, 'कहफ़': 18,

  // Surah 19: Maryam
  'maryam': 19, 'mariam': 19, 'mary': 19, 'मरयम': 19, 'मरियम': 19,

  // Surah 20: Ta-Ha
  'taha': 20, 'ta-ha': 20, 'ta ha': 20, 'ताहा': 20, 'ता-हा': 20,

  // Surah 21: Al-Anbiya
  'anbiya': 21, 'al anbiya': 21, 'ambiya': 21, 'अंबिया': 21, 'अम्बिया': 21,

  // Surah 22: Al-Hajj
  'hajj': 22, 'al hajj': 22, 'हज': 22,

  // Surah 23: Al-Mu'minun
  'muminun': 23, 'mominun': 23, 'al mominun': 23, 'mu\'minun': 23, 'मोमिनून': 23, 'मुमिनून': 23,

  // Surah 24: An-Nur
  'nur': 24, 'an nur': 24, 'noor': 24, 'नूर': 24,

  // Surah 25: Al-Furqan
  'furqan': 25, 'al furqan': 25, 'फुरकान': 25, 'फ़ुरक़ान': 25,

  // Surah 26: Ash-Shu'ara
  'shuara': 26, 'ash shuara': 26, 'shu\'ara': 26, 'शुआरा': 26,

  // Surah 27: An-Naml
  'naml': 27, 'an naml': 27, 'नमल': 27, 'नम्ल': 27,

  // Surah 28: Al-Qasas
  'qasas': 28, 'al qasas': 28, 'कसस': 28, 'क़सस': 28,

  // Surah 29: Al-Ankabut
  'ankabut': 29, 'al ankabut': 29, 'spider': 29, 'अंकबूत': 29,

  // Surah 30: Ar-Rum
  'rum': 30, 'ar rum': 30, 'romans': 30, 'रूम': 30,

  // Surah 31: Luqman
  'luqman': 31, 'लुकमान': 31, 'लुक़मान': 31,

  // Surah 32: As-Sajdah
  'sajdah': 32, 'sajda': 32, 'as sajdah': 32, 'सजदा': 32,

  // Surah 33: Al-Ahzab
  'ahzab': 33, 'al ahzab': 33, 'अहजाब': 33, 'अहज़ाब': 33,

  // Surah 34: Saba
  'saba': 34, 'सबा': 34,

  // Surah 35: Fatir
  'fatir': 35, 'al fatir': 35, 'फातिर': 35, 'फ़ातिर': 35,

  // Surah 36: Ya-Sin
  'yaseen': 36, 'yasin': 36, 'ya-sin': 36, 'yaseen sharif': 36, 'yasin sharif': 36,
  'यासीन': 36, 'या-सीन': 36, 'यासिन': 36,

  // Surah 37: As-Saffat
  'saffat': 37, 'as saffat': 37, 'साफ्फात': 37, 'साफात': 37,

  // Surah 38: Sad
  'sad': 38, 'swad': 38, 'साद': 38, 'स्वाद': 38,

  // Surah 39: Az-Zumar
  'zumar': 39, 'az zumar': 39, 'जुमर': 39, 'ज़ुमर': 39,

  // Surah 40: Ghafir
  'ghafir': 40, 'momin': 40, 'gafir': 40, 'गाफिर': 40, 'ग़ाफ़िर': 40, 'मोमिन': 40,

  // Surah 41: Fussilat
  'fussilat': 41, 'hamim sajda': 41, 'ha mim sajda': 41, 'फुस्सिलत': 41, 'हामीम सजदा': 41,

  // Surah 42: Ash-Shura
  'shura': 42, 'ash shura': 42, 'शूरा': 42,

  // Surah 43: Az-Zukhruf
  'zukhruf': 43, 'az zukhruf': 43, 'जुखरुफ': 43, 'ज़ुख़रुफ़': 43,

  // Surah 44: Ad-Dukhan
  'dukhan': 44, 'ad dukhan': 44, 'smoke': 44, 'दुखान': 44,

  // Surah 45: Al-Jathiyah
  'jathiya': 45, 'jasiya': 45, 'जासिया': 45,

  // Surah 46: Al-Ahqaf
  'ahqaf': 46, 'al ahqaf': 46, 'अहकाफ': 46, 'अहक़ाफ़': 46,

  // Surah 47: Muhammad
  'muhammad': 47, 'mohammed': 47, 'mohammad': 47, 'मुहम्मद': 47, 'मोहम्मद': 47,

  // Surah 48: Al-Fath
  'fath': 48, 'al fath': 48, 'fatah': 48, 'फतह': 48, 'फ़तह': 48,

  // Surah 49: Al-Hujurat
  'hujurat': 49, 'al hujurat': 49, 'हुजुरात': 49,

  // Surah 50: Qaf
  'qaf': 50, 'काफ': 50, 'क़ाफ़': 50,

  // Surah 51: Adh-Dhariyat
  'dhariyat': 51, 'zariyat': 51, 'जारियात': 51, 'ज़ारियात': 51,

  // Surah 52: At-Tur
  'tur': 52, 'at tur': 52, 'तूर': 52,

  // Surah 53: An-Najm
  'najm': 53, 'an najm': 53, 'star': 53, 'नजम': 53, 'नज्म': 53,

  // Surah 54: Al-Qamar
  'qamar': 54, 'al qamar': 54, 'moon': 54, 'कमर': 54, 'क़मर': 54,

  // Surah 55: Ar-Rahman
  'rehman': 55, 'ar rehman': 55, 'ar-rehman': 55, 'al rehman': 55,
  'rahman': 55, 'ar rahman': 55, 'ar-rahman': 55, 'al rahman': 55, 'रहमान': 55,

  // Surah 56: Al-Waqi'ah
  'waqia': 56, 'waqiah': 56, 'al waqia': 56, 'waqiya': 56, 'al waqiah': 56,
  'वाकिया': 56, 'वाक़िया': 56,

  // Surah 57: Al-Hadid
  'hadid': 57, 'al hadid': 57, 'iron': 57, 'हदीद': 57,

  // Surah 58: Al-Mujadila
  'mujadila': 58, 'al mujadila': 58, 'मुजादिला': 58,

  // Surah 59: Al-Hashr
  'hashr': 59, 'al hashr': 59, 'हशर': 59, 'हश्र': 59,

  // Surah 60: Al-Mumtahanah
  'mumtahina': 60, 'mumtahana': 60, 'al mumtahanah': 60, 'मुमतहिना': 60,

  // Surah 61: As-Saff
  'saff': 61, 'as saff': 61, 'सफ': 61, 'सफ़': 61,

  // Surah 62: Al-Jumu'ah
  'juma': 62, 'jummah': 62, 'jumuah': 62, 'al jumuah': 62, 'friday': 62,
  'जुमा': 62, 'जुमुआ': 62,

  // Surah 63: Al-Munafiqun
  'munafiqun': 63, 'munafiqoon': 63, 'मुनाफिकून': 63, 'मुनाफ़िक़ून': 63,

  // Surah 64: At-Taghabun
  'taghabun': 64, 'at taghabun': 64, 'तगाबुन': 64, 'तग़ाबुन': 64,

  // Surah 65: At-Talaq
  'talaq': 65, 'at talaq': 65, 'तलाक': 65, 'तलाक़': 65,

  // Surah 66: At-Tahrim
  'tahrim': 66, 'at tahrim': 66, 'तहरीम': 66,

  // Surah 67: Al-Mulk
  'mulk': 67, 'al mulk': 67, 'tabarak': 67, 'tabarakallazi': 67, 'मुल्क': 67, 'तबारक': 67,

  // Surah 68: Al-Qalam
  'qalam': 68, 'al qalam': 68, 'noon': 68, 'कलम': 68, 'क़लम': 68, 'नून': 68,

  // Surah 69: Al-Haqqah
  'haqqah': 69, 'al haqqah': 69, 'हाक्का': 69, 'हाक़्क़ा': 69,

  // Surah 70: Al-Ma'arij
  'maarij': 70, 'al maarij': 70, 'मआरिज': 70,

  // Surah 71: Nuh
  'nuh': 71, 'noah': 71, 'नूह': 71,

  // Surah 72: Al-Jinn
  'jinn': 72, 'jin': 72, 'al jinn': 72, 'जिन': 72, 'जिन्न': 72,

  // Surah 73: Al-Muzzammil
  'muzzammil': 73, 'muzammil': 73, 'al muzzammil': 73, 'मुजम्मिल': 73, 'मुज़म्मिल': 73,

  // Surah 74: Al-Muddaththir
  'muddaththir': 74, 'muddassir': 74, 'al muddassir': 74, 'मुद्दस्सिर': 74,

  // Surah 75: Al-Qiyamah
  'qiyamah': 75, 'qiyamat': 75, 'कियामत': 75, 'क़ियामा': 75, 'कियामा': 75,

  // Surah 76: Al-Insan
  'insan': 76, 'al insan': 76, 'dahr': 76, 'इंसान': 76, 'दहर': 76,

  // Surah 77: Al-Mursalat
  'mursalat': 77, 'al mursalat': 77, 'मुरसलात': 77,

  // Surah 78: An-Naba
  'naba': 78, 'an naba': 78, 'amma': 78, 'amma yatasaalun': 78, 'नबा': 78, 'अम्मा': 78,

  // Surah 79: An-Nazi'at
  'naziat': 79, 'an naziat': 79, 'नाजियात': 79, 'नाज़िआत': 79,

  // Surah 80: Abasa
  'abasa': 80, 'अबसा': 80, 'अबस': 80,

  // Surah 81: At-Takwir
  'takwir': 81, 'at takwir': 81, 'तकवीर': 81,

  // Surah 82: Al-Infitar
  'infitar': 82, 'al infitar': 82, 'इन्फितार': 82, 'इन्फ़ितार': 82,

  // Surah 83: Al-Mutaffifin
  'mutaffifin': 83, 'al mutaffifin': 83, 'मुतफ्फिफीन': 83,

  // Surah 84: Al-Inshiqaq
  'inshiqaq': 84, 'al inshiqaq': 84, 'इनशिकाक': 84,

  // Surah 85: Al-Buruj
  'buruj': 85, 'al buruj': 85, 'बुरुज': 85,

  // Surah 86: At-Tariq
  'tariq': 86, 'at tariq': 86, 'तारिक': 86, 'तारिक़': 86,

  // Surah 87: Al-A'la
  'ala': 87, 'al ala': 87, 'sabbi hisma': 87, 'आला': 87, 'सब्बिहिस्मा': 87,

  // Surah 88: Al-Ghashiyah
  'ghashiyah': 88, 'al ghashiyah': 88, 'गाशिया': 88, 'ग़ाशिया': 88,

  // Surah 89: Al-Fajr
  'fajr': 89, 'al fajr': 89, 'fajar': 89, 'फज्र': 89, 'फ़ज्र': 89, 'फजर': 89,

  // Surah 90: Al-Balad
  'balad': 90, 'al balad': 90, 'बलद': 90,

  // Surah 91: Ash-Shams
  'shams': 91, 'ash shams': 91, 'sun': 91, 'शम्स': 91,

  // Surah 92: Al-Layl
  'layl': 92, 'al layl': 92, 'लैल': 92,

  // Surah 93: Ad-Duha
  'duha': 93, 'ad duha': 93, 'wadduha': 93, 'दुहा': 93, 'जुहा': 93, 'वद्दुहा': 93,

  // Surah 94: Ash-Sharh
  'sharh': 94, 'inshirah': 94, 'alam nashrah': 94, 'शरह': 94, 'अलम नशरह': 94,

  // Surah 95: At-Tin
  'tin': 95, 'at tin': 95, 'watin': 95, 'तीन': 95, 'वत्तीन': 95,

  // Surah 96: Al-Alaq
  'alaq': 96, 'al alaq': 96, 'iqra': 96, 'अलक': 96, 'अलक़': 96, 'इकरा': 96,

  // Surah 97: Al-Qadr
  'qadr': 97, 'al qadr': 97, 'shab e qadr': 97, 'inna anzalna': 97, 'कद्र': 97, 'क़द्र': 97, 'इन्ना अनज़लना': 97,

  // Surah 98: Al-Bayyinah
  'bayyinah': 98, 'al bayyinah': 98, 'lam yakun': 98, 'बय्यिना': 98, 'लम यकुन': 98,

  // Surah 99: Az-Zalzalah
  'zalzalah': 99, 'zilzal': 99, 'iza zulzilat': 99, 'जलजला': 99, 'ज़लज़ला': 99,

  // Surah 100: Al-Adiyat
  'adiyat': 100, 'al adiyat': 100, 'wal adiyat': 100, 'आदियात': 100, 'वल आदियात': 100,

  // Surah 101: Al-Qari'ah
  'qariah': 101, 'al qariah': 101, 'कारिआ': 101, 'क़ारिआ': 101,

  // Surah 102: At-Takathur
  'takathur': 102, 'al takathur': 102, 'alhakum': 102, 'तकासुर': 102,

  // Surah 103: Al-Asr
  'asr': 103, 'al asr': 103, 'wal asr': 103, 'असर': 103, 'वल असर': 103,

  // Surah 104: Al-Humazah
  'humazah': 104, 'al humazah': 104, 'wailul likulli': 104, 'हुमजा': 104, 'हुमज़ा': 104, 'वैलुल लिकुल्ली': 104,

  // Surah 105: Al-Fil
  'fil': 105, 'al fil': 105, 'feel': 105, 'alam tara': 105, 'alam tara kaifa': 105,
  'फील': 105, 'फ़ील': 105, 'अलम तरा': 105,

  // Surah 106: Quraysh
  'quraysh': 106, 'li ilafi': 106, 'कुरैश': 106, 'क़ुरैश': 106, 'ली ईलाफ': 106,

  // Surah 107: Al-Ma'un
  'maun': 107, 'al maun': 107, 'ara aytallazi': 107, 'माऊन': 107, 'अरअयतल लज़ी': 107,

  // Surah 108: Al-Kawthar
  'kawthar': 108, 'kausar': 108, 'al kawthar': 108, 'inna aataina': 108, 'inna atayna': 108,
  'कौसर': 108, 'इन्ना आतैना': 108,

  // Surah 109: Al-Kafirun
  'kafirun': 109, 'al kafirun': 109, 'kafiroon': 109, 'qul ya ayyuhal kafirun': 109,
  'काफिरून': 109, 'काफ़िरून': 109, 'कुल या अय्युहल काफिरून': 109,

  // Surah 110: An-Nasr
  'nasr': 110, 'an nasr': 110, 'iza jaa': 110, 'नसर': 110, 'नस्र': 110,

  // Surah 111: Al-Masad
  'masad': 111, 'al masad': 111, 'lahab': 111, 'tabbat yada': 111, 'मसद': 111, 'तब्बत यदा': 111,

  // Surah 112: Al-Ikhlas
  'ikhlas': 112, 'al ikhlas': 112, 'ikhlaas': 112, 'qul huwallah': 112, 'kul huwallah': 112,
  'इखलास': 112, 'इख़लास': 112, 'कुल हुवल्लाह': 112,

  // Surah 113: Al-Falaq
  'falaq': 113, 'al falaq': 113, 'falak': 113, 'qul auzu birabbil falaq': 113, 'kul auzu': 113,
  'फलक': 113, 'फ़लक़': 113,

  // Surah 114: An-Nas
  'nas': 114, 'an nas': 114, 'naas': 114, 'qul auzu birabbin nas': 114, 'नास': 114
};

String cleanSurahPrefix(String text) {
  var s = text.trim();
  s = s.replaceAll(RegExp(r'^(surah|surat|soorah|para|juz|سورة|سورۃ|سورہ|پارہ|جزء|सूरह|सूरा|सूरत|पारा)\s+', caseSensitive: false), '');
  return s.trim();
}

String normalizeHindi(String str) {
  return str
      .replaceAll('क़', 'क')
      .replaceAll('ख़', 'ख')
      .replaceAll('ग़', 'ग')
      .replaceAll('ज़', 'ज')
      .replaceAll('ड़', 'ड')
      .replaceAll('ढ़', 'ढ')
      .replaceAll('फ़', 'फ')
      .replaceAll('य़', 'य')
      .replaceAll('़', '')
      .replaceAll('्', '')
      .replaceAll(RegExp(r'[\s\-_\.,\/]'), '')
      .toLowerCase();
}
