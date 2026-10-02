class AyahOfDay {
  final int surah;
  final int ayah;
  final String ar;
  final String en;
  final String reflection;
  const AyahOfDay({
    required this.surah,
    required this.ayah,
    required this.ar,
    required this.en,
    required this.reflection,
  });
}

const List<AyahOfDay> ayahOfDayList = [
  AyahOfDay(
    surah: 2,
    ayah: 152,
    ar: "فَٱذۡكُرُونِيٓ أَذۡكُرۡكُمۡ وَٱشۡكُرُواْ لِي وَلَا تَكۡفُرُونِ",
    en: "So remember Me; I will remember you. And be grateful to Me and do not deny Me",
    reflection:
        "Allah ka wada: tum Mujhe yaad karo, Main tumhe yaad karunga — zikr dil ka sukoon hai.",
  ),
  AyahOfDay(
    surah: 2,
    ayah: 186,
    ar: "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌۖ أُجِيبُ دَعۡوَةَ ٱلدَّاعِ إِذَا دَعَانِۖ فَلۡيَسۡتَجِيبُواْ لِي وَلۡيُؤۡمِنُواْ بِي لَعَلَّهُمۡ يَرۡشُدُونَ",
    en: "And when My servants ask you, [O Muhammad], concerning Me - indeed I am near. I respond to the invocation of the supplicant when he calls upon Me. So let them respond to Me [by obedience] and believe in Me that they may be [rightly] guided",
    reflection:
        "Allah tumhaare qareeb hai — dua karo, Woh sunta hai aur jawab deta hai.",
  ),
  AyahOfDay(
    surah: 2,
    ayah: 286,
    ar: "لَا يُكَلِّفُ ٱللَّهُ نَفۡسًا إِلَّا وُسۡعَهَاۚ لَهَا مَا كَسَبَتۡ وَعَلَيۡهَا مَا ٱكۡتَسَبَتۡۗ رَبَّنَا لَا تُؤَاخِذۡنَآ إِن نَّسِينَآ أَوۡ أَخۡطَأۡنَاۚ رَبَّنَا وَلَا تَحۡمِلۡ عَلَيۡنَآ إِصۡرࣰ ا كَمَا حَمَلۡتَهُۥ عَلَى ٱلَّذِينَ مِن قَبۡلِنَاۚ رَبَّنَا وَلَا تُحَمِّلۡنَا مَا لَا طَاقَةَ لَنَا بِهِۦۖ وَٱعۡفُ عَنَّا وَٱغۡفِرۡ لَنَا وَٱرۡحَمۡنَآۚ أَنتَ مَوۡلَىٰنَا فَٱنصُرۡنَا عَلَى ٱلۡقَوۡمِ ٱلۡكَٰفِرِينَ",
    en: "Allah does not charge a soul except [with that within] its capacity. It will have [the consequence of] what [good] it has gained, and it will bear [the consequence of] what [evil] it has earned. \"Our Lord, do not impose blame upon us if we have forgotten or erred. Our Lord, and lay not upon us a burden like that which You laid upon those before us. Our Lord, and burden us not with that which we have no ability to bear. And pardon us; and forgive us; and have mercy upon us. You are our protector, so give us victory over the disbelieving people",
    reflection:
        "Allah kisi jaan par uski taqat se zyada bojh nahi daalta — har mushkil tumse chhoti hai.",
  ),
  AyahOfDay(
    surah: 3,
    ayah: 139,
    ar: "وَلَا تَهِنُواْ وَلَا تَحۡزَنُواْ وَأَنتُمُ ٱلۡأَعۡلَوۡنَ إِن كُنتُم مُّؤۡمِنِينَ",
    en: "So do not weaken and do not grieve, and you will be superior if you are [true] believers",
    reflection:
        "Gham na karo, mayus na ho — agar tum sache momin ho to tum hi ghalib rahoge.",
  ),
  AyahOfDay(
    surah: 3,
    ayah: 160,
    ar: "إِن يَنصُرۡكُمُ ٱللَّهُ فَلَا غَالِبَ لَكُمۡۖ وَإِن يَخۡذُلۡكُمۡ فَمَن ذَا ٱلَّذِي يَنصُرُكُم مِّنۢ بَعۡدِهِۦۗ وَعَلَى ٱللَّهِ فَلۡيَتَوَكَّلِ ٱلۡمُؤۡمِنُونَ",
    en: "If Allah should aid you, no one can overcome you; but if He should forsake you, who is there that can aid you after Him? And upon Allah let the believers rely",
    reflection:
        "Agar Allah tumhari madad kare to koi tum par ghalib nahi aa sakta — sirf Us par bharosa rakho.",
  ),
  AyahOfDay(
    surah: 13,
    ayah: 28,
    ar: "ٱلَّذِينَ ءَامَنُواْ وَتَطۡمَئِنُّ قُلُوبُهُم بِذِكۡرِ ٱللَّهِۗ أَلَا بِذِكۡرِ ٱللَّهِ تَطۡمَئِنُّ ٱلۡقُلُوبُ",
    en: "Those who have believed and whose hearts are assured by the remembrance of Allah. Unquestionably, by the remembrance of Allah hearts are assured",
    reflection:
        "Dil Allah ke zikr se hi chain paate hain — sukoon ki dawa zikr hai, duniya nahi.",
  ),
  AyahOfDay(
    surah: 14,
    ayah: 7,
    ar: "وَإِذۡ تَأَذَّنَ رَبُّكُمۡ لَئِن شَكَرۡتُمۡ لَأَزِيدَنَّكُمۡۖ وَلَئِن كَفَرۡتُمۡ إِنَّ عَذَابِي لَشَدِيدࣱ‏",
    en: "And [remember] when your Lord proclaimed, 'If you are grateful, I will surely increase you [in favor]; but if you deny, indeed, My punishment is severe",
    reflection:
        "Shukr ada karo, Allah aur dega — na-shukri se bachna bhi zaroori hai.",
  ),
  AyahOfDay(
    surah: 29,
    ayah: 69,
    ar: "وَٱلَّذِينَ جَٰهَدُواْ فِينَا لَنَهۡدِيَنَّهُمۡ سُبُلَنَاۚ وَإِنَّ ٱللَّهَ لَمَعَ ٱلۡمُحۡسِنِينَ",
    en: "And those who strive for Us - We will surely guide them to Our ways. And indeed, Allah is with the doers of good",
    reflection:
        "Jo Allah ke raaste mein koshish kare, Allah uske liye raaste khol deta hai.",
  ),
  AyahOfDay(
    surah: 39,
    ayah: 53,
    ar: "۞قُلۡ يَٰعِبَادِيَ ٱلَّذِينَ أَسۡرَفُواْ عَلَىٰٓ أَنفُسِهِمۡ لَا تَقۡنَطُواْ مِن رَّحۡمَةِ ٱللَّهِۚ إِنَّ ٱللَّهَ يَغۡفِرُ ٱلذُّنُوبَ جَمِيعًاۚ إِنَّهُۥ هُوَ ٱلۡغَفُورُ ٱلرَّحِيمُ",
    en: "Say, \"O My servants who have transgressed against themselves [by sinning], do not despair of the mercy of Allah. Indeed, Allah forgives all sins. Indeed, it is He who is the Forgiving, the Merciful",
    reflection:
        "Allah ki rehmat se na-umeed mat ho — Woh tamam gunah maaf kar deta hai.",
  ),
  AyahOfDay(
    surah: 40,
    ayah: 60,
    ar: "وَقَالَ رَبُّكُمُ ٱدۡعُونِيٓ أَسۡتَجِبۡ لَكُمۡۚ إِنَّ ٱلَّذِينَ يَسۡتَكۡبِرُونَ عَنۡ عِبَادَتِي سَيَدۡخُلُونَ جَهَنَّمَ دَاخِرِينَ",
    en: "And your Lord says, \"Call upon Me; I will respond to you.\" Indeed, those who disdain My worship will enter Hell [rendered] contemptible",
    reflection:
        "Mujhe pukaaro, Main tumhari dua qubool karunga — mangne mein der na karo.",
  ),
  AyahOfDay(
    surah: 55,
    ayah: 13,
    ar: "فَبِأَيِّ ءَالَآءِ رَبِّكُمَا تُكَذِّبَانِ",
    en: "So which of the favors of your Lord would you deny",
    reflection:
        "To tum apne Rab ki kaunsi nemat ko jhutlaoge? — har saans ek nemat hai.",
  ),
  AyahOfDay(
    surah: 65,
    ayah: 3,
    ar: "وَيَرۡزُقۡهُ مِنۡ حَيۡثُ لَا يَحۡتَسِبُۚ وَمَن يَتَوَكَّلۡ عَلَى ٱللَّهِ فَهُوَ حَسۡبُهُۥٓۚ إِنَّ ٱللَّهَ بَٰلِغُ أَمۡرِهِۦۚ قَدۡ جَعَلَ ٱللَّهُ لِكُلِّ شَيۡءࣲ قَدۡرࣰ ا",
    en: "And will provide for him from where he does not expect. And whoever relies upon Allah - then He is sufficient for him. Indeed, Allah will accomplish His purpose. Allah has already set for everything a [decreed] extent",
    reflection:
        "Jo Allah par tawakkul kare, Woh uske liye kaafi hai — mushkil ke baad asaani hai.",
  ),
  AyahOfDay(
    surah: 94,
    ayah: 6,
    ar: "إِنَّ مَعَ ٱلۡعُسۡرِ يُسۡرࣰ ا",
    en: "Indeed, with hardship [will be] ease",
    reflection:
        "Beshak har tangi ke saath asaani hai — ghabrao mat, waqt badal jayega.",
  ),
  AyahOfDay(
    surah: 17,
    ayah: 23,
    ar: "۞وَقَضَىٰ رَبُّكَ أَلَّا تَعۡبُدُوٓاْ إِلَّآ إِيَّاهُ وَبِٱلۡوَٰلِدَيۡنِ إِحۡسَٰنًاۚ إِمَّا يَبۡلُغَنَّ عِندَكَ ٱلۡكِبَرَ أَحَدُهُمَآ أَوۡ كِلَاهُمَا فَلَا تَقُل لَّهُمَآ أُفࣲّ وَلَا تَنۡهَرۡهُمَا وَقُل لَّهُمَا قَوۡلࣰ ا كَرِيمࣰ ا",
    en: "And your Lord has decreed that you not worship except Him, and to parents, good treatment. Whether one or both of them reach old age [while] with you, say not to them [so much as], \"uff,\" and do not repel them but speak to them a noble word",
    reflection:
        "Waalidain ke saath husn-e-sulook karo — unke liye halki si bhi naaraazi na dikhao.",
  ),
  AyahOfDay(
    surah: 4,
    ayah: 110,
    ar: "وَمَن يَعۡمَلۡ سُوٓءًا أَوۡ يَظۡلِمۡ نَفۡسَهُۥ ثُمَّ يَسۡتَغۡفِرِ ٱللَّهَ يَجِدِ ٱللَّهَ غَفُورࣰ ا رَّحِيمࣰ ا",
    en: "And whoever does a wrong or wrongs himself but then seeks forgiveness of Allah will find Allah Forgiving and Merciful",
    reflection:
        "Jo bura kare phir maafi mange, Allah ko bakhshne wala paayega — tauba ka darwaza khula hai.",
  ),
  AyahOfDay(
    surah: 25,
    ayah: 70,
    ar: "إِلَّا مَن تَابَ وَءَامَنَ وَعَمِلَ عَمَلࣰ ا صَٰلِحࣰ ا فَأُوْلَٰٓئِكَ يُبَدِّلُ ٱللَّهُ سَيِّـَٔاتِهِمۡ حَسَنَٰتࣲۗ وَكَانَ ٱللَّهُ غَفُورࣰ ا رَّحِيمࣰ ا",
    en: "Except for those who repent, believe and do righteous work. For them Allah will replace their evil deeds with good. And ever is Allah Forgiving and Merciful",
    reflection:
        "Sacchi tauba ke baad nekiyan gunahon ki jagah le leti hain — pichli galtiyan aane wali nekiyon ka wada nahi rokti.",
  ),
  AyahOfDay(
    surah: 5,
    ayah: 8,
    ar: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ كُونُواْ قَوَّٰمِينَ لِلَّهِ شُهَدَآءَ بِٱلۡقِسۡطِۖ وَلَا يَجۡرِمَنَّكُمۡ شَنَـَٔانُ قَوۡمٍ عَلَىٰٓ أَلَّا تَعۡدِلُواْۚ ٱعۡدِلُواْ هُوَ أَقۡرَبُ لِلتَّقۡوَىٰۖ وَٱتَّقُواْ ٱللَّهَۚ إِنَّ ٱللَّهَ خَبِيرُۢ بِمَا تَعۡمَلُونَ",
    en: "O you who have believed, be persistently standing firm for Allah, witnesses in justice, and do not let the hatred of a people prevent you from being just. Be just; that is nearer to righteousness. And fear Allah; indeed, Allah is Acquainted with what you do",
    reflection:
        "Insaaf par qayam raho, chahe khilaf apnon ke ho — Allah insaaf karne walon se mohabbat karta hai.",
  ),
  AyahOfDay(
    surah: 16,
    ayah: 90,
    ar: "۞إِنَّ ٱللَّهَ يَأۡمُرُ بِٱلۡعَدۡلِ وَٱلۡإِحۡسَٰنِ وَإِيتَآيِٕ ذِي ٱلۡقُرۡبَىٰ وَيَنۡهَىٰ عَنِ ٱلۡفَحۡشَآءِ وَٱلۡمُنكَرِ وَٱلۡبَغۡيِۚ يَعِظُكُمۡ لَعَلَّكُمۡ تَذَكَّرُونَ",
    en: "Indeed, Allah orders justice and good conduct and giving to relatives and forbids immorality and bad conduct and oppression. He admonishes you that perhaps you will be reminded",
    reflection:
        "Allah insaaf aur ehsaan ka hukm deta hai — doosron ke saath acha sulook imaan ka hissa hai.",
  ),
  AyahOfDay(
    surah: 49,
    ayah: 13,
    ar: "يَٰٓأَيُّهَا ٱلنَّاسُ إِنَّا خَلَقۡنَٰكُم مِّن ذَكَرࣲ وَأُنثَىٰ وَجَعَلۡنَٰكُمۡ شُعُوبࣰ ا وَقَبَآئِلَ لِتَعَارَفُوٓاْۚ إِنَّ أَكۡرَمَكُمۡ عِندَ ٱللَّهِ أَتۡقَىٰكُمۡۚ إِنَّ ٱللَّهَ عَلِيمٌ خَبِيرࣱ‏",
    en: "O mankind, indeed We have created you from male and female and made you peoples and tribes that you may know one another. Indeed, the most noble of you in the sight of Allah is the most righteous of you. Indeed, Allah is Knowing and Acquainted",
    reflection:
        "Sab insaan ek maa-baap se hain — izzat taqwa mein hai, nasab mein nahi.",
  ),
  AyahOfDay(
    surah: 3,
    ayah: 103,
    ar: "وَٱعۡتَصِمُواْ بِحَبۡلِ ٱللَّهِ جَمِيعࣰ ا وَلَا تَفَرَّقُواْۚ وَٱذۡكُرُواْ نِعۡمَتَ ٱللَّهِ عَلَيۡكُمۡ إِذۡ كُنتُمۡ أَعۡدَآءࣰ فَأَلَّفَ بَيۡنَ قُلُوبِكُمۡ فَأَصۡبَحۡتُم بِنِعۡمَتِهِۦٓ إِخۡوَٰنࣰ ا وَكُنتُمۡ عَلَىٰ شَفَا حُفۡرَةࣲ مِّنَ ٱلنَّارِ فَأَنقَذَكُم مِّنۡهَاۗ كَذَٰلِكَ يُبَيِّنُ ٱللَّهُ لَكُمۡ ءَايَٰتِهِۦ لَعَلَّكُمۡ تَهۡتَدُونَ",
    en: "And hold firmly to the rope of Allah all together and do not become divided. And remember the favor of Allah upon you - when you were enemies and He brought your hearts together and you became, by His favor, brothers. And you were on the edge of a pit of the Fire, and He saved you from it. Thus does Allah make clear to you His verses that you may be guided",
    reflection:
        "Allah ki rassi ko mazbooti se pakdo aur tafriqe se bacho — ittehaad mein taqat hai.",
  ),
  AyahOfDay(
    surah: 2,
    ayah: 201,
    ar: "وَمِنۡهُم مَّن يَقُولُ رَبَّنَآ ءَاتِنَا فِي ٱلدُّنۡيَا حَسَنَةࣰ وَفِي ٱلۡأٓخِرَةِ حَسَنَةࣰ وَقِنَا عَذَابَ ٱلنَّارِ",
    en: "But among them is he who says, \"Our Lord, give us in this world [that which is] good and in the Hereafter [that which is] good and protect us from the punishment of the Fire",
    reflection:
        "Duniya mein bhalai aur aakhirat mein bhalai mango — dono jahaan ka khayal rakho.",
  ),
  AyahOfDay(
    surah: 7,
    ayah: 23,
    ar: "قَالَا رَبَّنَا ظَلَمۡنَآ أَنفُسَنَا وَإِن لَّمۡ تَغۡفِرۡ لَنَا وَتَرۡحَمۡنَا لَنَكُونَنَّ مِنَ ٱلۡخَٰسِرِينَ",
    en: "They said, \"Our Lord, we have wronged ourselves, and if You do not forgive us and have mercy upon us, we will surely be among the losers",
    reflection:
        "Apni galti maan lena tauba ki pehli seedhi hai — Adam (A.S.) ne yahi dua maangi thi.",
  ),
  AyahOfDay(
    surah: 21,
    ayah: 87,
    ar: "وَذَا ٱلنُّونِ إِذ ذَّهَبَ مُغَٰضِبࣰ ا فَظَنَّ أَن لَّن نَّقۡدِرَ عَلَيۡهِ فَنَادَىٰ فِي ٱلظُّلُمَٰتِ أَن لَّآ إِلَٰهَ إِلَّآ أَنتَ سُبۡحَٰنَكَ إِنِّي كُنتُ مِنَ ٱلظَّٰلِمِينَ",
    en: "And [mention] the man of the fish, when he went off in anger and thought that We would not decree [anything] upon him. And he called out within the darknesses, \"There is no deity except You; exalted are You. Indeed, I have been of the wrongdoers",
    reflection:
        "Andheron mein bhi umeed hai — Yunus (A.S.) ki dua har mushkil mein kaam aati hai.",
  ),
  AyahOfDay(
    surah: 20,
    ayah: 25,
    ar: "قَالَ رَبِّ ٱشۡرَحۡ لِي صَدۡرِي",
    en: "[Moses] said, \"My Lord, expand for me my breast [with assurance]",
    reflection:
        "Musa (A.S.) ne kaam shuru karne se pehle dua maangi — mushkil kaam se pehle Allah se madad lo.",
  ),
  AyahOfDay(
    surah: 3,
    ayah: 8,
    ar: "رَبَّنَا لَا تُزِغۡ قُلُوبَنَا بَعۡدَ إِذۡ هَدَيۡتَنَا وَهَبۡ لَنَا مِن لَّدُنكَ رَحۡمَةًۚ إِنَّكَ أَنتَ ٱلۡوَهَّابُ",
    en: "[Who say], \"Our Lord, let not our hearts deviate after You have guided us and grant us from Yourself mercy. Indeed, You are the Bestower",
    reflection:
        "Hidayat milne ke baad dilon ko phirne na do — har roz hidayat ki dua karo.",
  ),
  AyahOfDay(
    surah: 66,
    ayah: 8,
    ar: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُواْ تُوبُوٓاْ إِلَى ٱللَّهِ تَوۡبَةࣰ نَّصُوحًا عَسَىٰ رَبُّكُمۡ أَن يُكَفِّرَ عَنكُمۡ سَيِّـَٔاتِكُمۡ وَيُدۡخِلَكُمۡ جَنَّٰتࣲ تَجۡرِي مِن تَحۡتِهَا ٱلۡأَنۡهَٰرُ يَوۡمَ لَا يُخۡزِي ٱللَّهُ ٱلنَّبِيَّ وَٱلَّذِينَ ءَامَنُواْ مَعَهُۥۖ نُورُهُمۡ يَسۡعَىٰ بَيۡنَ أَيۡدِيهِمۡ وَبِأَيۡمَٰنِهِمۡ يَقُولُونَ رَبَّنَآ أَتۡمِمۡ لَنَا نُورَنَا وَٱغۡفِرۡ لَنَآۖ إِنَّكَ عَلَىٰ كُلِّ شَيۡءࣲ قَدِيرࣱ‏",
    en: "O you who have believed, repent to Allah with sincere repentance. Perhaps your Lord will remove from you your misdeeds and admit you into gardens beneath which rivers flow [on] the Day when Allah will not disgrace the Prophet and those who believed with him. Their light will proceed before them and on their right; they will say, \"Our Lord, perfect for us our light and forgive us. Indeed, You are over all things competent",
    reflection:
        "Sacchi tauba naseeb ho — Allah se maango ke Woh tumhare gunah mita de aur jannat de.",
  ),
  AyahOfDay(
    surah: 24,
    ayah: 35,
    ar: "۞ٱللَّهُ نُورُ ٱلسَّمَٰوَٰتِ وَٱلۡأَرۡضِۚ مَثَلُ نُورِهِۦ كَمِشۡكَوٰةࣲ فِيهَا مِصۡبَاحٌۖ ٱلۡمِصۡبَاحُ فِي زُجَاجَةٍۖ ٱلزُّجَاجَةُ كَأَنَّهَا كَوۡكَبࣱ دُرِّيࣱّ يُوقَدُ مِن شَجَرَةࣲ مُّبَٰرَكَةࣲ زَيۡتُونَةࣲ لَّا شَرۡقِيَّةࣲ وَلَا غَرۡبِيَّةࣲ يَكَادُ زَيۡتُهَا يُضِيٓءُ وَلَوۡ لَمۡ تَمۡسَسۡهُ نَارࣱۚ نُّورٌ عَلَىٰ نُورࣲۚ يَهۡدِي ٱللَّهُ لِنُورِهِۦ مَن يَشَآءُۚ وَيَضۡرِبُ ٱللَّهُ ٱلۡأَمۡثَٰلَ لِلنَّاسِۗ وَٱللَّهُ بِكُلِّ شَيۡءٍ عَلِيمࣱ‏",
    en: "Allah is the Light of the heavens and the earth. The example of His light is like a niche within which is a lamp, the lamp is within glass, the glass as if it were a pearly [white] star lit from [the oil of] a blessed olive tree, neither of the east nor of the west, whose oil would almost glow even if untouched by fire. Light upon light. Allah guides to His light whom He wills. And Allah presents examples for the people, and Allah is Knowing of all things",
    reflection:
        "Allah aasmaano aur zameen ka noor hai — Uska noor dilon ko roshan karta hai.",
  ),
  AyahOfDay(
    surah: 1,
    ayah: 5,
    ar: "إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ",
    en: "It is You we worship and You we ask for help",
    reflection:
        "Sirf Allah ki ibaadat, sirf Us se madad — yahi tauheed ka khulasa hai.",
  ),
  AyahOfDay(
    surah: 2,
    ayah: 45,
    ar: "وَٱسۡتَعِينُواْ بِٱلصَّبۡرِ وَٱلصَّلَوٰةِۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى ٱلۡخَٰشِعِينَ",
    en: "And seek help through patience and prayer, and indeed, it is difficult except for the humbly submissive [to Allah]",
    reflection:
        "Sabr aur namaz se madad lo — namaz mushkil waqt ka sab se bada sahara hai.",
  ),
  AyahOfDay(
    surah: 41,
    ayah: 34,
    ar: "وَلَا تَسۡتَوِي ٱلۡحَسَنَةُ وَلَا ٱلسَّيِّئَةُۚ ٱدۡفَعۡ بِٱلَّتِي هِيَ أَحۡسَنُ فَإِذَا ٱلَّذِي بَيۡنَكَ وَبَيۡنَهُۥ عَدَٰوَةࣱ كَأَنَّهُۥ وَلِيٌّ حَمِيمࣱ‏",
    en: "And not equal are the good deed and the bad. Repel [evil] by that [deed] which is better; and thereupon the one whom between you and him is enmity [will become] as though he was a devoted friend",
    reflection:
        "Burai ka jawab bhalai se do — narmi dushman ko bhi dost bana deti hai.",
  ),
];

/// Returns the ayah of the day for [date] (rotates through the list by day of month).
AyahOfDay ayahOfDayFor(DateTime date) =>
    ayahOfDayList[(date.day - 1) % ayahOfDayList.length];
