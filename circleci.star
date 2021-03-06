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


handlers.command(name='cancel-circle', func=_cancel, enabled=False)


def _retry(config, repo_owner, repo_name, comment_id):
  combined = github.get_combined_statuses()

  combined_state, statuses = combined['state'], combined['statuses']

  if combined_state == 'pending':
    react(comment_id, ':horse: hold your horses - no failures detected, yet.')
    return
  elif combined_state == 'success':
    react(comment_id, ':woman_shrugging: nothing to rebuild.')
    return

  failed_builds = []

  for status in statuses:
    context = status['context']

    if not context.startswith(_circleci_context_prefix):
      continue

    if not status['state'] in ['error', 'failure']:
      continue

    target_url = status['target_url']

    m = match(text=target_url, pattern='/([0-9]+)\?')
    if m and len(m) == 2:
      failed_builds.append((int(m[1]), target_url, context))

  if not failed_builds:
    error('combined status is %s, but no failed builds.' % combined_state)

  msgs = []
  any_err = False
  for build in failed_builds:
    build_id, target_url, context = build

    resp = retry(
      repo_owner,
      repo_name,
      build_id,
      token=config['token'],
    )

    print(build_id, resp)

    if resp['status_code'] == 200:
      msg = ':hammer: rebuilding `%s` ([failed build](%s))' % (context, target_url)
    else:
      any_err = True
      msg = ':scream_cat: failed invoking rebuild of `%s`: %s' % (context, resp['status'])

    msgs.append(msg)

  msgs = '\n'.join(msgs)

  if any_err:
    react(comment_id, msgs)
  else:
    react(comment_id, None)
    github.issue_create_comment(msgs)


handlers.command(name='retry-circle', func=_retry)
