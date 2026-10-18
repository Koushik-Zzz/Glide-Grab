"""Read-only release/save checks for the owner's confirmed testing experience.

This never publishes, changes permissions, writes a save, or prints credentials.
The private snapshot is stored under ignored tmp/ for a later rejoin comparison.
"""
import json
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from roblox_assets import NoRedirect, api_key

ROOT = Path(__file__).resolve().parents[1]
UNIVERSE, PLACE, OWNER = 10770918233, 135204243659176, 4105644482
API = "https://apis.roblox.com/"


def read(path, key):
    req = urllib.request.Request(API + path, headers={"x-api-key": key})
    with urllib.request.build_opener(NoRedirect).open(req, timeout=20) as response:
        return json.load(response)


def main():
    key = api_key()
    universe = read(f"cloud/v2/universes/{UNIVERSE}", key)
    if universe.get("user") != f"users/{OWNER}":
        raise ValueError("Testing experience owner does not match the confirmed target.")
    place = read(f"cloud/v2/universes/{UNIVERSE}/places/{PLACE}", key)
    result = {"name": universe["displayName"], "universeId": UNIVERSE, "placeId": PLACE,
              "visibility": universe["visibility"], "serverSize": place["serverSize"],
              "placeUpdateTime": place.get("updateTime")}
    query = urllib.parse.urlencode({"datastoreName": "GlideGrab_Player_v1", "scope": "global",
                                    "entryKey": f"Player_{OWNER}"})
    try:
        record = read(f"datastores/v1/universes/{UNIVERSE}/standard-datastores/datastore/entries/entry?{query}", key)
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        result["ownerSaveExists"] = False
    else:
        data = record.get("Data", {})
        result.update(ownerSaveExists=True, coins=data.get("Coins"), boost=data.get("BoostLevel"),
                      rebirths=data.get("Rebirths"), bat=data.get("Bat"), shields=data.get("Shields"),
                      storedEggs=len(data.get("Eggs", [])), activeLease=bool(record.get("Session")))
        folder = ROOT / "tmp"
        folder.mkdir(exist_ok=True)
        (folder / "owner-live-save-latest.json").write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result))


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        print(json.dumps({"status": error.code, "error": "Roblox rejected the read-only check."}))
        raise SystemExit(1)
    except (urllib.error.URLError, TimeoutError):
        print(json.dumps({"error": "Roblox connection failed."}))
        raise SystemExit(1)
