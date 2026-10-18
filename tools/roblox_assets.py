"""Upload this project's PNG artwork using .env, without logging credentials.

Official API: https://create.roblox.com/docs/cloud/guides/usage-assets
Uploads require explicit CLI arguments; merely importing this module does no IO.
"""
import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
API = "https://apis.roblox.com/assets/v1/"


def api_key():
    for line in (ROOT / ".env").read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"^\s*(?:export\s+)?(roblox_api|ROBLOX_API_KEY)\s*=\s*(.*)$", line)
        if match:
            value = match[2].strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]
            if value:
                return value
    raise ValueError("Configure roblox_api or ROBLOX_API_KEY in the ignored .env file.")


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # Never forward the credential to a redirect destination.


def request(path, key, body=None, content_type=None):
    if not re.fullmatch(r"(?:assets|operations)(?:/[A-Za-z0-9-]+)?", path):
        raise ValueError("Unexpected asset API path.")
    headers = {"x-api-key": key}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(API + path, data=body, headers=headers)
    opener = urllib.request.build_opener(NoRedirect)
    with opener.open(req, timeout=30) as response:
        return json.load(response)


def upload(path, name, creator, key, result_path):
    content = path.read_bytes()
    if path.suffix.lower() != ".png" or not content.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError("Only PNG project artwork is supported.")
    if len(content) > 20 * 1024 * 1024:
        raise ValueError("PNG exceeds the asset API limit.")
    metadata = {"assetType": "Image", "displayName": name,
                "description": "Original Glide & Grab stud UI illustration.",
                "creationContext": {"creator": {"userId": str(creator)}, "expectedPrice": 0}}
    boundary = "GlideGrab" + uuid.uuid4().hex
    chunks = [
        f'--{boundary}\r\nContent-Disposition: form-data; name="request"\r\nContent-Type: application/json\r\n\r\n'.encode(),
        json.dumps(metadata).encode(),
        f'\r\n--{boundary}\r\nContent-Disposition: form-data; name="fileContent"; filename="icon.png"\r\nContent-Type: image/png\r\n\r\n'.encode(),
        content, f"\r\n--{boundary}--\r\n".encode(),
    ]
    operation = request("assets", key, b"".join(chunks), "multipart/form-data; boundary=" + boundary)
    result_path.write_text(json.dumps(operation, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"operation": operation.get("path"), "file": str(path.relative_to(ROOT))}), flush=True)
    # Poll the acknowledged operation only. Never repeat a create request on timeout.
    for _ in range(20):
        if operation.get("done"):
            return operation
        time.sleep(2)
        operation = request(operation["path"], key)
        result_path.write_text(json.dumps(operation, indent=2) + "\n", encoding="utf-8")
    return operation


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    parser.add_argument("--name", required=True)
    parser.add_argument("--creator-id", required=True, type=int)
    parser.add_argument("--result", required=True, type=Path)
    args = parser.parse_args()
    path = args.file.resolve(strict=True)
    path.relative_to(ROOT / "assets" / "ui")
    result = args.result.resolve()
    result.relative_to(ROOT / "assets" / "ui")
    key = api_key()
    try:
        operation = upload(path, args.name, args.creator_id, key, result)
        result.write_text(json.dumps(operation, indent=2) + "\n", encoding="utf-8")
        asset = operation.get("response", {})
        print(json.dumps({"done": operation.get("done"), "assetId": asset.get("assetId"),
                          "moderation": asset.get("moderationResult"), "error": operation.get("error")}))
    except urllib.error.HTTPError as error:
        # API error strings are safe after redacting the credential, if echoed.
        message = error.read(2000).decode("utf-8", errors="replace").replace(key, "[redacted]")
        print(json.dumps({"status": error.code, "message": message}), file=sys.stderr)
        return 1
    except (urllib.error.URLError, TimeoutError):
        print("Roblox connection failed; check any acknowledged operation before retrying.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
