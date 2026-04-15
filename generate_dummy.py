import random

cities = [
    { "base_lat": -6.2088, "base_lng": 106.8456, "name": "Jakarta" },
    { "base_lat": -6.9175, "base_lng": 107.6191, "name": "Bandung" },
    { "base_lat": -7.7956, "base_lng": 110.3695, "name": "Yogyakarta" },
    { "base_lat": -6.9932, "base_lng": 110.4203, "name": "Semarang" },
    { "base_lat": -7.2504, "base_lng": 112.7688, "name": "Surabaya" },
    { "base_lat": -8.6705, "base_lng": 115.2128, "name": "Denpasar" },
    { "base_lat": -3.3194, "base_lng": 114.5901, "name": "Banjarmasin" },
    { "base_lat": -5.1476, "base_lng": 119.4327, "name": "Makassar" },
    { "base_lat": 3.5952, "base_lng": 98.6722,  "name": "Medan" },
    { "base_lat": -0.9492, "base_lng": 100.3543, "name": "Padang" },
]

names = ["Outdoor", "Adventure", "Camping", "Gear", "Rental", "Trek", "Camp", "Hike", "Summit", "Basecamp"]
random.seed(42)

values = []
for i in range(1, 101):
    city = random.choice(cities)
    lat = city["base_lat"] + random.uniform(-0.05, 0.05)
    lng = city["base_lng"] + random.uniform(-0.05, 0.05)
    name = f"Dummy {random.choice(names)} {random.choice(names)} {city['name']} {i}"
    phone = f"08{random.randint(1000000000, 9999999999)}"
    address = f"Jl. Dummy No. {i}, {city['name']}"
    rating = round(random.uniform(3.5, 5.0), 1)
    review_count = random.randint(10, 500)
    is_open = random.choice(["TRUE", "FALSE", "TRUE", "TRUE"])
    values.append(f"        ('{name}', NULL, '{phone}', '{address}', {rating}, {review_count}, {is_open}, 'assets/images/store_jakarta.png', {lat:.6f}, {lng:.6f})")

with open('dummy.sql', 'w') as f:
    f.write(",\n".join(values))
print('done')
