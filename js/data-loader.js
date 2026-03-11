/**
 * data-loader.js
 * Fetches monster & skill data from GitHub, caches in IndexedDB.
 */
const DataLoader = (() => {
  const GITHUB_RAW = 'https://raw.githubusercontent.com/Mapaler/PADDashFormation/master';
  const GITHUB_PAGES = 'https://mapaler.github.io/PADDashFormation';
  const DB_NAME = 'PADCardGuide';
  const DB_VERSION = 1;
  const STORE_NAME = 'data';
  const CACHE_HOURS = 24;

  let db = null;

  function openDB() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = (e) => {
        const database = e.target.result;
        if (!database.objectStoreNames.contains(STORE_NAME)) {
          database.createObjectStore(STORE_NAME, { keyPath: 'key' });
        }
      };
      request.onsuccess = (e) => {
        db = e.target.result;
        resolve(db);
      };
      request.onerror = (e) => reject(e.target.error);
    });
  }

  function getFromCache(key) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readonly');
      const store = tx.objectStore(STORE_NAME);
      const request = store.get(key);
      request.onsuccess = () => resolve(request.result || null);
      request.onerror = () => resolve(null);
    });
  }

  function saveToCache(key, data, ckey) {
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORE_NAME, 'readwrite');
      const store = tx.objectStore(STORE_NAME);
      store.put({ key, data, ckey, timestamp: Date.now() });
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
  }

  function isCacheValid(cached, remoteCkey) {
    if (!cached) return false;
    const age = Date.now() - cached.timestamp;
    if (age > CACHE_HOURS * 60 * 60 * 1000) return false;
    if (remoteCkey && cached.ckey !== remoteCkey) return false;
    return true;
  }

  async function fetchJSON(url, onProgress) {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`HTTP ${response.status} for ${url}`);

    // Try streaming for progress tracking
    const contentLength = response.headers.get('content-length');
    if (contentLength && response.body) {
      try {
        const total = parseInt(contentLength, 10);
        const reader = response.body.getReader();
        const chunks = [];
        let received = 0;

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          chunks.push(value);
          received += value.length;
          if (onProgress) onProgress(Math.round((received / total) * 100));
        }

        const allChunks = new Uint8Array(received);
        let position = 0;
        for (const chunk of chunks) {
          allChunks.set(chunk, position);
          position += chunk.length;
        }

        const text = new TextDecoder().decode(allChunks);
        return JSON.parse(text);
      } catch (e) {
        // Fallback if streaming fails
        console.warn('Streaming failed, retrying without stream:', e);
      }
    }

    // Non-streaming fallback
    const text = await response.text();
    if (onProgress) onProgress(100);
    return JSON.parse(text);
  }

  async function fetchCkeys() {
    try {
      const ckeys = await fetchJSON(`${GITHUB_RAW}/monsters-info/ckey.json`);
      const koData = ckeys.find(c => c.code === 'ko') || {};
      return koData.ckey || {};
    } catch (e) {
      console.warn('Failed to fetch ckeys:', e);
      return {};
    }
  }

  async function loadData(onProgress) {
    await openDB();

    const statusUpdate = (msg) => {
      if (onProgress) onProgress(0, msg);
    };

    statusUpdate('버전 정보 확인 중...');
    const remoteCkeys = await fetchCkeys();

    // Check cache for monsters
    statusUpdate('캐시 확인 중...');
    const cachedMonsters = await getFromCache('monsters_ko');
    const cachedSkills = await getFromCache('skills_ko');

    let monsters, skills;

    if (isCacheValid(cachedMonsters, remoteCkeys.card)) {
      statusUpdate('캐시에서 몬스터 데이터 로드 중...');
      monsters = cachedMonsters.data;
      if (onProgress) onProgress(40, '캐시에서 몬스터 데이터 로드 완료');
    } else {
      statusUpdate('GitHub에서 몬스터 데이터 다운로드 중...');
      monsters = await fetchJSON(
        `${GITHUB_RAW}/monsters-info/mon_ko.json`,
        (p) => { if (onProgress) onProgress(Math.round(p * 0.4), `몬스터 데이터 다운로드 중... ${p}%`); }
      );
      await saveToCache('monsters_ko', monsters, remoteCkeys.card);
    }

    if (isCacheValid(cachedSkills, remoteCkeys.skill)) {
      statusUpdate('캐시에서 스킬 데이터 로드 중...');
      skills = cachedSkills.data;
      if (onProgress) onProgress(80, '캐시에서 스킬 데이터 로드 완료');
    } else {
      statusUpdate('GitHub에서 스킬 데이터 다운로드 중...');
      skills = await fetchJSON(
        `${GITHUB_RAW}/monsters-info/skill_ko.json`,
        (p) => { if (onProgress) onProgress(40 + Math.round(p * 0.4), `스킬 데이터 다운로드 중... ${p}%`); }
      );
      await saveToCache('skills_ko', skills, remoteCkeys.skill);
    }

    if (onProgress) onProgress(90, '데이터 처리 중...');
    return { monsters, skills };
  }

  // Sprite sheet: each CARDS_XXX.PNG contains a 10x10 grid of card icons
  // Card icon size: 100x100 px, spacing: 2px between icons
  const ICON_SIZE = 102; // 100px icon + 2px gap
  const CARDS_PER_SHEET = 100; // 10x10 grid

  function getCardSpriteInfo(cardId, lang) {
    lang = lang || 'ko';
    const sheetIdx = Math.floor((cardId - 1) / CARDS_PER_SHEET) + 1;
    const posInSheet = (cardId - 1) % CARDS_PER_SHEET;
    const x = posInSheet % 10;
    const y = Math.floor(posInSheet / 10);
    const paddedSheet = String(sheetIdx).padStart(3, '0');
    const imgUrl = `${GITHUB_PAGES}/images/cards_${lang}/CARDS_${paddedSheet}.PNG`;

    return {
      url: imgUrl,
      x: x,
      y: y,
      bgPosX: -(x * ICON_SIZE),
      bgPosY: -(y * ICON_SIZE),
      sheetIdx: sheetIdx
    };
  }

  return { loadData, getCardSpriteInfo, ICON_SIZE, GITHUB_PAGES };
})();
