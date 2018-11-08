load("github.com/repokitteh/modules/lib/utils.star", "react")


# label to set when triggered.
_waiting_label = 'waiting'


def _changed():
  github_issue_unlabel(_waiting_label)


def _wait(comment_id):
  github_issue_label(_waiting_label)
  react(comment_id, None)


def on_pull_request(action):
  if action == 'synchronize':
    _changed()


# issue comment always triggered only after commands are handled.
def _issue_comment(action, commands):
  # if 'wait' command was issued in this invocation, don't attempt
  # to mark as changed.
  if 'wait' in [command.get('name') for command in commands]:
    return

  if action in ['submitted', 'created']:
    _changed()


command(name='wait', func=_wait)

issue_comment(func=_issue_comment)
pull_request_review(func=_issue_comment)
pull_request_review_comment(func=_changed)
