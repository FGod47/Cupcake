import sys
import urllib.request
import urllib.parse
import json
import re

def fetch_google(query):
    url = 'https://www.google.com/search?q=' + urllib.parse.quote(query) + '&hl=en'
    req = urllib.request.Request(
        url, 
        data=None, 
        headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
        }
    )
    
    try:
        response = urllib.request.urlopen(req, timeout=3)
        html = response.read().decode('utf-8')
        
        results = []
        
        # Google search results usually have links wrapped in <a href="..."> with an <h3> title
        # We need to find standard web results
        
        # This regex looks for <h3> tags inside <a> tags
        pattern = r'<a[^>]+href="([^"]+)"[^>]*>.*?<h3[^>]*>(.*?)</h3>.*?</a>'
        matches = re.finditer(pattern, html, re.IGNORECASE | re.DOTALL)
        
        for match in matches:
            url = match.group(1)
            title = match.group(2)
            
            # Clean up HTML tags in title
            title = re.sub(r'<[^>]+>', '', title).strip()
            
            # Filter out non-http links or google internal links
            if not url.startswith('http') or 'google.com' in url or url.startswith('/'):
                continue
                
            # Try to find the snippet text just after this link block
            # Google snippets usually appear in div tags shortly after
            snippet = "Web search result"
            snippet_match = re.search(r'<div[^>]*style="-webkit-line-clamp:2"[^>]*>(.*?)</div>', html[match.end():match.end()+1000], re.IGNORECASE | re.DOTALL)
            if not snippet_match:
                snippet_match = re.search(r'<div class="VwiC3b[^>]*>(.*?)</div>', html[match.end():match.end()+1000], re.IGNORECASE | re.DOTALL)
            
            if snippet_match:
                snippet = re.sub(r'<[^>]+>', '', snippet_match.group(1)).strip()
                
            results.append({
                "name": title,
                "comment": snippet,
                "url": url
            })
            
            if len(results) >= 3:
                break
                
        print(json.dumps(results))
        
    except Exception as e:
        print(json.dumps([{"name": "Error", "comment": str(e), "url": "https://google.com"}]))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        fetch_google(sys.argv[1])
