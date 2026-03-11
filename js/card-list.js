/**
 * card-list.js
 * Renders card grid with filtering, searching, sorting, pagination.
 * Awakening filter uses multi-select icon checkboxes.
 */
const CardList = (() => {
    const PAGE_SIZE = 60;
    let allCards = [];
    let filteredCards = [];
    let currentPage = 0;
    let currentFilter = { attrMain: 'all', attrSub: 'all', attrThird: 'all', type: 'all', rarity: 'all', sort: 'id-desc' };
    let selectedAwakenings = []; // multi-select awakening IDs (can contain duplicates)
    let searchQuery = '';
    let skillSearchQuery = '';

    // All awakenings grouped by category for the grid
    const AWAKEN_ICON_LIST = [
        // 스탯 (Stats)
        1, 2, 3, 82, 127,
        // 데미지 감소 (Damage Reduction)
        4, 5, 6, 7, 8, 128, 129, 130, 131, 132,
        // 내성 (Resists)
        10, 52, 11, 68, 12, 69, 13, 70, 28, 54, 55, 136,
        // 유틸 (Utility - SB, TE, Autoheal, Bind Clear, Skill Charge, Assist)
        21, 56, 19, 53, 9, 98, 20, 115, 51, 97, 49, 133, 134, 135,
        // 드롭 강화 (Drop Enhance)
        14, 99, 15, 100, 16, 101, 17, 102, 18, 103, 29, 104,
        // 열 강화 (Row Enhance)
        22, 116, 23, 117, 24, 118, 25, 119, 26, 120,
        // 드롭 꿰기 (Bead)
        73, 121, 74, 122, 75, 123, 76, 124, 77, 125,
        // 공격 각성 (Damage Awakens)
        27, 96, 43, 107, 61, 111, 79, 112, 80, 113, 81, 114,
        60, 108, 78, 110, 48, 109, 46, 57, 47, 58, 65, 67, 66, 72,
        // 추가 공격, 가드 브레이크 등 (FUA, Guard Break, Combo Drop)
        45, 50, 83, 62, 44,
        // 흡수 관통 (Absorption Pierce)
        91, 92, 93, 94, 95,
        // 킬러 (Killers)
        31, 85, 32, 88, 33, 86, 34, 87, 35, 84, 36, 89, 37, 90,
        38, 139, 39, 40, 41, 42, 105, 141, 142,
        // 기타 (Misc)
        71, 59, 63, 64, 30, 140, 137, 138, 106, 126
    ];

    const GITHUB_BASE = 'https://mapaler.github.io/PADDashFormation';

    function init(cards) {
        allCards = cards;
        buildAwakenPanel();
        applyFiltersAndRender();
        setupFilterListeners();
        setupSearchListener();
        setupAdvancedSearchListeners();
    }

    function buildAwakenPanel() {
        const body = document.getElementById('awaken-panel-body');
        if (!body) return;

        body.innerHTML = AWAKEN_ICON_LIST.map(id => {
            const name = DataParser.getAwakenName(id);
            return `<div class="awaken-checkbox" data-awaken-id="${id}" title="${name} 추가">
                <div class="awaken-sprite" style="
                    background-image:url('awakenings/${id}.png');
                "></div>
            </div>`;
        }).join('');

        // Toggle panel
        const toggleBtn = document.getElementById('awaken-toggle-btn');
        const panel = document.getElementById('awaken-panel');
        const closeBtn = document.getElementById('awaken-panel-close');
        const clearBtn = document.getElementById('awaken-clear-btn');
        const searchBtn = document.getElementById('awaken-search-btn');

        toggleBtn.addEventListener('click', () => {
            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
        });

        closeBtn.addEventListener('click', () => {
            panel.style.display = 'none';
        });

        searchBtn.addEventListener('click', () => {
            panel.style.display = 'none';
            currentPage = 0;
            applyFiltersAndRender();
        });

        clearBtn.addEventListener('click', () => {
            selectedAwakenings = [];
            renderAwakenTray();
            currentPage = 0;
            applyFiltersAndRender();
        });

        // Click on icon to add to tray
        body.addEventListener('click', (e) => {
            const checkbox = e.target.closest('.awaken-checkbox');
            if (!checkbox) return;
            const id = parseInt(checkbox.dataset.awakenId);

            selectedAwakenings.push(id);
            renderAwakenTray();
        });

        // Click on tray item to remove
        const trayList = document.getElementById('awaken-selected-list');
        trayList.addEventListener('click', (e) => {
            const item = e.target.closest('.awaken-selected-item');
            if (!item) return;
            const index = parseInt(item.dataset.index);
            selectedAwakenings.splice(index, 1);
            renderAwakenTray();
        });
    }

    function renderAwakenTray() {
        const trayList = document.getElementById('awaken-selected-list');
        const placeholder = document.getElementById('awaken-selected-placeholder');

        if (selectedAwakenings.length === 0) {
            trayList.innerHTML = '';
            placeholder.style.display = 'block';
        } else {
            placeholder.style.display = 'none';
            trayList.innerHTML = selectedAwakenings.map((id, index) => {
                const name = DataParser.getAwakenName(id);
                return `<div class="awaken-selected-item" data-index="${index}" title="${name} (클릭하여 제거)" style="background-image:url('awakenings/${id}.png');"></div>`;
            }).join('');
        }
        updateAwakenUI();
    }

    function updateAwakenUI() {
        const badge = document.getElementById('awaken-count-badge');
        const toggleBtn = document.getElementById('awaken-toggle-btn');
        const clearBtn = document.getElementById('awaken-clear-btn');
        const count = selectedAwakenings.length;

        badge.textContent = count > 0 ? count : '';
        toggleBtn.classList.toggle('has-selection', count > 0);
        clearBtn.style.display = count > 0 ? 'inline-flex' : 'none';
    }

    function setupFilterListeners() {
        const filterSection = document.getElementById('filter-section');
        filterSection.addEventListener('click', (e) => {
            const btn = e.target.closest('.filter-btn');
            if (!btn) return;
            // Skip awakening buttons
            if (btn.id === 'awaken-toggle-btn' || btn.id === 'awaken-clear-btn') return;

            const attrMain = btn.dataset.attrMain;
            const attrSub = btn.dataset.attrSub;
            const attrThird = btn.dataset.attrThird;
            const rarity = btn.dataset.rarity;
            const sort = btn.dataset.sort;
            const type = btn.dataset.type;

            if (attrMain !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-attr-main]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.attrMain = attrMain;
            } else if (attrSub !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-attr-sub]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.attrSub = attrSub;
            } else if (attrThird !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-attr-third]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.attrThird = attrThird;
            } else if (type !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-type]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.type = type;
            } else if (rarity !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-rarity]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.rarity = rarity;
            } else if (sort !== undefined) {
                filterSection.querySelectorAll('.filter-btn[data-sort]').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                currentFilter.sort = sort;
            }

            currentPage = 0;
            applyFiltersAndRender();
        });
    }

    function setupSearchListener() {
        const searchInput = document.getElementById('search-input');
        let timeout;
        searchInput.addEventListener('input', (e) => {
            clearTimeout(timeout);
            timeout = setTimeout(() => {
                searchQuery = e.target.value.trim().toLowerCase();
                currentPage = 0;
                applyFiltersAndRender();
            }, 200);
        });
    }

    function setupAdvancedSearchListeners() {
        // Skill search
        const skillInput = document.getElementById('skill-search');
        if (skillInput) {
            let timeout;
            skillInput.addEventListener('input', (e) => {
                clearTimeout(timeout);
                timeout = setTimeout(() => {
                    skillSearchQuery = e.target.value.trim().toLowerCase();
                    currentPage = 0;
                    applyFiltersAndRender();
                }, 300);
            });
        }
    }

    function applyFiltersAndRender() {
        // Filter
        filteredCards = allCards.filter(card => {
            if (!card.name || card.name === '' || card.name.startsWith('カード')) return false;
            if (/^[\*\?#\s]+$/.test(card.name)) return false;

            // Main Attr filter
            if (currentFilter.attrMain !== 'all') {
                const attrId = parseInt(currentFilter.attrMain);
                if (card.attrs[0] !== attrId) return false;
            }

            // Sub Attr filter
            if (currentFilter.attrSub !== 'all') {
                const attrId = parseInt(currentFilter.attrSub);
                if (card.attrs[1] !== attrId) return false;
            }

            // Third Attr filter
            if (currentFilter.attrThird !== 'all') {
                const attrId = parseInt(currentFilter.attrThird);
                if (card.attrs[2] !== attrId) return false;
            }

            // Type filter
            if (currentFilter.type !== 'all') {
                const typeId = parseInt(currentFilter.type);
                if (!card.types || !card.types.includes(typeId)) return false;
            }

            // Rarity filter
            if (currentFilter.rarity !== 'all') {
                const minRarity = parseInt(currentFilter.rarity);
                if (card.rarity < minRarity) return false;
            }

            // Multi-select awakening filter (with duplicates and '+' equivalence support)
            if (selectedAwakenings.length > 0) {
                const AWAKEN_EQUIV = {
                    52: { base: 10, weight: 2 }, 56: { base: 21, weight: 2 }, 53: { base: 19, weight: 2 },
                    96: { base: 27, weight: 2 }, 107: { base: 43, weight: 2 }, 111: { base: 61, weight: 2 },
                    109: { base: 48, weight: 2 }, 110: { base: 78, weight: 2 }, 112: { base: 79, weight: 2 },
                    113: { base: 80, weight: 2 }, 114: { base: 81, weight: 2 }, 115: { base: 20, weight: 2 },
                    // Row enhances are worth 3
                    116: { base: 22, weight: 3 }, 117: { base: 23, weight: 3 }, 118: { base: 24, weight: 3 },
                    119: { base: 25, weight: 3 }, 120: { base: 26, weight: 3 },
                    // Beads
                    121: { base: 73, weight: 2 }, 122: { base: 74, weight: 2 }, 123: { base: 75, weight: 2 },
                    124: { base: 76, weight: 2 }, 125: { base: 77, weight: 2 },
                    98: { base: 9, weight: 2 }, 99: { base: 14, weight: 2 },
                    100: { base: 15, weight: 2 }, 101: { base: 16, weight: 2 }, 102: { base: 17, weight: 2 },
                    103: { base: 18, weight: 2 }, 104: { base: 29, weight: 2 }, 97: { base: 51, weight: 2 },
                    // Full resists are 5
                    68: { base: 11, weight: 5 }, 69: { base: 12, weight: 5 }, 70: { base: 13, weight: 5 }
                };

                const reqCounts = {};
                for (const id of selectedAwakenings) {
                    const equiv = AWAKEN_EQUIV[id];
                    const baseId = equiv ? equiv.base : id;
                    const weight = equiv ? equiv.weight : 1;
                    reqCounts[baseId] = (reqCounts[baseId] || 0) + weight;
                }

                const cardAwakenings = [
                    ...(card.awakenings || []),
                    ...(card.superAwakenings || [])
                ];

                const cardCounts = {};
                for (const id of cardAwakenings) {
                    const equiv = AWAKEN_EQUIV[id];
                    const baseId = equiv ? equiv.base : id;
                    const weight = equiv ? equiv.weight : 1;
                    cardCounts[baseId] = (cardCounts[baseId] || 0) + weight;
                }

                let hasAll = true;
                for (const [baseId, reqCount] of Object.entries(reqCounts)) {
                    if ((cardCounts[baseId] || 0) < reqCount) {
                        hasAll = false;
                        break;
                    }
                }
                if (!hasAll) return false;
            }

            // Name/ID search
            if (searchQuery) {
                const matchesName = card.name.toLowerCase().includes(searchQuery);
                const matchesId = String(card.id).includes(searchQuery);
                if (!matchesName && !matchesId) return false;
            }

            // Skill search
            if (skillSearchQuery) {
                const activeSkill = DataParser.getSkill(card.activeSkillId);
                const leaderSkill = DataParser.getSkill(card.leaderSkillId);
                const matchesActive = activeSkill && (
                    (activeSkill.name && activeSkill.name.toLowerCase().includes(skillSearchQuery)) ||
                    (activeSkill.description && activeSkill.description.toLowerCase().includes(skillSearchQuery))
                );
                const matchesLeader = leaderSkill && (
                    (leaderSkill.name && leaderSkill.name.toLowerCase().includes(skillSearchQuery)) ||
                    (leaderSkill.description && leaderSkill.description.toLowerCase().includes(skillSearchQuery))
                );
                if (!matchesActive && !matchesLeader) return false;
            }

            return true;
        });

        // Sort
        switch (currentFilter.sort) {
            case 'id-desc':
                filteredCards.sort((a, b) => b.id - a.id);
                break;
            case 'id-asc':
                filteredCards.sort((a, b) => a.id - b.id);
                break;
            case 'rarity':
                filteredCards.sort((a, b) => b.rarity - a.rarity || b.id - a.id);
                break;
            case 'hp':
                filteredCards.sort((a, b) => (b.hp?.max || 0) - (a.hp?.max || 0) || b.id - a.id);
                break;
            case 'atk':
                filteredCards.sort((a, b) => (b.atk?.max || 0) - (a.atk?.max || 0) || b.id - a.id);
                break;
            case 'rcv':
                filteredCards.sort((a, b) => (b.rcv?.max || 0) - (a.rcv?.max || 0) || b.id - a.id);
                break;
        }

        renderCards();
        updateStats();
    }

    function renderCards() {
        const grid = document.getElementById('card-grid');
        const loadMoreContainer = document.getElementById('load-more-container');
        const emptyState = document.getElementById('empty-state');

        if (currentPage === 0) {
            grid.innerHTML = '';
        }

        const start = currentPage * PAGE_SIZE;
        const end = start + PAGE_SIZE;
        const pageCards = filteredCards.slice(start, end);

        if (filteredCards.length === 0) {
            emptyState.style.display = 'block';
            loadMoreContainer.style.display = 'none';
            return;
        } else {
            emptyState.style.display = 'none';
        }

        const fragment = document.createDocumentFragment();
        pageCards.forEach((card, i) => {
            const el = createCardElement(card, start + i);
            fragment.appendChild(el);
        });
        grid.appendChild(fragment);

        if (end < filteredCards.length) {
            loadMoreContainer.style.display = 'block';
            const loadMoreBtn = document.getElementById('load-more-btn');
            loadMoreBtn.textContent = `더 보기 (${filteredCards.length - end}개 남음)`;
            loadMoreBtn.onclick = () => {
                currentPage++;
                renderCards();
                updateStats();
            };
        } else {
            loadMoreContainer.style.display = 'none';
        }
    }

    function createCardElement(card, index) {
        const div = document.createElement('div');
        div.className = 'card-item';
        div.setAttribute('data-attr', card.attrs[0] >= 0 ? card.attrs[0] : '');
        div.style.animationDelay = `${(index % PAGE_SIZE) * 0.02}s`;

        const sprite = DataLoader.getCardSpriteInfo(card.id);
        const mainAttr = card.attrs[0] >= 0 ? DataParser.getAttrClass(card.attrs[0]) : '';
        const subAttr = card.attrs[1] >= 0 ? DataParser.getAttrClass(card.attrs[1]) : '';
        const thirdAttr = card.attrs[2] >= 0 ? DataParser.getAttrClass(card.attrs[2]) : '';

        div.innerHTML = `
      <div class="card-img-wrapper">
        <div class="card-sprite" 
             data-sheet="${sprite.sheetIdx}"
             data-card-id="${card.id}"
             style="width:100px;height:100px;"></div>
      </div>
      <div class="card-info">
        <div class="card-id">No.${card.id}</div>
        <div class="card-name" title="${card.name}">${card.name}</div>
        <div class="card-attr-badges">
          ${mainAttr ? `<span class="attr-dot ${mainAttr}"></span>` : ''}
          ${subAttr ? `<span class="attr-dot ${subAttr}"></span>` : ''}
          ${thirdAttr ? `<span class="attr-dot ${thirdAttr}"></span>` : ''}
        </div>
        <div class="rarity-stars">${DataParser.getRarityStars(card.rarity)}</div>
      </div>
    `;

        // Lazy load sprite sheet
        const spriteDiv = div.querySelector('.card-sprite');
        const wrapper = div.querySelector('.card-img-wrapper');

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    spriteDiv.style.backgroundImage = `url('${sprite.url}')`;
                    spriteDiv.style.backgroundPosition = `${sprite.bgPosX}px ${sprite.bgPosY}px`;
                    spriteDiv.style.backgroundSize = `${10 * DataLoader.ICON_SIZE}px ${10 * DataLoader.ICON_SIZE}px`;
                    spriteDiv.style.backgroundRepeat = 'no-repeat';
                    wrapper.classList.remove('loading');
                    observer.unobserve(entry.target);
                }
            });
        }, { rootMargin: '400px' });

        observer.observe(wrapper);

        div.addEventListener('click', () => {
            CardDetail.show(card);
        });

        return div;
    }

    function updateStats() {
        const totalEl = document.getElementById('total-count');
        const shownEl = document.getElementById('shown-count');
        const shownCount = Math.min((currentPage + 1) * PAGE_SIZE, filteredCards.length);
        totalEl.textContent = `전체: ${allCards.length.toLocaleString()}`;
        shownEl.textContent = `표시: ${shownCount.toLocaleString()} / ${filteredCards.length.toLocaleString()}`;
    }

    return { init };
})();
