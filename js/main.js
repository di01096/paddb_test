/**
 * main.js
 * App initialization and global event handlers.
 */
(async function () {
    'use strict';

    const loadingScreen = document.getElementById('loading-screen');
    const progressFill = document.getElementById('progress-fill');
    const loadingStatus = document.getElementById('loading-status');
    const scrollTopBtn = document.getElementById('scroll-top-btn');
    const logoLink = document.getElementById('logo-link');

    // Progress callback
    function onProgress(percent, statusText) {
        progressFill.style.width = `${percent}%`;
        if (statusText) loadingStatus.textContent = statusText;
    }

    // Initialize
    try {
        // Init card detail modal handlers
        CardDetail.init();

        // Load data from GitHub
        onProgress(5, '데이터를 불러오는 중...');
        const { monsters, skills } = await DataLoader.loadData(onProgress);

        onProgress(90, '데이터 처리 중...');
        const { cards } = DataParser.parseData(monsters, skills);

        onProgress(95, '화면 구성 중...');

        // Filter out cards with invalid data (id = 0, no name, etc.)
        const validCards = cards.filter(c => c.id > 0 && c.name && c.name.trim() !== '');

        console.log(`Loaded ${validCards.length} cards`);

        // Initialize card list
        CardList.init(validCards);

        onProgress(100, '완료!');

        // Hide loading screen
        setTimeout(() => {
            loadingScreen.classList.add('fade-out');
            setTimeout(() => {
                loadingScreen.style.display = 'none';
            }, 400);
        }, 300);

    } catch (error) {
        console.error('Failed to load data:', error);
        loadingStatus.textContent = `오류 발생: ${error.message}. 페이지를 새로고침 해주세요.`;
        loadingStatus.style.color = '#e74c3c';
        progressFill.style.background = '#e74c3c';
    }

    // Scroll to top button
    window.addEventListener('scroll', () => {
        if (window.scrollY > 300) {
            scrollTopBtn.classList.add('visible');
        } else {
            scrollTopBtn.classList.remove('visible');
        }
    });

    scrollTopBtn.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // Logo click - reset filters and scroll to top
    logoLink.addEventListener('click', (e) => {
        e.preventDefault();
        document.getElementById('search-input').value = '';
        window.scrollTo({ top: 0, behavior: 'smooth' });
        // Trigger reset of filters
        document.querySelectorAll('.filter-btn[data-attr="all"], .filter-btn[data-rarity="all"], .filter-btn[data-sort="id-desc"]').forEach(btn => btn.click());
    });
})();
