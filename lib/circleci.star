load('text', 'match')


def _call(owner, repo, build_id, verb, token):
  """Makes a CircleCI API request."""

  url = 'https://circleci.com/api/v1.1/project/github/%s/%s/%d/%s?circle-token=%s' % (
    owner,
    repo,
    build_id,
    verb,
    token,
  )

  return http(secret_url=url, method='POST')


def retry(owner, repo, build_id, token):
  """Retry a specific build."""

  return _call(owner, repo, build_id, 'retry', token)


def cancel(owner, repo, build_id, token):
  """Cancel a specific build."""

  return _call(owner, repo, build_id, 'cancel', token)
