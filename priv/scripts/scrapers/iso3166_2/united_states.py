# import csv
# import requests
# from bs4 import BeautifulSoup

# URL = "https://en.wikipedia.org/wiki/ISO_3166-2:US"

# resp = requests.get(URL)
# resp.raise_for_status()

# soup = BeautifulSoup(resp.text, features="html.parser")
# table = soup.table
# rows = table.find_all("tr")

# with open("us.csv", "w") as csvfile:
#   writer = csv.DictWriter(csvfile, fieldnames=["code", "name", "category"])
#   writer.writeheader()
#   for row in rows[1:]:
#     columns = row.find_all("td")
#     code = columns[0].span.string.strip()
#     name = columns[1].a.string.strip()
#     category = columns[2].string.strip()
#     writer.writerow({"code": code, "name": name, "category": category})


import csv
import requests
from bs4 import BeautifulSoup

WIKIPEDIA_URL = "https://en.wikipedia.org/wiki/ISO_3166-2:US"
STATOIDS_URL = "http://www.statoids.com/uus.html"

wikipedia_resp = requests.get(WIKIPEDIA_URL)
wikipedia_resp.raise_for_status()

statoids_resp = requests.get(STATOIDS_URL)
statoids_resp.raise_for_status()

states = {}

# Wikipedia
soup = BeautifulSoup(wikipedia_resp.text, features="html.parser")
table = soup.table
rows = table.find_all("tr")

for row in rows[1:]:
  columns = row.find_all("td")
  code = columns[0].span.string.strip()
  name = columns[1].a.string.strip()
  category = columns[2].string.strip()
  states[code] = {"code": code, "name": name, "category": category}

# Statoids
soup = BeautifulSoup(statoids_resp.text, features="html.parser")
table = soup.find("table", class_="st")
rows = table.find_all("tr")

for row in rows[1:52]:
  columns = row.find_all("td")
  code = columns[1].code.string.split(".")[1]
  fips = columns[2].code.string
  states[f"US-{code}"].update({"fips": fips})

# Write CSV
with open("us.csv", "w") as csvfile:
  writer = csv.DictWriter(csvfile, fieldnames=["code", "name", "category", "fips"])
  writer.writeheader()

  for state in states.values():
    writer.writerow(state)
