#!/usr/bin/env python3
"""Expande colecciones del Workshop de L4D2 (app 550) a IDs de fichero."""
from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request

API = "https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/"
COLLECTION_FILETYPE = 2


def collection_details(ids: list[str]) -> list[dict]:
    data: dict[str, str | int] = {"collectioncount": len(ids)}
    for i, pid in enumerate(ids):
        data[f"publishedfileids[{i}]"] = pid
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(API, data=body, method="POST")
    with urllib.request.urlopen(req, timeout=45) as resp:
        payload = json.load(resp)
    return payload.get("response", {}).get("collectiondetails") or []


def expand(root_ids: list[str]) -> list[str]:
    queue = [str(i).strip() for i in root_ids if str(i).strip()]
    files: list[str] = []
    seen: set[str] = set()
    while queue:
        batch: list[str] = []
        while queue and len(batch) < 20:
            item_id = queue.pop(0)
            if item_id in seen:
                continue
            seen.add(item_id)
            batch.append(item_id)
        if not batch:
            continue
        try:
            details = collection_details(batch)
        except Exception as exc:  # noqa: BLE001 — fallback: bajar los IDs tal cual
            print(f"expand-workshop: API falló ({exc}); se usan IDs sin expandir", file=sys.stderr)
            files.extend(batch)
            continue
        got = {str(item.get("publishedfileid", "")): item for item in details}
        for item_id in batch:
            item = got.get(item_id) or {}
            children = item.get("children") or []
            if item.get("result") != 1 or not children:
                files.append(item_id)
                continue
            for child in children:
                child_id = str(child.get("publishedfileid", "")).strip()
                if not child_id:
                    continue
                if int(child.get("filetype", 0)) == COLLECTION_FILETYPE:
                    queue.append(child_id)
                elif child_id not in seen:
                    seen.add(child_id)
                    files.append(child_id)
    # estable y sin duplicados
    return list(dict.fromkeys(files))


if __name__ == "__main__":
    ids = expand(sys.argv[1:])
    sys.stdout.write("\n".join(ids))
    if ids:
        sys.stdout.write("\n")
