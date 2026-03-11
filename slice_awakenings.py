import os
import urllib.request
import hashlib
from PIL import Image

AWOKEN_URL = 'https://mapaler.github.io/PADDashFormation/images/awoken.png'

def get_file_hash(filepath):
    """Returns the MD5 hash of a file, or None if it doesn't exist."""
    if not os.path.exists(filepath):
        return None
    hasher = hashlib.md5()
    with open(filepath, 'rb') as f:
        hasher.update(f.read())
    return hasher.hexdigest()

def check_and_update(image_path='awoken.png', out_dir='awakenings', icon_size=32):
    """
    Downloads the remote awoken.png and hashes it.
    If the hash differs from the local awoken.png (meaning it was updated),
    it saves the new image and re-runs the slicing logic.
    """
    print(f"[Auto-Update] Checking for updates from {AWOKEN_URL}...")
    try:
        # User-Agent is sometimes required by GitHub pages to prevent 403s
        req = urllib.request.Request(AWOKEN_URL, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        remote_data = response.read()
    except Exception as e:
        print(f"[Auto-Update] Failed to fetch remote image: {e}")
        return

    remote_hash = hashlib.md5(remote_data).hexdigest()
    local_hash = get_file_hash(image_path)

    if local_hash == remote_hash:
        print("[Auto-Update] Local 'awoken.png' is already up-to-date. No slice needed.")
    else:
        print("[Auto-Update] Update found! Saving new 'awoken.png' and slicing...")
        with open(image_path, 'wb') as f:
            f.write(remote_data)
        slice_awakenings(image_path, out_dir, icon_size)

def slice_awakenings(image_path='awoken.png', out_dir='awakenings', icon_size=32):
    """
    Slices the awoken.png sprite sheet into individual 32x32px icons.
    As per accurate cutting logic, horizontal columns are variations/states.
    We only extract the first column (col 0) from top to bottom, row by row.
    The ID of the awakening directly corresponds to its row index.
    """
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    try:
        img = Image.open(image_path)
    except FileNotFoundError:
        print(f"Error: Could not find '{image_path}'.")
        return

    img_width, img_height = img.size
    rows = img_height // icon_size

    saved_count = 0
    print(f"[Slice] Slicing '{image_path}' ({img_width}x{img_height})... extracting first column only.")

    for row in range(rows):
        icon_id = row
        
        # We only care about the very first column (left = 0)
        left = 0
        upper = row * icon_size
        right = icon_size
        lower = upper + icon_size
        
        # Crop the icon from the main sheet
        icon = img.crop((left, upper, right, lower))
        
        # Save the cropped icon using its ID
        out_path = os.path.join(out_dir, f'{icon_id}.png')
        icon.save(out_path)
        
        saved_count += 1

    print(f"[Slice] Successfully extracted {saved_count} icons to the '{out_dir}/' directory.")

if __name__ == '__main__':
    # Run the check and update flow by default
    check_and_update()
