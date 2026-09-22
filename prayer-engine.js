/**
 * NŪR AL-QURAN - Prayer Times, Qiblah & Azan Engine
 * 100% Offline Astronomical Solar Calculation Engine + Compass & Alarm Suite
 */

(function(window) {
  'use strict';

  // ---------------------------------------------------------------------------
  // 1. KAABA & SOLAR CONSTANTS
  // ---------------------------------------------------------------------------
  const KAABA_LAT = 21.422487;
  const KAABA_LNG = 39.826206;

  // Preset Popular Cities (India, Pakistan, Bangladesh, Gulf, Global)
  const PRESET_CITIES = [
    // India
    { id: 'delhi', name: 'Delhi / New Delhi', urdu: 'دہلی', country: 'India', lat: 28.6139, lng: 77.2090, tz: 5.5 },
    { id: 'mumbai', name: 'Mumbai', urdu: 'ممبئی', country: 'India', lat: 19.0760, lng: 72.8777, tz: 5.5 },
    { id: 'kolkata', name: 'Kolkata', urdu: 'کولکاتہ', country: 'India', lat: 22.5726, lng: 88.3639, tz: 5.5 },
    { id: 'hyderabad', name: 'Hyderabad', urdu: 'حیدرآباد', country: 'India', lat: 17.3850, lng: 78.4867, tz: 5.5 },
    { id: 'lucknow', name: 'Lucknow', urdu: 'لکھنؤ', country: 'India', lat: 26.8467, lng: 80.9462, tz: 5.5 },
    { id: 'patna', name: 'Patna', urdu: 'پٹنہ', country: 'India', lat: 25.5941, lng: 85.1376, tz: 5.5 },
    { id: 'bengaluru', name: 'Bengaluru', urdu: 'بنگلور', country: 'India', lat: 12.9716, lng: 77.5946, tz: 5.5 },
    { id: 'ahmedabad', name: 'Ahmedabad', urdu: 'احمد آباد', country: 'India', lat: 23.0225, lng: 72.5714, tz: 5.5 },
    { id: 'srinagar', name: 'Srinagar', urdu: 'سری نگر', country: 'India', lat: 34.0837, lng: 74.7973, tz: 5.5 },
    { id: 'deoband', name: 'Deoband', urdu: 'دیوبند', country: 'India', lat: 29.6924, lng: 77.6805, tz: 5.5 },
    { id: 'bareilly', name: 'Bareilly', urdu: 'بریلی', country: 'India', lat: 28.3670, lng: 79.4304, tz: 5.5 },
    { id: 'chennai', name: 'Chennai', urdu: 'چنئی', country: 'India', lat: 13.0827, lng: 80.2707, tz: 5.5 },

    // Pakistan
    { id: 'karachi', name: 'Karachi', urdu: 'کراچی', country: 'Pakistan', lat: 24.8607, lng: 67.0011, tz: 5.0 },
    { id: 'lahore', name: 'Lahore', urdu: 'لاہور', country: 'Pakistan', lat: 31.5204, lng: 74.3587, tz: 5.0 },
    { id: 'islamabad', name: 'Islamabad / Rawalpindi', urdu: 'اسلام آباد / راولپنڈی', country: 'Pakistan', lat: 33.6844, lng: 73.0479, tz: 5.0 },
    { id: 'peshawar', name: 'Peshawar', urdu: 'پشاور', country: 'Pakistan', lat: 34.0151, lng: 71.5249, tz: 5.0 },
    { id: 'quetta', name: 'Quetta', urdu: 'کوئٹہ', country: 'Pakistan', lat: 30.1798, lng: 66.9750, tz: 5.0 },
    { id: 'multan', name: 'Multan', urdu: 'ملتان', country: 'Pakistan', lat: 30.1575, lng: 71.5249, tz: 5.0 },
    { id: 'faisalabad', name: 'Faisalabad', urdu: 'فیصل آباد', country: 'Pakistan', lat: 31.4504, lng: 73.1350, tz: 5.0 },

    // Bangladesh
    { id: 'dhaka', name: 'Dhaka', urdu: 'ڈھاکہ', country: 'Bangladesh', lat: 23.8103, lng: 90.4125, tz: 6.0 },
    { id: 'chittagong', name: 'Chittagong', urdu: 'چٹاگانگ', country: 'Bangladesh', lat: 22.3569, lng: 91.7832, tz: 6.0 },
    { id: 'sylhet', name: 'Sylhet', urdu: 'سلہٹ', country: 'Bangladesh', lat: 24.8949, lng: 91.8687, tz: 6.0 },

    // Saudi Arabia & Gulf
    { id: 'makkah', name: 'Makkah Al-Mukarramah', urdu: 'مکہ مکرمہ', country: 'Saudi Arabia', lat: 21.4225, lng: 39.8262, tz: 3.0 },
    { id: 'madinah', name: 'Al-Madinah Al-Munawwarah', urdu: 'مدینہ منورہ', country: 'Saudi Arabia', lat: 24.5247, lng: 39.5692, tz: 3.0 },
    { id: 'riyadh', name: 'Riyadh', urdu: 'ریاض', country: 'Saudi Arabia', lat: 24.7136, lng: 46.6753, tz: 3.0 },
    { id: 'dubai', name: 'Dubai', urdu: 'دبئی', country: 'UAE', lat: 25.2048, lng: 55.2708, tz: 4.0 },
    { id: 'doha', name: 'Doha', urdu: 'دوحہ', country: 'Qatar', lat: 25.2854, lng: 51.5310, tz: 3.0 },
    { id: 'kuwait', name: 'Kuwait City', urdu: 'کویت سٹی', country: 'Kuwait', lat: 29.3759, lng: 47.9774, tz: 3.0 },

    // Global
    { id: 'london', name: 'London', urdu: 'لندن', country: 'United Kingdom', lat: 51.5074, lng: -0.1278, tz: 0.0 },
    { id: 'newyork', name: 'New York', urdu: 'نیویارک', country: 'USA', lat: 40.7128, lng: -74.0060, tz: -5.0 },
    { id: 'toronto', name: 'Toronto', urdu: 'ٹورنٹو', country: 'Canada', lat: 43.6532, lng: -79.3832, tz: -5.0 }
  ];

  const storage = typeof localStorage !== 'undefined' ? localStorage : {
    getItem: () => null,
    setItem: () => {}
  };

  // State
  const state = {
    location: JSON.parse(storage.getItem('nur-prayer-location') || 'null') || PRESET_CITIES[0],
    asrJuristic: storage.getItem('nur-asr-juristic') || 'Hanafi', // 'Hanafi' or 'Standard'
    alarmSettings: JSON.parse(storage.getItem('nur-prayer-alarms') || '{"fajr":true,"dhuhr":true,"asr":true,"maghrib":true,"isha":true}'),
    azanAudioEnabled: storage.getItem('nur-azan-sound') !== 'false',
    qiblahHeading: 0,
    compassActive: false,
    lastAlarmPlayedPrayer: null
  };

  // ---------------------------------------------------------------------------
  // 2. MATHEMATICAL & ASTRONOMICAL SOLAR CALCULATION ENGINE
  // ---------------------------------------------------------------------------
  const D2R = Math.PI / 180;
  const R2D = 180 / Math.PI;

  function sinD(d) { return Math.sin(d * D2R); }
  function cosD(d) { return Math.cos(d * D2R); }
  function tanD(d) { return Math.tan(d * D2R); }
  function asinD(x) { return Math.asin(x) * R2D; }
  function acosD(x) { return Math.acos(x) * R2D; }
  function atanD(x) { return Math.atan(x) * R2D; }
  function fixAngle(a) { return a - 360 * Math.floor(a / 360); }
  function fixHour(h) { return h - 24 * Math.floor(h / 24); }

  // Sun Coordinates Calculation for a Julian Day
  function sunPosition(jd) {
    const D = jd - 2451545.0;
    const g = fixAngle(357.529 + 0.98560028 * D);
    const q = fixAngle(280.459 + 0.98564736 * D);
    const L = fixAngle(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g));
    const e = 23.439 - 0.00000036 * D;
    const d = asinD(sinD(e) * sinD(L));
    let RA = atanD(cosD(e) * sinD(L) / cosD(L)) / 15;
    if (cosD(L) < 0) RA += 12;
    else if (sinD(L) < 0) RA += 24;
    const EqT = q / 15 - fixHour(RA);
    return { declination: d, equationOfTime: EqT };
  }

  function julianDate(year, month, day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    const A = Math.floor(year / 100);
    const B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + B - 1524.5;
  }

  // Calculate Prayer Times for given date and location
  function calculatePrayerTimes(date, loc, asrMode = 'Hanafi') {
    const lat = loc.lat;
    const lng = loc.lng;
    const tz = loc.tz !== undefined ? loc.tz : -date.getTimezoneOffset() / 60;

    const jd = julianDate(date.getFullYear(), date.getMonth() + 1, date.getDate());
    const sun = sunPosition(jd);
    const d = sun.declination;
    const eqt = sun.equationOfTime;

    // Solar Noon (Zawal / Nisf-un-Nahar)
    const noon = fixHour(12 + tz - (lng / 15) - eqt);

    // Sun altitude hour angle helper
    function hourAngle(alpha) {
      const cosHA = (sinD(alpha) - sinD(lat) * sinD(d)) / (cosD(lat) * cosD(d));
      if (cosHA > 1) return null; // Sun never reaches altitude
      if (cosHA < -1) return null;
      return acosD(cosHA) / 15;
    }

    // Solar Points:
    // Tulu-e-Aftab (Sunrise) & Ghuroob-e-Aftab (Sunset): -0.8333 degrees (atmospheric refraction + solar disk)
    const sunriseAngle = -0.8333;
    const haSun = hourAngle(sunriseAngle);
    const sunrise = haSun !== null ? noon - haSun : noon - 6;
    const sunset = haSun !== null ? noon + haSun : noon + 6;

    // Fajr: 18 degrees twilight (University of Islamic Sciences, Karachi standard)
    const haFajr = hourAngle(-18);
    const fajr = haFajr !== null ? noon - haFajr : sunrise - 1.5;

    // Isha: 18 degrees twilight
    const haIsha = hourAngle(-18);
    const isha = haIsha !== null ? noon + haIsha : sunset + 1.5;

    // Asr calculation (Hanafi: shadow factor 2; Shafi/Standard: shadow factor 1)
    const shadowFactor = asrMode === 'Hanafi' ? 2 : 1;
    const asrAngle = atanD(1 / (shadowFactor + tanD(Math.abs(lat - d))));
    const haAsr = hourAngle(asrAngle);
    const asr = haAsr !== null ? noon + haAsr : noon + 3.5;

    // Zawal Makruh window: typically 10-15 mins before Dhuhr until Dhuhr start
    const zawalStart = noon - (12 / 60);
    const zawalEnd = noon;

    // Tahajjud: last third of night (between Maghrib and Fajr next morning)
    const nightDuration = fixHour(fajr + 24 - sunset);
    const tahajjud = fixHour(sunset + (nightDuration * 2 / 3));

    // Sehri / Imsak: 10 mins before Fajr
    const sehriEnd = fajr - (10 / 60);

    return {
      fajr: floatToTime(fajr),
      sunrise: floatToTime(sunrise),        // طلوع آفتاب
      zawalStart: floatToTime(zawalStart),  // زوال آفتاب شروع
      zawal: floatToTime(noon),             // زوال / نصف النہار
      dhuhr: floatToTime(noon + (2 / 60)),  // ظہر (2 mins after noon)
      asr: floatToTime(asr),                // عصر
      sunset: floatToTime(sunset),          // غروب آفتاب
      maghrib: floatToTime(sunset + (2 / 60)), // مغرب
      isha: floatToTime(isha),              // عشاء
      tahajjud: floatToTime(tahajjud),      // تہجد
      sehriEnd: floatToTime(sehriEnd),      // سحری ختم
      rawHours: {
        fajr, sunrise, zawalStart, zawal: noon, dhuhr: noon + 2/60, asr, sunset, maghrib: sunset + 2/60, isha
      }
    };
  }

  function floatToTime(h) {
    h = fixHour(h);
    const hours24 = Math.floor(h);
    const mins = Math.floor((h - hours24) * 60);
    const secs = Math.floor(((h - hours24) * 60 - mins) * 60);

    const period = hours24 >= 12 ? 'PM' : 'AM';
    let hours12 = hours24 % 12;
    if (hours12 === 0) hours12 = 12;

    const pad = (n) => String(n).padStart(2, '0');
    return {
      hours24,
      mins,
      secs,
      time24: `${pad(hours24)}:${pad(mins)}`,
      time12: `${hours12}:${pad(mins)} ${period}`,
      displayTime: `${hours12}:${pad(mins)}`,
      period: period
    };
  }

  // ---------------------------------------------------------------------------
  // 3. QIBLAH BEARING & DISTANCE ENGINE
  // ---------------------------------------------------------------------------
  function calculateQiblah(userLat, userLng) {
    const phi1 = userLat * D2R;
    const phi2 = KAABA_LAT * D2R;
    const deltaLambda = (KAABA_LNG - userLng) * D2R;

    const y = Math.sin(deltaLambda);
    const x = Math.cos(phi1) * Math.tan(phi2) - Math.sin(phi1) * Math.cos(deltaLambda);

    let qiblahAngle = Math.atan2(y, x) * R2D;
    qiblahAngle = (qiblahAngle + 360) % 360;

    // Haversine Distance in Kilometers
    const R = 6371; // Earth's mean radius
    const dLat = (KAABA_LAT - userLat) * D2R;
    const dLng = (KAABA_LNG - userLng) * D2R;
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(phi1) * Math.cos(phi2) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = Math.round(R * c);

    // Cardinal Direction Name
    const cardinals = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    const cardIdx = Math.round(qiblahAngle / 22.5) % 16;
    const cardinalName = cardinals[cardIdx];

    return {
      bearing: Math.round(qiblahAngle * 10) / 10,
      distanceKm: distanceKm,
      cardinal: cardinalName
    };
  }

  // ---------------------------------------------------------------------------
  // 4. AZAN AUDIO & NOTIFICATION SYSTEM (Mobile Autoplay Resilient)
  // ---------------------------------------------------------------------------
  let azanAudioElement = null;
  let isAudioUnlocked = false;

  function initAzanAudio() {
    if (!azanAudioElement) {
      azanAudioElement = document.getElementById('azanAudio');
      if (!azanAudioElement) {
        azanAudioElement = new Audio('assets/audio/azan.mp3');
      }
      azanAudioElement.preload = 'auto';
      azanAudioElement.setAttribute('playsinline', 'true');
      azanAudioElement.setAttribute('webkit-playsinline', 'true');
    }
    return azanAudioElement;
  }

  // Pre-unlock audio element & AudioContext on user's first touch/interaction (iOS/Android requirement)
  function unlockMobileAudio() {
    if (isAudioUnlocked) return;
    const audio = initAzanAudio();
    if (audio) {
      const prevMuted = audio.muted;
      audio.muted = true;
      const p = audio.play();
      if (p !== undefined) {
        p.then(() => {
          audio.pause();
          audio.currentTime = 0;
          audio.muted = prevMuted;
          isAudioUnlocked = true;
        }).catch(() => {});
      }
    }
    // Also unlock Web Audio context
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) {
        if (!window.__nurAudioCtx) {
          window.__nurAudioCtx = new AudioContext();
        }
        if (window.__nurAudioCtx.state === 'suspended') {
          window.__nurAudioCtx.resume().catch(() => {});
        }
      }
    } catch (e) {}
  }

  if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    ['click', 'touchstart', 'touchend', 'pointerdown'].forEach(evt => {
      document.addEventListener(evt, unlockMobileAudio, { once: false, passive: true });
    });
  }

  function playAzan(prayerName) {
    const audio = initAzanAudio();

    if (audio) {
      audio.currentTime = 0;
      audio.muted = false;
      audio.volume = 1.0;
      const p = audio.play();
      if (p !== undefined) {
        p.catch(e => {
          console.warn('MP3 playback failed or blocked by mobile policy, playing synthesized chime fallback:', e);
          playSynthesizedChime();
        });
      }
    } else {
      playSynthesizedChime();
    }

    showAzanModal(prayerName || 'Namaz');
    sendPrayerNotification(prayerName || 'Namaz');
  }

  function stopAzan() {
    const audio = initAzanAudio();
    if (audio) {
      audio.pause();
      audio.currentTime = 0;
    }
    const modal = document.getElementById('azanActiveBanner');
    if (modal) modal.classList.add('hidden');
  }

  // Audio synthesis fallback chime if MP3 autoplay is restricted by browser policy
  function playSynthesizedChime() {
    try {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return;
      const ctx = window.__nurAudioCtx || new AudioContext();
      window.__nurAudioCtx = ctx;
      if (ctx.state === 'suspended') {
        ctx.resume().catch(() => {});
      }
      const notes = [440, 554.37, 659.25, 880];
      notes.forEach((freq, idx) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.value = freq;
        gain.gain.setValueAtTime(0.3, ctx.currentTime + idx * 0.4);
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + idx * 0.4 + 0.8);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(ctx.currentTime + idx * 0.4);
        osc.stop(ctx.currentTime + idx * 0.4 + 0.9);
      });
    } catch (e) {}
  }

  async function sendPrayerNotification(prayerName) {
    const urduNames = {
      fajr: 'فجر',
      dhuhr: 'ظہر',
      asr: 'عصر',
      maghrib: 'مغرب',
      isha: 'عشاء'
    };
    const pKey = prayerName.toLowerCase().replace(/[^a-z]/g, '');
    const urduName = urduNames[pKey] || prayerName;
    const title = `حی علی الصلاۃ — وقتِ ${urduName}`;
    const body = `Namaz ${prayerName} ka waqt ho gaya hai (${state.location.name}). Tap to open Nur Al-Quran.`;

    if (!('Notification' in window) || Notification.permission !== 'granted') {
      return;
    }

    // 1. Android Chrome / PWA: MUST use ServiceWorkerRegistration.showNotification()
    if ('serviceWorker' in navigator) {
      try {
        const reg = await navigator.serviceWorker.ready;
        if (reg && reg.showNotification) {
          return reg.showNotification(title, {
            body: body,
            icon: 'assets/icon-192.png',
            badge: 'assets/icon-192.png',
            vibrate: [200, 100, 200, 100, 200, 100, 400],
            tag: 'prayer-alarm-' + pKey,
            renotify: true,
            requireInteraction: true,
            data: { url: '/' }
          });
        }
      } catch (e) {
        console.warn('SW showNotification failed, trying desktop fallback:', e);
      }
    }

    // 2. Desktop Fallback
    try {
      new Notification(title, {
        body: body,
        icon: 'assets/icon-192.png',
        badge: 'assets/icon-192.png'
      });
    } catch (e) {
      console.warn('Notification constructor failed:', e);
    }
  }

  async function requestNotificationPermission() {
    if (!('Notification' in window)) return false;
    if (Notification.permission === 'granted') return true;
    try {
      const res = await Notification.requestPermission();
      return res === 'granted';
    } catch (e) {
      return new Promise(resolve => {
        try {
          Notification.requestPermission(p => resolve(p === 'granted'));
        } catch (err) {
          resolve(false);
        }
      });
    }
  }

  function showAzanModal(prayerName) {
    const banner = document.getElementById('azanActiveBanner');
    const label = document.getElementById('azanPrayerTitle');
    if (banner && label) {
      const urduMap = { fajr: 'فجر', dhuhr: 'ظہر', asr: 'عصر', maghrib: 'مغرب', isha: 'عشاء' };
      const pKey = prayerName.toLowerCase().replace(/[^a-z]/g, '');
      const urdu = urduMap[pKey] || prayerName;
      label.textContent = `اذانِ ${urdu} (${prayerName})`;
      banner.classList.remove('hidden');
    }
  }

  // ---------------------------------------------------------------------------
  // 5. BACKGROUND REAL-TIME PRAYER SCHEDULER
  // ---------------------------------------------------------------------------
  function checkPrayerAlarmTick() {
    const now = new Date();
    const curMinutes = now.getHours() * 60 + now.getMinutes();
    const todayDateStr = `${now.getFullYear()}-${now.getMonth() + 1}-${now.getDate()}`;

    const times = calculatePrayerTimes(now, state.location, state.asrJuristic);

    const prayerSchedule = [
      { key: 'fajr', time: times.fajr, name: 'Fajr' },
      { key: 'dhuhr', time: times.dhuhr, name: 'Dhuhr' },
      { key: 'asr', time: times.asr, name: 'Asr' },
      { key: 'maghrib', time: times.maghrib, name: 'Maghrib' },
      { key: 'isha', time: times.isha, name: 'Isha' }
    ];

    for (const p of prayerSchedule) {
      const pMinutes = p.time.hours24 * 60 + p.time.mins;
      const diff = curMinutes - pMinutes;

      // Trigger if prayer started between 0 and 10 minutes ago (grace period for background throttle)
      if (diff >= 0 && diff <= 10) {
        const storageKey = `nur-alarm-fired-${p.key}-${todayDateStr}`;
        if (!storage.getItem(storageKey)) {
          storage.setItem(storageKey, 'true');
          state.lastAlarmPlayedPrayer = `${p.key}_${todayDateStr}`;

          const isAlarmEnabled = state.alarmSettings[p.key] !== false;
          if (isAlarmEnabled && state.azanAudioEnabled !== false) {
            playAzan(p.name);
          }
        }
      }
    }
  }

  // Expose API globally
  window.NurPrayerEngine = {
    PRESET_CITIES,
    state,
    calculatePrayerTimes,
    calculateQiblah,
    playAzan,
    testAzan: function() {
      playAzan('Test Azan (تجرباتی اذان)');
    },
    stopAzan,
    sendPrayerNotification,
    unlockMobileAudio,
    requestNotificationPermission,
    checkPrayerAlarmTick,
    setLocation: function(loc) {
      state.location = loc;
      localStorage.setItem('nur-prayer-location', JSON.stringify(loc));
      window.dispatchEvent(new CustomEvent('nur-prayer-location-changed', { detail: loc }));
    },
    setAsrJuristic: function(mode) {
      state.asrJuristic = mode;
      localStorage.setItem('nur-asr-juristic', mode);
      window.dispatchEvent(new CustomEvent('nur-prayer-settings-changed'));
    },
    toggleAlarm: function(prayerKey, isEnabled) {
      if (typeof isEnabled === 'boolean') {
        state.alarmSettings[prayerKey] = isEnabled;
      } else {
        const current = state.alarmSettings[prayerKey] !== false;
        state.alarmSettings[prayerKey] = !current;
      }
      localStorage.setItem('nur-prayer-alarms', JSON.stringify(state.alarmSettings));
      return state.alarmSettings[prayerKey];
    }
  };

  // Start minute tick for alarms in browser + visibility change handlers
  if (typeof window !== 'undefined' && typeof document !== 'undefined') {
    setInterval(checkPrayerAlarmTick, 15000);

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        checkPrayerAlarmTick();
      }
    });
    window.addEventListener('focus', checkPrayerAlarmTick);
  }

})(window);
