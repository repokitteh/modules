def _doge():
  resp = http("https://random.dog/woof", timeout=5)
  if resp["status_code"] == 200:
    url = "https://random.dog/%s" % resp["body"]
    github_issue_create_comment("![woof](%s)" % url)
  else:
    error("request failed: %s" % resp)

command(name='doge', func=_doge)
