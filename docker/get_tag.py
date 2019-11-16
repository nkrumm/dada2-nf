import json
import urllib.request
import sys
from subprocess import run, PIPE

try:
    tag = sys.argv[1]
except IndexError:
    tag = 'v' + run(
        ['git', 'describe', '--abbrev=0'], stdout=PIPE, text=True).stdout.strip()

url = 'https://api.github.com/repos/benjjneb/dada2/tags'
with urllib.request.urlopen(url) as response:
    output = response.read().decode(response.headers.get_content_charset())
    tags = {tag['name']: tag['commit']['sha'] for tag in json.loads(output)}
    try:
        sys.stdout.write(tags[tag])
    except (IndexError, KeyError):
        sys.stderr.write('versions: [{}]\n'.format(' | '.join(sorted(tags.keys()))))
        sys.exit(1)
