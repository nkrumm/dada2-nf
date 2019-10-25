import json
import urllib.request
import sys

with urllib.request.urlopen('https://api.github.com/repos/benjjneb/dada2/tags') as response:
    output = response.read().decode(response.headers.get_content_charset())
    tags = {tag['name']: tag['commit']['sha'] for tag in json.loads(output)}
    try:
        sys.stdout.write(tags[sys.argv[1]])
    except (IndexError, KeyError):
        sys.stderr.write('specify a dada2 version tag as one of [{}]\n'.format(' | '.join(sorted(tags.keys()))))
        sys.exit(1)
