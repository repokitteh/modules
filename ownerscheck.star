# specs: [(owner, prefix, mode)]
# returns: [(owner, prefix, [path])]
def _get_relevant_specs(specs):
  if not specs:
    return []
    
  pr_paths = [f['filename'] for f in github.pr_list_files()]

  relevant = []

  for owner, prefix in specs:
    owned_paths = [p for p in pr_paths if p.startswith(prefix)]
    if owned_paths:
      relevant.append((owner, prefix, owned_paths))

  return relevant


# returns: list(owner)
def _get_approvers():
  reviews = github.pr_list_reviews()

  return [r['user']['login'] for r in reviews if r['state'] == 'APPROVED']


def _is_approved(owner, approvers):
  if owner[-1] == '!':
    owner = owner[:-1]

  required = [owner]

  if '/' in owner:
    # this is a team, parse it.
    team_id = github.team_get_by_name(owner.split('/')[1])['id']
    required = [m['login'] for m in github.team_list_members(team_id)]

  return any([any([a for a in approvers if a == r]) for r in required])


def _update_status(owner, prefix, paths, approved):
  github.create_status(
    state=approved and 'success' or 'pending',
    context='rk:ownerscheck:%s' % prefix,
    description='%s must approve changes to %s' % (owner, prefix),
  )


def _reconcile(config):
  specs = _get_relevant_specs(config.get('paths', []))

  if not specs:
    return

  approvers = _get_approvers()

  results = []

  for owner, prefix, paths in specs:
    approved = _is_approved(owner, approvers)

    results.append((owner, prefix, paths, approved))

  for owner, prefix, paths, approved in results:
    if owner[-1] == '!':
      _update_status(owner, prefix, paths, approved)

  return results


def _reconcile_and_comment(config):
  results = _reconcile(config)

  lines = []

  for owner, prefix, paths, approved in results:
    if approved:
      continue

    if owner[0] != '@':
      owner = '@' + owner

    if prefix:
      prefix = ' for changes made to `' + prefix + '`'

    if owner[-1] == '!':
      lines.append('CC %s: Your approval is needed%s.' % (owner, prefix))
    else:
      lines.append('CC %s: FYI only%s.' % (owner, prefix))

  github.issue_create_comment('\n'.join(lines))


def _pr(action, config):
  if action != 'synchronize':
    return

  _reconcile_and_comment(config)


def _pr_review(action, review_state, config):
  if action != 'submitted' or not review_state:
    return

  _reconcile(config)


handlers.pull_request(func=_pr)
handlers.pull_request_review(func=_pr_review)

handlers.command(name='checkowners', func=_reconcile)
handlers.command(name='checkowners!', func=_reconcile_and_comment)
