import sys
import urllib.request
import urllib.parse
import json
import re

def fetch_duckduckgo(query):
    url = 'https://lite.duckduckgo.com/lite/'
    data = urllib.parse.urlencode({'q': query}).encode('utf-8')
    req = urllib.request.Request(
        url, 
        data=data, 
        headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Content-Type': 'application/x-www-form-urlencoded'
        }
    )
    
    try:
        response = urllib.request.urlopen(req, timeout=3)
        html = response.read().decode('utf-8')
        
        results = []
        
        # lite.duckduckgo.com uses a table format.
        # The title/URL is in <a rel="nofollow" href="..." class='result-link'>...</a>
        # The snippet is in <td class="result-snippet">...</td>
        
        matches = re.finditer(r'<a[^>]+href="([^"]+)"[^>]*class=[\'"]result-link[\'"][^>]*>(.*?)</a>.*?<td class=[\'"]result-snippet[\'"]>(.*?)</td>', html, re.IGNORECASE | re.DOTALL)
        
        for i, match in enumerate(matches):
            if i >= 3:
                break
                
            url = match.group(1)
            title = match.group(2).strip()
            snippet = match.group(3)
            
            # Clean up HTML tags
            snippet = re.sub(r'<[^>]+>', '', snippet).strip()
            
            # Clean up URL routing from DuckDuckGo if present
            if url.startswith('//duckduckgo.com/l/?uddg='):
                url = urllib.parse.unquote(url.split('uddg=')[1].split('&')[0])
                
            results.append({
                "name": title,
                "comment": snippet,
                "url": url
            })
            
        print(json.dumps(results))
        
    except Exception as e:
        print(json.dumps([{"name": "Error", "comment": str(e), "url": "https://duckduckgo.com"}]))

if __name__ == "__main__":
    if len(sys.argv) > 1:
        fetch_duckduckgo(sys.argv[1])
