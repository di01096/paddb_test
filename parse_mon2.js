const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

/**
 * parse_mon2.js
 * Node.js script to process PAD .bin files from mon2 directory.
 */

const MON2_DIR = path.join(__dirname, 'mon2');
const OUTPUT_FILE = path.join(__dirname, 'extracted_monsters.json');
const RECORD_SIZE = 438; // Default record size for recent versions

function parseMonster(buffer) {
    try {
        // Basic mapping based on standard PAD binary structure
        // Note: Offsets can vary between game versions. 
        // This is a common baseline for current versions (~438 bytes).
        
        return {
            id: buffer.readUInt16LE(0),
            hp_min: buffer.readUInt32LE(4),
            atk_min: buffer.readUInt32LE(8),
            rcv_min: buffer.readUInt32LE(12),
            max_level: buffer.readUInt8(16),
            main_attr: buffer.readInt16LE(18),
            sub_attr: buffer.readInt16LE(20),
            is_inheritable: buffer.readUInt8(22) > 0,
            type1: buffer.readUInt8(24),
            type2: buffer.readUInt8(25),
            rarity: buffer.readUInt8(26),
            cost: buffer.readUInt16LE(28),
            // More fields like awakenings are usually later in the record
            // Awakenings often start around offset 100-200 depending on version
        };
    } catch (e) {
        return null;
    }
}

function processFolder() {
    if (!fs.existsSync(MON2_DIR)) {
        console.error(`[!] Error: Directory not found: ${MON2_DIR}`);
        return;
    }

    const files = fs.readdirSync(MON2_DIR).filter(f => f.endsWith('.bin'));
    console.log(`[*] Found ${files.length} .bin files in ${MON2_DIR}`);

    let allMonsters = [];

    files.forEach(file => {
        console.log(`[*] Processing ${file}...`);
        const filePath = path.join(MON2_DIR, file);
        const fileData = fs.readFileSync(filePath);

        if (fileData.length < 32) return;

        // PAD Header: 32 bytes
        // Monster count is usually at offset 24
        const monsterCount = fileData.readUInt32LE(24);
        const compressedBody = fileData.slice(32);

        try {
            const decompressed = zlib.inflateSync(compressedBody);
            
            // Inside decompressed data, there is often another 32-byte header
            // followed by records.
            for (let i = 0; i < monsterCount; i++) {
                const offset = 32 + (i * RECORD_SIZE);
                if (offset + RECORD_SIZE > decompressed.length) break;

                const record = decompressed.slice(offset, offset + RECORD_SIZE);
                const monster = parseMonster(record);
                
                if (monster && monster.id > 0) {
                    allMonsters.push(monster);
                }
            }
        } catch (err) {
            console.error(`[!] Failed to decompress/parse ${file}: ${err.message}`);
        }
    });

    // Save consolidated data
    fs.writeFileSync(OUTPUT_FILE, JSON.stringify(allMonsters, null, 2), 'utf-8');
    console.log(`[+] Successfully extracted ${allMonsters.length} monsters to ${OUTPUT_FILE}`);
}

processFolder();
