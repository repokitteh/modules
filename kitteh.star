def _kitteh():
  resp = http("http://aws.random.cat/meow", timeout=5)
  if resp["status_code"] == 200:
    url = resp["json"].get("file")
    if not url:
      error("invalid response from server: %s" % resp)
    github_issue_create_comment("![meow](%s)" % url)
  else:
    error("request failed: %s" % resp)

command(name='kitteh', func=_kitteh)
