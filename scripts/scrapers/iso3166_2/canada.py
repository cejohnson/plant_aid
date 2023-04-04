import csv
import requests
from bs4 import BeautifulSoup

WIKIPEDIA_URL = "https://en.wikipedia.org/wiki/ISO_3166-2:CA"
STATOIDS_URL = "http://www.statoids.com/uca.html"

wikipedia_resp = requests.get(WIKIPEDIA_URL)
wikipedia_resp.raise_for_status()

statoids_resp = requests.get(STATOIDS_URL)
statoids_resp.raise_for_status()

provinces = {}

# Wikipedia
soup = BeautifulSoup(wikipedia_resp.text, features="html.parser")
table = soup.table
rows = table.find_all("tr")

for row in rows[1:]:
  columns = row.find_all("td")
  code = columns[0].span.string.strip()
  name = columns[1].a.string.strip()
  category = columns[3].string.strip()
  provinces[code] = {"code": code, "name": name, "category": category}

# Statoids
soup = BeautifulSoup(statoids_resp.text, features="html.parser")
table = soup.find("table", class_="st")
rows = table.find_all("tr")

for row in rows[1:14]:
  columns = row.find_all("td")
  code = columns[2].code.string
  fips = columns[3].code.string
  sgc = columns[4].code.string
  provinces[f"CA-{code}"].update({"fips": fips, "sgc": sgc})

with open("ca.csv", "w") as csvfile:
  writer = csv.DictWriter(csvfile, fieldnames=["code", "name", "category", "fips", "sgc"])
  writer.writeheader()

  for province in provinces.values():
    writer.writerow(province)
