#!/usr/bin/env python3
"""
grok_bridge.py — Send a message to your live Grok conversation and
automatically append both the user message and Grok's full reply to
grok_conversation.md.

SETUP (one-time):
  Kill your current Chrome and relaunch it with remote debugging enabled:

    google-chrome --remote-debugging-port=9222 --profile-directory=Default &

  Then log into grok.com and open your conversation. After that, just run:

    python3 grok_bridge.py "Your message to Grok here"

  Or run with no args for interactive prompt mode.
"""

import sys
import re
import time
import datetime
from pathlib import Path
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout

# ── Config ──────────────────────────────────────────────────────────────────
CONVO_MD = Path(__file__).parent / "grok_conversation.md"
REMOTE_DEBUG_URL = "http://localhost:9222"
GROK_URL_PATTERN = "*://grok.com/*"
RESPONSE_TIMEOUT_MS = 120_000   # 2 minutes max wait for Grok reply
POLL_INTERVAL_S = 1.5           # How often to check if response is done
STABLE_WAIT_S = 4               # Seconds of no DOM change = response complete
# ────────────────────────────────────────────────────────────────────────────


def count_messages_in_md(path: Path) -> int:
    """Count the highest message number already recorded in the .md file."""
    if not path.exists():
        return 0
    pattern = re.compile(r"^## Message (\d+)", re.MULTILINE)
    matches = pattern.findall(path.read_text(encoding="utf-8"))
    return max((int(m) for m in matches), default=0)


def append_message(path: Path, number: int, role: str, content: str) -> None:
    """Append a formatted message block to the conversation file."""
    icon = "👤 User (You)" if role == "user" else "🤖 Grok"
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    block = f"\n## Message {number} — {icon}\n\n{content.strip()}\n\n---\n"
    with path.open("a", encoding="utf-8") as f:
        f.write(block)
    print(f"[grok_bridge] Appended Message {number} ({role}) to {path.name}")


def get_grok_page(playwright):
    """Connect to the existing Chrome session and find the Grok tab."""
    try:
        browser = playwright.chromium.connect_over_cdp(REMOTE_DEBUG_URL)
    except Exception as e:
        print(f"\n❌ Could not connect to Chrome on port 9222.\n"
              f"   Make sure Chrome is running with --remote-debugging-port=9222\n"
              f"   Error: {e}")
        sys.exit(1)

    # Find the Grok tab
    for context in browser.contexts:
        for page in context.pages:
            if "grok.com" in page.url and "/share/" not in page.url:
                print(f"[grok_bridge] Found Grok tab: {page.url}")
                return browser, page

    print("❌ No interactive Grok tab found (skipped shared URLs). Please open grok.com in Chrome first.")
    sys.exit(1)


def send_message(page, message: str) -> None:
    """Type and submit a message in the Grok chat input."""
    # Try common Grok input selectors
    selectors = [
        "textarea[placeholder]",
        "div[contenteditable='true']",
        "textarea",
        "[data-testid='chat-input']",
        ".chat-input textarea",
    ]

    input_el = None
    for sel in selectors:
        try:
            el = page.wait_for_selector(sel, timeout=5000)
            if el:
                input_el = el
                print(f"[grok_bridge] Found input via: {sel}")
                break
        except PlaywrightTimeout:
            continue

    if not input_el:
        # Fallback: click the visible area and use keyboard
        print("[grok_bridge] Falling back to click-based input...")
        page.click("body")
        page.keyboard.press("Tab")

    # Clear any existing text, type the message
    input_el.click()
    input_el.fill("")
    input_el.type(message, delay=20)
    time.sleep(0.3)

    # Submit — try Enter key (Grok uses Shift+Enter for newline, Enter to send)
    input_el.press("Enter")
    print(f"[grok_bridge] Message sent: {message[:80]}{'...' if len(message)>80 else ''}")


def wait_for_response(page) -> str:
    """
    Wait until Grok finishes generating its response.
    Strategy: poll the last assistant message's text length until it
    stops growing for STABLE_WAIT_S seconds.
    """
    print("[grok_bridge] Waiting for Grok response", end="", flush=True)

    # JavaScript to grab the last bot response text
    js_get_last_response = """
    () => {
        // Grok renders messages in article/div blocks — grab the last one
        // that is NOT a user bubble
        const all = document.querySelectorAll(
            '[data-message-author-role="assistant"], ' +
            '.message-bubble.assistant, ' +
            'article:last-child, ' +
            '[data-testid="response-message"]:last-child'
        );
        if (!all.length) return '';
        return all[all.length - 1].innerText || '';
    }
    """

    start = time.time()
    last_length = -1
    stable_since = None

    while time.time() - start < RESPONSE_TIMEOUT_MS / 1000:
        try:
            text = page.evaluate(js_get_last_response)
        except Exception:
            text = ""

        current_length = len(text)

        if current_length > 0 and current_length != last_length:
            # Still growing
            last_length = current_length
            stable_since = time.time()
            print(".", end="", flush=True)
        elif current_length > 0 and stable_since is not None:
            # Text exists and hasn't changed
            if time.time() - stable_since >= STABLE_WAIT_S:
                print(" ✅")
                return text.strip()

        time.sleep(POLL_INTERVAL_S)

    print(" ⚠️ Timeout — capturing whatever is there")
    try:
        return page.evaluate(js_get_last_response).strip()
    except Exception:
        return "(Could not capture response — check Chrome manually)"


def main():
    # Get the message from args or prompt
    if len(sys.argv) > 1:
        user_message = " ".join(sys.argv[1:])
    else:
        print("What do you want to say to Grok?")
        user_message = input("> ").strip()
        if not user_message:
            print("No message entered. Exiting.")
            sys.exit(0)

    # Figure out next message numbers
    last_num = count_messages_in_md(CONVO_MD)
    user_num = last_num + 1
    grok_num = last_num + 2

    print(f"\n[grok_bridge] Conversation file: {CONVO_MD}")
    print(f"[grok_bridge] Next messages will be #{user_num} (you) and #{grok_num} (Grok)\n")

    with sync_playwright() as pw:
        browser, page = get_grok_page(pw)

        # Append user message immediately
        append_message(CONVO_MD, user_num, "user", user_message)

        # Send to Grok
        send_message(page, user_message)

        # Wait for and capture response
        response = wait_for_response(page)

        # Append Grok's reply
        if response:
            append_message(CONVO_MD, grok_num, "grok", response)
            print(f"\n✅ Done! Messages #{user_num} and #{grok_num} saved to {CONVO_MD.name}")
            print(f"\n── Grok said (first 300 chars) ──────────────────")
            print(response[:300] + ("..." if len(response) > 300 else ""))
        else:
            print("⚠️ No response captured. Check the Grok tab manually.")

        browser.close()


if __name__ == "__main__":
    main()
