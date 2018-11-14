load("github.com/repokitteh/modules/lib/utils.star", "react")


# waiting only for push.
_waiting_push_label = 'waiting'

# waiting for either push or comment.
_waiting_any_label = 'waiting:any'


def _wait_push(comment_id, labels):
  if _waiting_any_label in labels:
    github_issue_unlabel(_waiting_any_label)

  github_issue_label(_waiting_push_label)
  react(comment_id, None)


def _wait_any(comment_id, labels):
  if _waiting_push_label in labels:
    github_issue_unlabel(_waiting_push_label)

  github_issue_label(_waiting_any_label)
  react(comment_id, None)


# issue comment always triggered only after commands are handled.
def _issue_comment(action, commands, review_id, labels):
  if not(action in ['submitted', 'created']):
    return

  if not(_waiting_any_label in labels):
    return

  commands = commands or []

  # if in a review context, get commands from actual review.
  if review_id:
    review_body = github_pr_review(int(review_id)).get('body', '')
    commands.extend(parse_commands(review_body))

  # if 'wait' command was issued in this invocation, don't attempt
  # to mark as changed.
  if commands and any([command.get('name') in ['wait', 'wait-push', 'wait-any'] for command in commands]):
    return

  github_issue_unlabel(_waiting_any_label)


def on_pull_request(action, labels):
  if action != 'synchronize':
    return

  if _waiting_push_label in labels:
    github_issue_unlabel(_waiting_push_label)

  if _waiting_any_label in labels:
    github_issue_unlabel(_waiting_any_label)


issue_comment(func=_issue_comment)
pull_request_review(func=_issue_comment)
pull_request_review_comment(func=_issue_comment)

command(name='wait', func=_wait_push)
command(name='wait-any', func=_wait_any)
