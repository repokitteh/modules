# specs: [(owner, prefix, label?)]
# returns: [(owner, prefix, [path], label?)]
def _get_relevant_specs(specs):
  if not specs:
    return []

  pr_paths = [f['filename'] for f in github.pr_list_files()]

  relevant = []

  for spec in specs:
    if type(spec) == "list":
      owner, prefix = spec
      label = None
    else:
      owner, prefix, label = spec["owner"], spec["path"], spec.get("label")

    owned_paths = [p for p in pr_paths if p.startswith(prefix)]
    if owned_paths:
      relevant.append((owner, prefix, owned_paths, label))

  return relevant


# returns: list(owner)
def _get_approvers():
  reviews = [{'login': r['user']['login'], 'state': r['state']} for r in github.pr_list_reviews()]

  print("reviews=%s" % reviews)

  return [r['login'] for r in reviews if r['state'] == 'APPROVED']


def _is_approved(owner, approvers):
  if owner[-1] == '!':
    owner = owner[:-1]

  required = [owner]

  if '/' in owner:
    team_name = owner.split('/')[1]

    # this is a team, parse it.
    team_id = github.team_get_by_name(team_name)['id']
    required = [m['login'] for m in github.team_list_members(team_id)]

    print("team %s(%d) = %s" % (team_name, team_id, required))

  for r in required:
    if any([a for a in approvers if a == r]):
      print("approver: %s" % r)
      return True

  return False


def _update_status(owner, prefix, paths, approved):
  github.create_status(
    state=approved and 'success' or 'pending',
    context='%s must approve' % owner,
    description='changes to %s' % (prefix or '/'),
  )


def _reconcile(config):
  specs = _get_relevant_specs(config.get('paths', []))

  print("specs: %s" % specs)

  if not specs:
    return []

  approvers = _get_approvers()

  print("approvers: %s" % approvers)

  results = []

  for owner, prefix, paths, label in specs:
    approved = _is_approved(owner, approvers)

    results.append((owner, prefix, paths, label, approved))

  print("results: %s" % results)

  for owner, prefix, paths, label, approved in results:
    if owner[-1] == '!':
      _update_status(owner[:-1], prefix, paths, approved)

      if label:
        if approved:
          github.issue_unlabel(label)
        else:
          github.issue_label(label)

  return results


def _comment(config, results, force=False):
  lines = []

  for owner, prefix, paths, approved, label in results:
    if approved:
      continue

    mention = owner

    if mention[0] != '@':
      mention = '@' + mention

    if mention[-1] == '!':
      mention = mention[:-1]

    if prefix:
      prefix = ' for changes made to `' + prefix + '`'

    mode = owner[-1] == '!' and 'approval' or 'fyi'

    key = "ownerscheck/%s/%s" % (owner, prefix)

    if (not force) and (store_get(key) == mode):
      mode = 'skip'
    else:
      store_put(key, mode)

    if mode == 'approval':
      lines.append('CC %s: Your approval is needed%s.' % (mention, prefix))
    elif mode == 'fyi':
      lines.append('CC %s: FYI only%s.' % (mention, prefix))

  if lines:
    github.issue_create_comment('\n'.join(lines))

def _reconcile_and_comment(config):
  _comment(config, _reconcile(config))

def _force_reconcile_and_comment(config):
  _comment(config, _reconcile(config), force=True)

def _pr(action, config):
  if action in ['synchronize', 'opened']:
    _reconcile_and_comment(config)


def _pr_review(action, review_state, config):
  if action != 'submitted' or not review_state:
    return

  _reconcile(config)


handlers.pull_request(func=_pr)
handlers.pull_request_review(func=_pr_review)

handlers.command(name='checkowners', func=_reconcile)
handlers.command(name='checkowners!', func=_force_reconcile_and_comment)
