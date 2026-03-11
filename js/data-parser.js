/**
 * data-parser.js
 * Parses and normalizes monster/skill data from PADDashFormation JSON.
 */
const DataParser = (() => {
    // Attribute names
    const ATTR_NAMES = ['화', '수', '목', '광', '암'];
    const ATTR_NAMES_EN = ['Fire', 'Water', 'Wood', 'Light', 'Dark'];
    const ATTR_CLASSES = ['fire', 'water', 'wood', 'light', 'dark'];

    // Type names (Korean)
    const TYPE_NAMES = {
        0: '진화용',
        1: '밸런스',
        2: '체력',
        3: '회복',
        4: '드래곤',
        5: '신',
        6: '공격',
        7: '악마',
        8: '머신',
        9: '부구호',
        12: '각성용',
        14: '강화합성용',
        15: '매각용'
    };

    // Awakening names (Korean) - complete list up to ID 142
    const AWAKEN_NAMES = {
        1: 'HP 강화 (체뻥)',
        2: '공격 강화 (공뻥)',
        3: '회복 강화 (회뻥)',
        4: '불 대미지 경감 (화경감,불경감)',
        5: '물 대미지 경감 (수경감,물경감)',
        6: '풀 대미지 경감 (목경감,풀경감)',
        7: '빛 대미지 경감 (빛경감)',
        8: '어둠 대미지 경감(암경감)',
        9: '자동회복 (자회)',
        10: '바인드 내성 (바면)',
        11: '암흑 내성 (암막)',
        12: '방해 내성 (방막)',
        13: '독 내성 (독막)',
        14: '불드롭 강화 (old_불드강, old_화드강)',
        15: '물드롭 강화 (old_물드강, old_수드강)',
        16: '나무드롭 강화 (old_풀드강, old_목드강)',
        17: '빛드롭 강화 (old_빛드강)',
        18: '어둠드롭 강화 (old_암드강)',
        19: '조작 시간 연장 (old_손가락, old_조작)',
        20: '바인드 회복 (바회)',
        21: '스킬 부스트 (스부)',
        22: '불 가로 1렬 강화 (불횡, 불횡강)',
        23: '물 가로 1렬 강화 (물횡, 물횡강)',
        24: '나무 가로 1렬 강화 (목횡, 풀횡, 목횡강,풀횡강)',
        25: '빛 가로 1렬 강화 (빛횡, 빛횡강)',
        26: '어둠 가로 1렬 강화 (암횡, 암횡강)',
        27: '2마리 공격 (웨이, 투웨이)',
        28: '봉인 내성 (스봉)',
        29: '회복드롭 강화 (회드강)',
        30: '멀티 부스트 (멀부)',
        31: '드래곤 킬러 (드킬)',
        32: '신 킬러 (신킬)',
        33: '악마 킬러 (악킬)',
        34: '머신 킬러 (머킬)',
        35: '밸런스 킬러 (밸킬)',
        36: '공격 킬러 (공킬)',
        37: '체력 킬러 (체킬)',
        38: '회복 킬러 (회킬)',
        39: '진화용 킬러',
        40: '능력 각성용 킬러',
        41: '강화 합성용 킬러',
        42: '판매용 킬러',
        43: '콤보 강화 (7콤각)',
        44: '가드 브레이크 (가브)',
        45: '추가 공격 (종강, 추가타)',
        46: '팀 HP 강화 (팀체각)',
        47: '팀 회복 강화 (팀회각)',
        48: '대미지 무효 관통 (무무각)',
        49: '각성 어시스트 (어시각)',
        50: '초 추가 공격 (쫑강, 초추가타)',
        51: '스킬 차지 (스차)',
        52: '바인드 내성+ (바면쁠)',
        53: '조작 시간 연장+ (조작쁠)',
        54: '구름 내성 (구름막)',
        55: '조작 불가 내성 (띠막)',
        56: '스킬 부스트+ (스부쁠)',
        57: 'HP 50% 이상 강화 (반피이상)',
        58: 'HP 50% 이하 강화 (반피이하)',
        59: '회복 L자 지움 (회엘각, 회L각)',
        60: 'L자 지움 공격 (엘각, L각)',
        61: '초 콤보 강화 (10콤각)',
        62: '콤보드롭 생성 (콤드, 완두콩)',
        63: '스킬 보이스 (보이스)',
        64: '던전 보너스 (던보, 동굴각)',
        65: 'HP 약화 (체깎)',
        66: '공격 약화 (공깎)',
        67: '회복 약화 (회깎)',
        68: '암흑 내성+ (암완막)',
        69: '방해 내성+ (방완막)',
        70: '독 내성+ (독완막)',
        71: '방해드롭의 가호 (방해낙차)',
        72: '독드롭의 가호 (독낙차)',
        73: '불 콤보 강화 (불타코)',
        74: '물 콤보 강화 (물타코)',
        75: '나무 콤보 강화 (풀타코, 목타코)',
        76: '빛 콤보 강화 (빛타코)',
        77: '어둠 콤보 강화 (암타코)',
        78: '십자 지움 공격 (십자각, +각)',
        79: '3속성 공격 강화 (3속각)',
        80: '4속성 공격 강화 (4속각)',
        81: '5속성 공격 강화 (5속각)',
        82: '초 연결 지움 강화 (초연결)',
        83: '드래곤타입 추가 (드타입 부여, 드 부여)',
        84: '신타입 추가 (신타입 부여, 신 부여)',
        85: '악마타입 추가 (악마타입 부여, 악 부여)',
        86: '머신타입 추가 (머신타입 부여, 머타입 부여)',
        87: '밸런스타입 추가 (밸런스타입 부여, 밸타입 부여)',
        88: '공격타입 추가 (공타입 부여, 공부여)',
        89: '체력타입 추가 (체타입 부여, 체부여)',
        90: '회복타입 추가 (회타입 부여, 회부여)',
        91: '서브속성 변경 - 불 (불부속, 불부여)',
        92: '서브속성 변경 - 물 (물부속, 물부여)',
        93: '서브속성 변경 - 나무 (목부속, 목부여)',
        94: '서브속성 변경 - 빛 (빛부속, 빛부여)',
        95: '서브속성 변경 - 어둠 (암부속, 암부여)',
        96: '2마리 공격+ (웨이쁠, 투웨이쁠)',
        97: '스킬 차지+ (스차쁠)',
        98: '자동회복+ (자회쁠)',
        99: '불드롭 강화+ (화드강,불드강)',
        100: '물드롭 강화+ (수드강,물드강)',
        101: '나무드롭 강화+ (목드강,풀드강)',
        102: '빛드롭 강화+ (빛드강)',
        103: '어둠드롭 강화+ (암드강)',
        104: '회복드롭 강화+ (회드강쁠)',
        105: '스킬 부스트 마이너스 (턴밀각)',
        106: '부유 (부유)',
        107: '콤보 강화+ (7콤쁠, 14콤각)',
        108: 'L자 지움 공격+ (엘쁠, 엘+, L쁠, L+)',
        109: '대미지 무효 관통+ (무무쁠)',
        110: '십자 지움 공격+ (십자쁠)',
        111: '초 콤보 강화+ (10콤쁠, 20콤각)',
        112: '3속성 공격 강화+ (3속쁠)',
        113: '4속성 공격 강화+ (4속쁠)',
        114: '5속성 공격 강화+ (5속쁠)',
        115: '바인드 회복+ (바회쁠)',
        116: '불 가로 1렬 강화+ (불횡쁠)',
        117: '물 가로 1렬 강화+ (물횡쁠)',
        118: '나무 가로 1렬 강화+ (목횡쁠, 풀횡쁠)',
        119: '빛 가로 1렬 강화+ (빛횡쁠)',
        120: '어둠 가로 1렬 강화+ (암횡쁠)',
        121: '불 콤보 강화+ (불타코쁠)',
        122: '물 콤보 강화+ (물타코쁠)',
        123: '나무 콤보 강화+ (목타코쁠, 풀타코쁠)',
        124: '빛 콤보 강화+ (빛타코쁠)',
        125: '어둠 콤보 강화+ (암타코쁠)',
        126: 'T자 지움 공격 (T각, T자)',
        127: '모든 파라미터 강화(올파라, 올파라각)',
        128: '양의 가호 (양각)',
        129: '음의 가호 (음각)',
        130: '숙성 (숙성, 술통)',
        131: '부위 파괴 보너스 (부파, 부파각)',
        132: '애프터눈 티(찻잔, 커피각)',
        133: '불물 동시 공격 (불물각)',
        134: '물나무 동시 공격 (물풀각)',
        135: '나무불 동시 공격 (불풀각)',
        136: '스킬 지연 내성 (스지각)',
        137: '5속성 드롭 강화 (5드강, 올드강)',
        138: '어시스트 공명 (공명, 어시공명)',
        139: '자신의 힘(자력, 자력각)',
        140: '조작시간 변경 내성 (조작내성)',
        141: '달인 다색 강화 (달인, 달인각)',
        142: '모든 파라미터 강화+ (올파라쁠)'
    };

    let parsedCards = [];
    let parsedSkills = {};

    function parseData(rawMonsters, rawSkills) {
        parsedSkills = parseSkills(rawSkills);
        parsedCards = parseMonsters(rawMonsters);
        return { cards: parsedCards, skills: parsedSkills };
    }

    function parseSkills(raw) {
        const skills = {};
        if (Array.isArray(raw)) {
            raw.forEach(s => {
                if (s && s.id !== undefined) {
                    skills[s.id] = {
                        id: s.id,
                        name: s.name || '',
                        description: s.description || '',
                        initialCooldown: s.initialCooldown || 0,
                        maxLevel: s.maxLevel || 0,
                        type: s.type || 0
                    };
                }
            });
        } else if (typeof raw === 'object') {
            Object.keys(raw).forEach(key => {
                const s = raw[key];
                if (s) {
                    skills[key] = {
                        id: parseInt(key) || s.id,
                        name: s.name || '',
                        description: s.description || '',
                        initialCooldown: s.initialCooldown || 0,
                        maxLevel: s.maxLevel || 0,
                        type: s.type || 0
                    };
                }
            });
        }
        return skills;
    }

    function parseMonsters(raw) {
        const cards = [];
        const process = (item) => {
            if (!item || item.id === undefined || item.id === 0) return;
            // Skip cards with no name (usually placeholders)
            if (!item.name && !item.id) return;

            const card = {
                id: item.id,
                name: item.name || `카드 #${item.id}`,
                attrs: item.attrs || [item.attribute || -1, item.subAttribute !== undefined ? item.subAttribute : -1],
                types: item.types || [],
                rarity: item.rarity || 0,
                cost: item.cost || 0,
                maxLevel: item.maxLevel || 0,
                hp: item.hp || { min: 0, max: 0, scale: 0 },
                atk: item.atk || { min: 0, max: 0, scale: 0 },
                rcv: item.rcv || { min: 0, max: 0, scale: 0 },
                exp: item.exp || 0,
                activeSkillId: item.activeSkillId || 0,
                leaderSkillId: item.leaderSkillId || 0,
                awakenings: item.awakenings || [],
                superAwakenings: item.superAwakenings || [],
                sellMP: item.sellMP || 0,
                limitBreakIncr: item.limitBreakIncr || 0,
                evoRootId: item.evoRootId || item.id,
                series: item.series || null,
                collab: item.collab || null,
                inheritable: item.inheritable || false
            };

            // Normalize attrs
            if (typeof card.attrs[0] === 'undefined' || card.attrs[0] === null) card.attrs[0] = -1;
            if (typeof card.attrs[1] === 'undefined' || card.attrs[1] === null) card.attrs[1] = -1;
            if (typeof card.attrs[2] === 'undefined' || card.attrs[2] === null) card.attrs[2] = -1;

            cards.push(card);
        };

        if (Array.isArray(raw)) {
            raw.forEach(process);
        } else if (typeof raw === 'object') {
            Object.values(raw).forEach(process);
        }

        return cards;
    }

    function getAttrName(attrId) {
        return ATTR_NAMES[attrId] || '?';
    }

    function getAttrClass(attrId) {
        return ATTR_CLASSES[attrId] || '';
    }

    function getTypeName(typeId) {
        return TYPE_NAMES[typeId] || `타입${typeId}`;
    }

    function getAwakenName(awakenId) {
        return AWAKEN_NAMES[awakenId] || `각성#${awakenId}`;
    }

    function getSkill(skillId) {
        return parsedSkills[skillId] || null;
    }

    function getRarityStars(rarity) {
        return '★'.repeat(Math.min(rarity, 10));
    }

    function getAllCards() {
        return parsedCards;
    }

    return {
        parseData,
        getAttrName,
        getAttrClass,
        getTypeName,
        getAwakenName,
        getSkill,
        getRarityStars,
        getAllCards,
        ATTR_NAMES,
        ATTR_CLASSES,
        TYPE_NAMES,
        AWAKEN_NAMES
    };
})();
