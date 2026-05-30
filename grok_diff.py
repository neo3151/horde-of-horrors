#!/usr/bin/env python3
import sys
import os
import urllib.request
import json
import ssl
import argparse
import re

# Color constants for nice terminal output
BLUE = "\033[94m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BOLD = "\033[1m"
RESET = "\033[0m"

CACHE_DIR = os.path.expanduser("~/.config/grok_tracker")
CACHE_FILE = os.path.join(CACHE_DIR, "state.json")
HEADERS_FILE = os.path.join(CACHE_DIR, "headers.json")
CURL_FILE = os.path.join(CACHE_DIR, "curl.txt")

def load_cache():
    if not os.path.exists(CACHE_FILE):
        return {}
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

def save_cache(cache):
    os.makedirs(CACHE_DIR, exist_ok=True)
    try:
        with open(CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(cache, f, indent=2)
    except Exception as e:
        print(f"Warning: Failed to save cache: {e}", file=sys.stderr)

def parse_curl(curl_text):
    headers = {}
    cookie = None
    
    header_matches = re.findall(r'-H\s+[\'"]([a-zA-Z0-9_\-]+):\s*(.*?)[\'"]', curl_text, re.IGNORECASE)
    for name, value in header_matches:
        headers[name.strip()] = value.strip()
        if name.lower() == 'cookie':
            cookie = value.strip()
            
    cookie_match = re.search(r'-b\s+[\'"](.*?)[\'"]', curl_text)
    if cookie_match:
        cookie = cookie_match.group(1).strip()
        headers['Cookie'] = cookie
        
    return headers

def import_curl_file():
    if not os.path.exists(CURL_FILE):
        return False
    try:
        with open(CURL_FILE, "r", encoding="utf-8") as f:
            content = f.read()
        headers = parse_curl(content)
        if headers:
            os.makedirs(CACHE_DIR, exist_ok=True)
            with open(HEADERS_FILE, "w", encoding="utf-8") as out:
                json.dump(headers, out, indent=2)
            print(f"{GREEN}Successfully imported headers and cookies from {CURL_FILE}!{RESET}")
            return True
    except Exception as e:
        print(f"Error importing curl file: {e}", file=sys.stderr)
    return False

def get_headers(cli_cookie=None):
    if os.path.exists(HEADERS_FILE):
        try:
            with open(HEADERS_FILE, "r", encoding="utf-8") as f:
                headers = json.load(f)
                if cli_cookie:
                    headers['Cookie'] = cli_cookie
                return headers
        except Exception:
            pass
            
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36",
        "Accept": "application/json"
    }
    
    cookie_file = os.path.join(CACHE_DIR, "cookie.txt")
    cookie = None
    if cli_cookie:
        cookie = cli_cookie
    elif os.path.exists(cookie_file):
        try:
            with open(cookie_file, "r", encoding="utf-8") as f:
                cookie = f.read().strip()
        except Exception:
            pass
            
    if cookie:
        headers["Cookie"] = cookie
        
    return headers

def parse_input(url_or_id):
    if "grok.com/share/" in url_or_id or "x.ai/grok/share/" in url_or_id:
        share_id = url_or_id.split("share/")[-1].split("?")[0].strip("/")
        return "share", share_id
    elif "grok.com/c/" in url_or_id or "grok.com/chat/" in url_or_id:
        conv_id = url_or_id.split("/c/")[-1].split("/chat/")[-1].split("?")[0].strip("/")
        return "live", conv_id
    elif len(url_or_id.split("-")) >= 4:
        return "live", url_or_id.strip()
    else:
        return "share", url_or_id.strip()

def fetch_data(type_, id_, headers):
    if type_ == "share":
        url = f"https://grok.com/rest/app-chat/share_links/{id_}"
    else:
        url = f"https://grok.com/rest/app-chat/conversations/{id_}/responses"
        
    if type_ == "live" and "Cookie" not in headers:
        print(f"{YELLOW}Error: Live conversation tracking requires authentication headers/cookies.{RESET}", file=sys.stderr)
        print(f"Please copy a curl command for any request from grok.com and save it in:", file=sys.stderr)
        print(f"  {CURL_FILE}", file=sys.stderr)
        sys.exit(1)

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    if type_ == "live":
        headers["Referer"] = f"https://grok.com/c/{id_}"
        headers["Origin"] = "https://grok.com"
        
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            return json.loads(response.read().decode('utf-8'))
    except Exception as e:
        print(f"Error fetching data from {url}: {e}", file=sys.stderr)
        if type_ == "live":
            fallback_url = f"https://grok.com/rest/app-chat/conversations/{id_}"
            print(f"Attempting fallback to {fallback_url}...", file=sys.stderr)
            req_fallback = urllib.request.Request(fallback_url, headers=headers)
            try:
                with urllib.request.urlopen(req_fallback, context=ctx) as response:
                    return json.loads(response.read().decode('utf-8'))
            except Exception as e2:
                print(f"Fallback also failed: {e2}", file=sys.stderr)
        sys.exit(1)

def dump_to_markdown(responses, title, conv_id, filepath):
    md_content = f"# Grok Conversation: {title}\n\n"
    md_content += f"**Conversation ID:** `{conv_id}`\n"
    md_content += f"**Total Messages:** {len(responses)}\n\n---\n\n"
    
    for i, msg in enumerate(responses):
        sender = msg.get("sender", "").upper()
        content = msg.get("message", "").strip()
        
        if sender == "HUMAN":
            role_title = "👤 User (You)"
            indented_lines = "\n".join([f"> {line}" for line in content.split("\n")])
            md_content += f"## Message {i+1} — {role_title}\n\n{indented_lines}\n\n"
        else:
            role_title = "🤖 Grok"
            md_content += f"## Message {i+1} — {role_title}\n\n{content}\n\n"
            
        md_content += "---\n\n"
        
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(md_content)
        print(f"{GREEN}Successfully dumped entire conversation markdown to: {filepath}{RESET}")
    except Exception as e:
        print(f"Error writing markdown dump: {e}", file=sys.stderr)

def send_message(id_, message, headers):
    url = f"https://grok.com/rest/app-chat/conversations/{id_}/responses"
    payload = {
        "message": message,
        "modelName": "grok-3",
        "fileAttachments": [],
        "imageAttachments": []
    }
    
    # Copy headers and set content type for JSON streaming
    post_headers = headers.copy()
    post_headers["Content-Type"] = "application/json"
    post_headers["Accept"] = "text/event-stream"
    
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    req = urllib.request.Request(
        url, 
        data=json.dumps(payload).encode("utf-8"), 
        headers=post_headers, 
        method="POST"
    )
    
    print(f"{BLUE}{BOLD}Sending message...{RESET}\n")
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            print(f"{GREEN}{BOLD}--- GROK (Streaming) ---{RESET}")
            buffer = ""
            for line in response:
                decoded_line = line.decode("utf-8").strip()
                if not decoded_line:
                    continue
                if decoded_line.startswith("data:"):
                    data_str = decoded_line[5:].strip()
                    if data_str == "[DONE]":
                        break
                    try:
                        data_json = json.loads(data_str)
                        token = data_json.get("token") or data_json.get("text")
                        if token:
                            print(token, end="", flush=True)
                        elif "message" in data_json:
                            # Fallback delta logic
                            msg = data_json["message"]
                            if msg.startswith(buffer):
                                delta = msg[len(buffer):]
                                print(delta, end="", flush=True)
                                buffer = msg
                    except Exception:
                        pass
            print("\n")
    except Exception as e:
        print(f"{YELLOW}Error sending message: {e}{RESET}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Track updates to a Grok share link or live conversation.")
    parser.add_argument("url", nargs="?", help="Grok share URL, live conversation URL, or ID")
    parser.add_argument("--cookie", help="Your Grok session cookie string")
    parser.add_argument("--reset", action="store_true", help="Clear the seen message cache for this link/conversation")
    parser.add_argument("--show-all", action="store_true", help="Show all messages from the beginning without caching")
    parser.add_argument("--import-curl", action="store_true", help="Manually trigger import of curl.txt")
    parser.add_argument("--dump", metavar="FILE", help="Dump the entire conversation text to a beautifully formatted Markdown file")
    parser.add_argument("--send", help="Send a message to the tracked live conversation")
    args = parser.parse_args()

    if args.import_curl or os.path.exists(CURL_FILE):
        import_curl_file()

    cache = load_cache()

    url_input = args.url
    if not url_input:
        last_input = cache.get("_last_tracked_input")
        if last_input:
            url_input = last_input
        else:
            print("Error: No URL or ID provided, and no previously tracked session found.", file=sys.stderr)
            parser.print_help()
            sys.exit(1)

    type_, extracted_id = parse_input(url_input)
    cache["_last_tracked_input"] = url_input

    headers = get_headers(args.cookie)

    if args.send:
        if type_ != "live":
            print(f"{YELLOW}Error: Sending messages is only supported for live conversations, not share links.{RESET}", file=sys.stderr)
            sys.exit(1)
        send_message(extracted_id, args.send, headers)
        
        # Save cache state so we don't double show the user's prompt on next check
        # First fetch updated responses to get their IDs
        try:
            print("Refreshing message history cache...")
            updated_data = fetch_data(type_, extracted_id, headers)
            if isinstance(updated_data, list):
                responses = updated_data
            else:
                responses = updated_data.get("responses", [])
            seen_ids = set([r.get("responseId") for r in responses if r.get("responseId")])
            cache[extracted_id] = list(seen_ids)
            save_cache(cache)
        except Exception:
            pass
        return

    print(f"Fetching conversation updates (Mode: {type_}, ID: {extracted_id})...")
    data = fetch_data(type_, extracted_id, headers)

    
    if isinstance(data, list):
        responses = data
        title = "Live Chat Updates"
    else:
        responses = data.get("responses", [])
        title = data.get("conversation", {}).get("title", "Untitled Conversation")
    
    print(f"\n{BOLD}Conversation: {title} ({len(responses)} messages total){RESET}\n")

    if args.dump:
        dump_to_markdown(responses, title, extracted_id, args.dump)
        return

    if args.reset:
        if extracted_id in cache:
            del cache[extracted_id]
            save_cache(cache)
        print("Seen cache reset. Showing all messages:")

    seen_ids = set(cache.get(extracted_id, []))
    new_messages = []
    
    for r in responses:
        msg_id = r.get("responseId")
        if args.show_all or msg_id not in seen_ids:
            new_messages.append(r)

    if not new_messages:
        print(f"{YELLOW}No new messages since you last checked.{RESET}")
        return

    for msg in new_messages:
        sender = msg.get("sender", "").upper()
        content = msg.get("message", "").strip()
        
        if sender == "HUMAN":
            header_color = BLUE
            prefix = "YOU"
        else:
            header_color = GREEN
            prefix = "GROK"
            
        print(f"{header_color}{BOLD}--- {prefix} ---{RESET}")
        print(content)
        print()
        
        seen_ids.add(msg.get("responseId"))

    if not args.show_all:
        cache[extracted_id] = list(seen_ids)
        save_cache(cache)

if __name__ == "__main__":
    main()
