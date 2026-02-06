import os
import json
import re
import hashlib

# Configuration
REPO_URL = "https://niconachoo.github.io/DunZum/"
ROOT_DIR = "."
CONSTANTS_FILE = os.path.join(ROOT_DIR, "src", "Constants.lua")
OUTPUT_FILE = os.path.join(ROOT_DIR, "version.json")
FILES_TO_INCLUDE = ["main.lua", "src", "music", "imgs", "lib"] # File or Directory paths relative to ROOT_DIR

def get_game_version():
    """Extracts GAME_VERSION from src/Constants.lua"""
    try:
        with open(CONSTANTS_FILE, 'r') as f:
            content = f.read()
            match = re.search(r'GAME_VERSION\s*=\s*"([^"]+)"', content)
            if match:
                return match.group(1)
            else:
                print("Error: GAME_VERSION not found in Constants.lua")
                return None
    except FileNotFoundError:
        print(f"Error: Could not find {CONSTANTS_FILE}")
        return None

def get_file_hash(path):
    """Calculates MD5 hash of a file"""
    try:
        with open(path, 'rb') as f:
            file_hash = hashlib.md5()
            while chunk := f.read(8192):
                file_hash.update(chunk)
        return file_hash.hexdigest()
    except Exception as e:
        print(f"Error hashing {path}: {e}")
        return None

def get_files_list():
    """Walks directories and returns a list of file info dicts"""
    file_list = []
    
    for item in FILES_TO_INCLUDE:
        item_path = os.path.join(ROOT_DIR, item)
        
        if os.path.isfile(item_path):
            # Single file
            rel_path = item.replace("\\", "/")
            file_hash = get_file_hash(item_path)
            
            if file_hash:
                file_list.append({
                    "path": rel_path,
                    "url": REPO_URL + rel_path,
                    "md5": file_hash
                })
            
        elif os.path.isdir(item_path):
            # Directory
            for root, dirs, files in os.walk(item_path):
                for file in files:
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, ROOT_DIR).replace("\\", "/")
                    
                    # Optional: Exclude certain files (like .DS_Store, temporary files)
                    if file.startswith("."):
                        continue
                        
                    file_hash = get_file_hash(full_path)
                    
                    if file_hash:
                        file_list.append({
                            "path": rel_path,
                            "url": REPO_URL + rel_path,
                            "md5": file_hash
                        })
    
    return file_list

def main():
    print("Generating version.json...")
    
    version = get_game_version()
    if not version:
        return

    files = get_files_list()
    
    manifest = {
        "version": version,
        "files": files
    }
    
    # Write to file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(manifest, f, indent=4)
        
    print(f"Success! version.json generated for version {version} with {len(files)} files.")

if __name__ == "__main__":
    main()
