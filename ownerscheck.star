def _get_relevant_specs(specs):
  if not specs:
    return []

  pr_paths = [f['filename'] for f in github.pr_list_files()]

  relevant = []

  for spec in specs:
    prefix = spec["path"]

    owned_paths = [p for p in pr_paths if p.startswith(prefix)]
    if owned_paths:
      relevant.append(struct(paths=owned_paths, prefix=prefix, **spec))

  return relevant


def _get_approvers(): # -> List[str] (owners)
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

  for spec in specs:
    approved = _is_approved(spec.owner, approvers)

    print("%s -> %s" % (spec, approved))

    results.append((spec, approved))

    if spec.owner[-1] == '!':
      _update_status(spec.owner[:-1], spec.prefix, spec.paths, approved)

      if spec.label:
        if approved:
          github.issue_unlabel(spec.label)
        else:
          github.issue_label(spec.label)
    elif spec.label: # fyis
      github.issue_label(spec.label)

  return results


def _comment(config, results, force=False):
  lines = []

  for spec, approved in results:
    if approved:
      continue

    mention = spec.owner

    if mention[0] != '@':
      mention = '@' + mention

    if mention[-1] == '!':
      mention = mention[:-1]

    prefix = spec.prefix
    if prefix:
      prefix = ' for changes made to `' + prefix + '`'

    mode = spec.owner[-1] == '!' and 'approval' or 'fyi'

    key = "ownerscheck/%s/%s" % (spec.owner, spec.prefix)

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
