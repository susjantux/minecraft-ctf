#!/usr/bin/env python3
import base64
import sys

print(" Book of the Old Sage ")
print("[*] The Librarian villager adjusts his glasses and examines your runes...")

if len(sys.argv) < 2:
    print("Usage: python3 book_of_wisdom.py <base64_encoded_text>")
    sys.exit(1)

runes = sys.argv[1]
try:
    answer = base64.b64decode(runes).decode('utf-8')
    print(f"[+] The deciphered text reads: {answer}")
except Exception as e:
    print("[-] This makes no sense... Are these even real runes?")
