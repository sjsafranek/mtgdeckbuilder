import os
import json
import sqlite3
import requests
from flask import Flask

app = Flask(__name__)

# setup database
conn = sqlite3.connect('catalog.db')
cursor = conn.cursor()
cursor.execute('''
    CREATE TABLE IF NOT EXISTS cards(
        name        TEXT,
        type        TEXT,
        types       TEXT,
        subtypes    TEXT,
        supertypes  TEXT,
        cmc         INTEGER,
        mana_cost   TEXT,
        color_r     BOOLEAN,
        color_g     BOOLEAN,
        color_b     BOOLEAN,
        color_u     BOOLEAN,
        color_w     BOOLEAN,
        text        TEXT,
        power       INTEGER,
        toughness   INTEGER
    );
''')

conn.commit()



card_catalog_file = 'AllCards.json'

if not os.path.exists(card_catalog_file):

    resp = requests.get('https://mtgjson.com/json/AllCards.json', stream=True)
    resp.raise_for_status()
    with open(card_catalog_file, 'wb') as fh:
        for chunk in resp.iter_content(1024):
            fh.write(chunk)

    catalog = {}
    with open(card_catalog_file, 'r') as f:
        catalog = json.load(f)

    cards = []
    for name in catalog:
        card = catalog[name]

        manaCost = None
        if 'manaCost' in card:
            manaCost = card['manaCost']

        text = None
        if 'text' in card:
            text = card['text']

        power = None
        if 'power' in card:
            text = card['power']

        toughness = None
        if 'toughness' in card:
            text = card['toughness']

        cards.append((
            card['name'],
            card['type'],
            json.dumps(card['types']),
            json.dumps(card['subtypes']),
            json.dumps(card['supertypes']),
            int(card['convertedManaCost']),
            manaCost,
            'R' in card['colors'],
            'G' in card['colors'],
            'B' in card['colors'],
            'U' in card['colors'],
            'W' in card['colors'],
            text,
            power,
            toughness
        ))

    cursor.executemany('INSERT INTO cards (name, type, types, subtypes, supertypes, cmc, mana_cost, color_r, color_g, color_b, color_u, color_w, text, power, toughness) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', cards)
    conn.commit()



@app.route('/')
def hello():
    return "Hello World!"

if __name__ == '__main__':
    app.run()
