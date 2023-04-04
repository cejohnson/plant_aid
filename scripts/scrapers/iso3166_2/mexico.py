import csv
import requests
from bs4 import BeautifulSoup

WIKIPEDIA_URL = "https://en.wikipedia.org/wiki/ISO_3166-2:MX"
STATOIDS_URL = "http://www.statoids.com/umx.html"

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
  category = columns[3].string.strip().capitalize()
  states[code] = {"code": code, "name": name, "category": category}

# Statoids
soup = BeautifulSoup(statoids_resp.text, features="html.parser")
table = soup.find("table", class_="st")
rows = table.find_all("tr")

for row in rows[1:33]:
  columns = row.find_all("td")
  code = columns[2].code.string
  # Special case Mexico City
  if code == "DIF":
    code = "CMX"
  fips = columns[3].code.string
  inegi = columns[5].code.string
  states[f"MX-{code}"].update({"fips": fips, "inegi": inegi})

# Print CSV
with open("mx.csv", "w") as csvfile:
  writer = csv.DictWriter(csvfile, fieldnames=["code", "name", "category", "fips", "inegi"])
  writer.writeheader()

  for state in states.values():
    writer.writerow(state)
