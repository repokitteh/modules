load('text', 'match')

load("github.com/repokitteh/modules/lib/utils.star", "react")
load("github.com/repokitteh/modules/lib/circleci.star", "retry", "cancel")


_circleci_context_prefix = 'ci/circleci: '


def _cancel(config, repo_owner, repo_name, command):
  for arg in command.args:
    print(cancel(
      repo_owner,
      repo_name,
      int(arg),
      token=config['token'],
    ))


command(name='cancel-circle', func=_cancel, enabled=False)


def _retry(config, repo_owner, repo_name, comment_id):
  combined_status, statuses = github_get_statuses()

  if combined_status == 'pending':
    react(comment_id, ':horse: hold your horses - no failures detected, yet.')
    return
  elif combined_status == 'success':
    react(comment_id, ':woman_shrugging: nothing to rebuild.')
    return

  failed_builds = []

  for status in statuses:
    context = status['context']

    if not context.startswith(_circleci_context_prefix):
      continue

    if not status['state'] in ['error', 'failure']:
      continue

    m = match(text=status['target_url'], pattern='/([0-9]+)\?')
    if m and len(m) == 2:
      failed_builds.append((int(m[1]), context))

  if not failed_builds:
    error('combined status is %s, but no failed builds.' % combined_status)

  msgs = []
  any_err = False
  for build in failed_builds:
    build_id, context = build

    resp = retry(
      repo_owner,
      repo_name,
      build_id,
      token=config['token'],
    )

    print(build_id, resp)

    if resp['status_code'] == 200:
      msg = ':hammer: rebuilding `%s`' % context
    else:
      any_err = True
      msg = ':scream_cat: failed invoking rebuild of `%s`: %s' % (context, resp['status'])

    msgs.append(msg)

  msgs = '\n'.join(msgs)

  if any_err:
    react(comment_id, msgs)
  else:
    react(comment_id, None)
    github_issue_create_comment(msgs)


command(name='retry-circle', func=_retry)
