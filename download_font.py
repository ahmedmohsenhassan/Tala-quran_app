import urllib.request
import os

os.makedirs('assets/fonts', exist_ok=True)
urls = [
    "https://raw.githubusercontent.com/thetruetruth/quran-data-kfgqpc/master/fonts/KFGQPC%20Uthmanic%20Script%20HAFS%20Regular.ttf",
    "https://raw.githubusercontent.com/quran/quran-ios/master/Quran/Quran/Fonts/me_quran.ttf",
    "https://raw.githubusercontent.com/islamic-network/cdn/master/fonts/me_quran.ttf",
    "https://raw.githubusercontent.com/nasser/quran_mushaf/master/assets/fonts/me_quran.ttf"
]

success = False
for url in urls:
    try:
        print(f"Trying {url}...")
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response, open('assets/fonts/KFGQPC_Uthmanic_Script_HAFS_Regular.ttf', 'wb') as out_file:
            data = response.read()
            out_file.write(data)
        print("Success!")
        success = True
        break
    except Exception as e:
        print(f"Failed: {e}")

if not success:
    with open('assets/fonts/failed.log', 'w') as f:
        f.write("All failed")
