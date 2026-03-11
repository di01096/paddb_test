/**
 * card-detail.js
 * Shows card detail modal with stats, skills, awakenings.
 */
const CardDetail = (() => {
  const GITHUB_BASE = 'https://mapaler.github.io/PADDashFormation';

  function show(card) {
    const overlay = document.getElementById('modal-overlay');
    const modalImage = document.getElementById('modal-image');
    const modalId = document.getElementById('modal-card-id');
    const modalName = document.getElementById('modal-card-name');
    const modalAttrs = document.getElementById('modal-card-attrs');
    const modalRarity = document.getElementById('modal-rarity');
    const modalTypes = document.getElementById('modal-types');
    const modalBody = document.getElementById('modal-body');

    // Image using sprite sheet
    const sprite = DataLoader.getCardSpriteInfo(card.id);
    modalImage.innerHTML = `<div class="detail-sprite" style="
      width:100px;height:100px;
      background-image:url('${sprite.url}');
      background-position:${sprite.bgPosX}px ${sprite.bgPosY}px;
      background-size:${10 * DataLoader.ICON_SIZE}px ${10 * DataLoader.ICON_SIZE}px;
      background-repeat:no-repeat;
      border-radius:8px;
    "></div>`;

    // Basic info
    modalId.textContent = `No.${card.id}`;
    modalName.textContent = card.name;
    modalRarity.textContent = DataParser.getRarityStars(card.rarity) + ` (${card.rarity}★)`;

    // Attrs
    modalAttrs.innerHTML = '';
    if (card.attrs[0] >= 0) {
      const cls = DataParser.getAttrClass(card.attrs[0]);
      modalAttrs.innerHTML += `<span class="attr-badge ${cls}">${DataParser.getAttrName(card.attrs[0])} (주속성)</span>`;
    }
    if (card.attrs[1] >= 0) {
      const cls = DataParser.getAttrClass(card.attrs[1]);
      modalAttrs.innerHTML += `<span class="attr-badge ${cls}">${DataParser.getAttrName(card.attrs[1])} (부속성)</span>`;
    }
    if (card.attrs.length > 2 && card.attrs[2] >= 0) {
      const cls = DataParser.getAttrClass(card.attrs[2]);
      modalAttrs.innerHTML += `<span class="attr-badge ${cls}">${DataParser.getAttrName(card.attrs[2])} (제3속성)</span>`;
    }

    // Types
    modalTypes.innerHTML = '';
    if (card.types && card.types.length > 0) {
      card.types.forEach(t => {
        if (t >= 0) {
          modalTypes.innerHTML += `<span class="type-badge">${DataParser.getTypeName(t)}</span>`;
        }
      });
    }

    // Body content
    let bodyHTML = '';

    // Stats section
    const hpMax = card.hp && card.hp.max ? card.hp.max : 0;
    const atkMax = card.atk && card.atk.max ? card.atk.max : 0;
    const rcvMax = card.rcv && card.rcv.max ? card.rcv.max : 0;

    bodyHTML += `
      <div class="detail-section">
        <div class="detail-section-title">📊 스탯 (최대 Lv)</div>
        <div class="stats-grid">
          <div class="stat-card hp">
            <div class="stat-label">HP</div>
            <div class="stat-value">${hpMax.toLocaleString()}</div>
          </div>
          <div class="stat-card atk">
            <div class="stat-label">공격</div>
            <div class="stat-value">${atkMax.toLocaleString()}</div>
          </div>
          <div class="stat-card rcv">
            <div class="stat-label">회복</div>
            <div class="stat-value">${rcvMax.toLocaleString()}</div>
          </div>
        </div>
      </div>
    `;

    // Limit break info
    if (card.limitBreakIncr > 0) {
      const lb = card.limitBreakIncr / 100;
      const hp120 = Math.round(hpMax * (1 + lb) * 1.1);
      const atk120 = Math.round(atkMax * (1 + lb) * 1.05);
      const rcv120 = Math.round(rcvMax * (1 + lb) * 1.05);
      bodyHTML += `
        <div class="detail-section">
          <div class="detail-section-title">🔓 한계돌파 (Lv110, +${card.limitBreakIncr}%)</div>
          <div class="stats-grid">
            <div class="stat-card hp">
              <div class="stat-label">HP</div>
              <div class="stat-value">${hp120.toLocaleString()}</div>
            </div>
            <div class="stat-card atk">
              <div class="stat-label">공격</div>
              <div class="stat-value">${atk120.toLocaleString()}</div>
            </div>
            <div class="stat-card rcv">
              <div class="stat-label">회복</div>
              <div class="stat-value">${rcv120.toLocaleString()}</div>
            </div>
          </div>
        </div>
      `;
    }

    // Active Skill
    const activeSkill = DataParser.getSkill(card.activeSkillId);
    if (activeSkill && activeSkill.name) {
      const minCD = activeSkill.initialCooldown - (activeSkill.maxLevel > 0 ? activeSkill.maxLevel - 1 : 0);
      bodyHTML += `
        <div class="detail-section">
          <div class="detail-section-title">⚡ 액티브 스킬</div>
          <div class="skill-box">
            <div class="skill-name">${activeSkill.name}</div>
            <div class="skill-desc">${activeSkill.description || '설명 없음'}</div>
            <div class="skill-turns">턴: ${minCD} ~ ${activeSkill.initialCooldown} (Lv.${activeSkill.maxLevel || 1})</div>
          </div>
        </div>
      `;
    }

    // Leader Skill
    const leaderSkill = DataParser.getSkill(card.leaderSkillId);
    if (leaderSkill && leaderSkill.name) {
      bodyHTML += `
        <div class="detail-section">
          <div class="detail-section-title">👑 리더 스킬</div>
          <div class="skill-box">
            <div class="skill-name">${leaderSkill.name}</div>
            <div class="skill-desc">${leaderSkill.description || '설명 없음'}</div>
          </div>
        </div>
      `;
    }

    // Awakenings - use individual images
    if (card.awakenings && card.awakenings.length > 0) {
      bodyHTML += `
        <div class="detail-section">
          <div class="detail-section-title">🌟 각성 스킬</div>
          <div class="awaken-list">
            ${card.awakenings.map(a => {
        const awakenName = DataParser.getAwakenName(a);
        return `<div class="awaken-item" title="${awakenName}">
                <div class="awaken-icon-sprite" style="
                  width:36px;height:36px;
                  background-image:url('awakenings/${a}.png');
                  background-size:contain;
                  background-position:center;
                  background-repeat:no-repeat;
                "></div>
                <span class="awaken-name">${awakenName}</span>
              </div>`;
      }).join('')}
          </div>
        </div>
      `;
    }

    // Super Awakenings
    if (card.superAwakenings && card.superAwakenings.length > 0) {
      bodyHTML += `
        <div class="detail-section">
          <div class="detail-section-title">💎 초각성</div>
          <div class="awaken-list super">
            ${card.superAwakenings.map(a => {
        const awakenName = DataParser.getAwakenName(a);
        return `<div class="awaken-item" title="${awakenName}">
                <div class="awaken-icon-sprite" style="
                  width:36px;height:36px;
                  background-image:url('awakenings/${a}.png');
                  background-size:contain;
                  background-position:center;
                  background-repeat:no-repeat;
                "></div>
                <span class="awaken-name">${awakenName}</span>
              </div>`;
      }).join('')}
          </div>
        </div>
      `;
    }

    // Additional info
    bodyHTML += `
      <div class="detail-section">
        <div class="detail-section-title">ℹ️ 기본 정보</div>
        <div class="skill-box">
          <div class="skill-desc">
            코스트: ${card.cost} | MP: ${(card.sellMP || 0).toLocaleString()} | 최대 Lv: ${card.maxLevel || '?'}
            ${card.limitBreakIncr > 0 ? ` | 한계돌파: +${card.limitBreakIncr}%` : ''}
          </div>
        </div>
      </div>
    `;

    modalBody.innerHTML = bodyHTML;

    // Show modal
    overlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  function hide() {
    const overlay = document.getElementById('modal-overlay');
    overlay.classList.remove('active');
    document.body.style.overflow = '';
  }

  function init() {
    // Close on overlay click
    document.getElementById('modal-overlay').addEventListener('click', (e) => {
      if (e.target.id === 'modal-overlay') hide();
    });

    // Close button
    document.getElementById('modal-close').addEventListener('click', hide);

    // ESC key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') hide();
    });
  }

  return { show, hide, init };
})();
