import os
import zlib
import struct
import json
import subprocess

# Configuration
REPO_URL = "https://github.com/Mapaler/Puzzle-and-Dragons-Data-Files"
DATA_DIR = "pad_data_repo"
OUTPUT_FILE = "extracted_monsters.json"
CARDS_DIR = os.path.join(DATA_DIR, "cards_KO")

def clone_repo():
    """Clones the data repository if it doesn't exist."""
    if not os.path.exists(DATA_DIR):
        print(f"[*] Cloning {REPO_URL} into {DATA_DIR}...")
        subprocess.run(["git", "clone", "--depth", "1", REPO_URL, DATA_DIR], check=True)
    else:
        print("[*] Repository already exists. Pulling latest changes...")
        subprocess.run(["git", "-C", DATA_DIR, "pull"], check=True)

def parse_monster_record(data):
    """
    Parses a single monster record from the binary data.
    Based on standard PAD binary structure (approx 438 bytes per record).
    Note: Offsets can vary between game versions.
    """
    try:
        # Standard record structure (simplified example)
        # ID: uint16 at 0
        # HP: uint32 at 4
        # ATK: uint32 at 8
        # RCV: uint32 at 12
        monster_id = struct.unpack('<H', data[0:2])[0]
        hp = struct.unpack('<I', data[4:8])[0]
        atk = struct.unpack('<I', data[8:12])[0]
        rcv = struct.unpack('<I', data[12:16])[0]
        
        return {
            "id": monster_id,
            "hp": hp,
            "atk": atk,
            "rcv": rcv
        }
    except Exception as e:
        return None

def extract_data():
    """Extracts data from .bin files in cards_KO."""
    if not os.path.exists(CARDS_DIR):
        print(f"[!] Error: {CARDS_DIR} not found.")
        return

    all_monsters = []
    
    # Iterate through all .bin files in cards_KO
    bin_files = sorted([f for f in os.listdir(CARDS_DIR) if f.endswith('.bin')])
    print(f"[*] Found {len(bin_files)} .bin files to process.")

    for bin_file in bin_files:
        file_path = os.path.join(CARDS_DIR, bin_file)
        print(f"[*] Processing {bin_file}...")
        
        with open(file_path, 'rb') as f:
            raw_data = f.read()
            
        # PAD .bin files often have a 32-byte header followed by zlib compression
        header = raw_data[:32]
        compressed_content = raw_data[32:]
        
        try:
            # Decompress the content
            decompressed = zlib.decompress(compressed_content)
            
            # The decompressed content starts with a header (often 32 bytes)
            # followed by fixed-length monster records.
            # Record size is typically 438 bytes in recent versions.
            record_size = 438
            monster_count = struct.unpack('<I', header[24:28])[0]
            
            for i in range(monster_count):
                offset = 32 + (i * record_size)
                if offset + record_size > len(decompressed):
                    break
                    
                record = decompressed[offset : offset + record_size]
                monster_info = parse_monster_record(record)
                if monster_info and monster_info['id'] > 0:
                    all_monsters.append(monster_info)
                    
        except Exception as e:
            print(f"[!] Failed to parse {bin_file}: {e}")

    # Save to JSON
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(all_monsters, f, indent=2, ensure_ascii=False)
    
    print(f"[+] Successfully extracted {len(all_monsters)} monsters to {OUTPUT_FILE}")

if __name__ == "__main__":
    clone_repo()
    extract_data()
