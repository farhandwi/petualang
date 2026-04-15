import sys

target = 'server/lib/db/database.dart'
dummy_file = 'dummy.sql'

with open(dummy_file, 'r', encoding='utf-8') as f:
    dummy_content = f.read()

with open(target, 'r', encoding='utf-8') as f:
    content = f.read()

search_str = "('Osing Trekking Center', NULL, '085512341234', 'Jl. Ahmad Yani No.105, Taman Baru, Banyuwangi, Jawa Timur 68416', 4.8, 140, TRUE, 'assets/images/store_banyuwangi.png', -8.219233, 114.369227)"

if search_str in content:
    replacement = search_str + ",\n" + dummy_content
    new_content = content.replace(search_str, replacement)
    
    with open(target, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print('Successfully inserted dummy data')
else:
    print('Failed to find search string')
