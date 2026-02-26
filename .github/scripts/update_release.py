import argparse
import os
import re
import shutil
import subprocess
import sys
import urllib.request
import urllib.error
import hashlib
import json

# Configuration
REPO_ROOT = os.getcwd()
PACKAGE_SWIFT_PATH = os.path.join(REPO_ROOT, "Package.swift")
OBJECTIVEC_DIR = os.path.join(REPO_ROOT, "objectivec")
ORT_REPO_URL = "https://github.com/microsoft/onnxruntime.git"
EXT_REPO_API = "https://api.github.com/repos/microsoft/onnxruntime-extensions/releases"
ORT_REPO_API = "https://api.github.com/repos/microsoft/onnxruntime/releases"

def run_command(command, cwd=None):
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, cwd=cwd, text=True, capture_output=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        sys.exit(1)
    return result.stdout.strip()

def fetch_releases(api_url, github_token=None):
    print(f"Fetching releases from {api_url}...")
    try:
        # Fetching first page (30 items) should be enough to find a valid release
        headers = {}
        if github_token:
            headers["Authorization"] = f"Bearer {github_token}"
        req = urllib.request.Request(api_url, headers=headers)
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read())
    except Exception as e:
        print(f"Failed to fetch releases: {e}")
        sys.exit(1)

def check_url_exists(url):
    try:
        req = urllib.request.Request(url, method='HEAD')
        with urllib.request.urlopen(req) as response:
            return response.status == 200
    except urllib.error.HTTPError:
        return False
    except Exception as e:
        print(f"Error checking URL {url}: {e}")
        return False

def calculate_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def find_latest_valid_release(releases, is_extension=False):
    base_url = "https://download.onnxruntime.ai/"
    
    for release in releases:
        tag_name = release["tag_name"]
        
        version_clean = tag_name.lstrip("v")
        
        if is_extension:
            filename = f"pod-archive-onnxruntime-extensions-c-{version_clean}.zip"
        else:
            filename = f"pod-archive-onnxruntime-c-{version_clean}.zip"
            
        url = base_url + filename
        print(f"Checking {tag_name}: {url} ...", end=" ", flush=True)
        if check_url_exists(url):
            print("FOUND")
            return tag_name, version_clean, url
        else:
            print("MISSING")
                
    print(f"Error: No valid release found in the recent list for {'extensions' if is_extension else 'runtime'}.")
    sys.exit(1)

def download_file(url, dest_path):
    print(f"Downloading {url} to {dest_path}...")
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as response:
            with open(dest_path, 'wb') as out_file:
                shutil.copyfileobj(response, out_file)
    except Exception as e:
        print(f"Failed to download {url}: {e}")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Update ONNX Runtime Swift Package")
    parser.add_argument("--ort-version", help="Optional: Force check specific ORT version")
    parser.add_argument("--ext-version", help="Optional: Force check specific Ext version")
    parser.add_argument("--github-token", help="Optional: GitHub token for authenticated API requests")
    args = parser.parse_args()

    github_token = args.github_token or os.environ.get("GITHUB_TOKEN")

    # 1. Find Latest Valid ORT Version
    if args.ort_version:
        # If version provided, we just check that specific version
        ort_tag = args.ort_version
        if not ort_tag.startswith("v"): ort_tag = "v" + ort_tag
        print(f"Checking provided ORT version: {ort_tag}")
        ort_releases = [{"tag_name": ort_tag}]
    else:
        ort_releases = fetch_releases(ORT_REPO_API, github_token)
        
    ort_tag, ort_version_clean, ort_url = find_latest_valid_release(ort_releases, is_extension=False)
    print(f"Selected ONNX Runtime: {ort_tag} ({ort_url})")

    # 2. Check if tag exists locally (prefer tag with v prefix)
    existing_tags = run_command("git tag").splitlines()
    if ort_tag in existing_tags:
        print(f"Tag {ort_tag} already exists locally. Skipping update.")
        sys.exit(0)

    # 3. Find Latest Valid Extension Version
    if args.ext_version:
        ext_tag = args.ext_version
        if not ext_tag.startswith("v"): ext_tag = "v" + ext_tag
        ext_releases = [{"tag_name": ext_tag}]
    else:
        ext_releases = fetch_releases(EXT_REPO_API, github_token)
        
    ext_tag, ext_version_clean, ext_url = find_latest_valid_release(ext_releases, is_extension=True)
    print(f"Selected Extensions: {ext_tag} ({ext_url})")

    # 4. Sync Objective-C Source
    print("Syncing Objective-C source files...")
    temp_dir = os.path.join(REPO_ROOT, "temp_ort_clone")
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    
    run_command(f"git clone --depth 1 --branch {ort_tag} {ORT_REPO_URL} {temp_dir}")
    
    # Remove existing objectivec dir
    if os.path.exists(OBJECTIVEC_DIR):
        shutil.rmtree(OBJECTIVEC_DIR)
    
    # Copy new objectivec dir
    src_objectivec = os.path.join(temp_dir, "objectivec")
    shutil.copytree(src_objectivec, OBJECTIVEC_DIR)
    
    # Cleanup clone
    shutil.rmtree(temp_dir)

    # 5. Update Package.swift
    print("Updating Package.swift...")
    
    # Download and Hash ORT
    ort_zip_path = os.path.join(REPO_ROOT, f"ort-{ort_version_clean}.zip")
    download_file(ort_url, ort_zip_path)
    ort_checksum = calculate_sha256(ort_zip_path)
    os.remove(ort_zip_path)
    print(f"ORT Checksum: {ort_checksum}")

    # Download and Hash Ext
    ext_zip_path = os.path.join(REPO_ROOT, f"ext-{ext_version_clean}.zip")
    download_file(ext_url, ext_zip_path)
    ext_checksum = calculate_sha256(ext_zip_path)
    os.remove(ext_zip_path)
    print(f"Ext Checksum: {ext_checksum}")
    
    # Read Package.swift
    with open(PACKAGE_SWIFT_PATH, "r") as f:
        content = f.read()
        
    # Capture 1: Target.binaryTarget(name: "onnxruntime", url: "
    ort_pattern = r'(Target\.binaryTarget\(\s*name:\s*"onnxruntime",\s+url:\s*")[^"]+("\s*,\s*(?://.*?\s+)*checksum:\s*")[^"]+("\))'
    
    # Ext
    ext_pattern = r'(Target\.binaryTarget\(\s*name:\s*"onnxruntime_extensions",\s+url:\s*")[^"]+("\s*,\s*(?://.*?\s+)*checksum:\s*")[^"]+("\))'
    
    # Using lambda for re.sub to avoid escaping issues with f-strings
    new_content = re.sub(ort_pattern, lambda m: f'{m.group(1)}{ort_url}{m.group(2)}{ort_checksum}{m.group(3)}', content, flags=re.DOTALL)
    new_content = re.sub(ext_pattern, lambda m: f'{m.group(1)}{ext_url}{m.group(2)}{ext_checksum}{m.group(3)}', new_content, flags=re.DOTALL)
    
    if content == new_content:
        print("Warning: Package.swift content did not change (regex might have failed or versions are same).")
    else:
        with open(PACKAGE_SWIFT_PATH, "w") as f:
            f.write(new_content)
        print("Package.swift updated.")
        
    # Export variables for GitHub Actions
    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"ort_version={ort_version_clean}\n")
            f.write(f"ext_version={ext_version_clean}\n")
            f.write(f"ort_tag={ort_tag}\n")
            f.write(f"ext_tag={ext_tag}\n")

if __name__ == "__main__":
    main()
