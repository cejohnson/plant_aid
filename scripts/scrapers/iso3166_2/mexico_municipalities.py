import csv
import re
import requests
from bs4 import BeautifulSoup

STATOIDS_URL = "http://www.statoids.com/ymx.html"

statoids_resp = requests.get(STATOIDS_URL)
statoids_resp.raise_for_status()

soup = BeautifulSoup(statoids_resp.text, features="html.parser")
municipality_blob = soup.pre.string
municipalities = re.findall(r'(.*)MX\.\w{2}.\w{2} (.{2}) (.{3}).*\n', municipality_blob)

# Print CSV
with open("mx_municipalities.csv", "w") as csvfile:
  writer = csv.DictWriter(csvfile, fieldnames=["name", "inegi_state", "inegi_municipality"])
  writer.writeheader()

  for (name, state, municipality) in municipalities:
    writer.writerow({"name": name.strip(), "inegi_state": state, "inegi_municipality": municipality})
