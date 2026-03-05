import os
import json

input_folder = 'assets/surahs'
output_file = 'lib/data/surahs.dart'

surah_list = []

for filename in sorted(os.listdir(input_folder)):
    if filename.endswith('.json'):
        filepath = os.path.join(input_folder, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            surah_data = json.load(f)

            # تأكد أن المفاتيح موجودة قبل الإضافة
            if 'name' in surah_data and 'english_name' in surah_data and 'number' in surah_data:
                surah_list.append({
                    'name': surah_data['name'],
                    'english_name': surah_data['english_name'],
                    'number': surah_data['number'],
                })
            else:
                print(f"⚠️ Skipped: {filename} missing required keys")

with open(output_file, 'w', encoding='utf-8') as f:
    f.write('// GENERATED FILE - DO NOT MODIFY MANUALLY\n')
    f.write('final List<Map<String, dynamic>> surahs = [\n')
    for surah in surah_list:
        f.write('  {\n')
        f.write(f'    "name": "{surah["name"]}",\n')
        f.write(f'    "english_name": "{surah["english_name"]}",\n')
        f.write(f'    "number": {surah["number"]},\n')
        f.write('  },\n')
    f.write('];\n')

print("✅ surahs.dart generated successfully.")
