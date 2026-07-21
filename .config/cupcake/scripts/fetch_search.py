import sys
import urllib.parse
import urllib.request
import json
import re

def fetch_search(query):
    req = urllib.request.Request(
        f"https://search.yahoo.com/search?p={urllib.parse.quote(query)}",
        headers={'User-Agent': 'Mozilla/5.0'}
    )
    try:
        html = urllib.request.urlopen(req, timeout=5).read().decode('utf-8')
    except Exception:
        print("[]")
        return
        
    results = []
    
    # Split by result blocks
    blocks = html.split('class="compTitle options-toggle"')[1:]
    
    for block in blocks:
        if len(results) >= 3:
            break
            
        url_match = re.search(r'href="([^"]+)"', block)
        title_match = re.search(r'<h3[^>]*>(.*?)</h3>', block, re.IGNORECASE | re.DOTALL)
        snippet_match = re.search(r'<div class="compText[^"]*">.*?<p[^>]*>(.*?)</p>', block, re.IGNORECASE | re.DOTALL)
        
        if not (url_match and title_match and snippet_match):
            continue
            
        url = url_match.group(1)
        title = re.sub(r'<[^>]+>', '', title_match.group(1)).strip()
        snippet = re.sub(r'<[^>]+>', '', snippet_match.group(1)).strip()
        
        if '/RU=' in url:
            url = url.split('/RU=')[1].split('/RK=')[0]
            url = urllib.parse.unquote(url)
            
        domain = urllib.parse.urlparse(url).netloc
        icon_url = f"https://icons.duckduckgo.com/ip3/{domain}.ico" if domain else "web-browser"
        
        results.append({
            "name": title,
            "comment": snippet,
            "icon": icon_url,
            "url": url
        })
        
    print(json.dumps(results))
    
if __name__ == '__main__':
    fetch_search(sys.argv[1] if len(sys.argv) > 1 else "1 tb ssd")
