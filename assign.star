load("github.com/repokitteh/modules/lib/utils.star", "react")


def _assign(comment_id, action, sender, command):
  if not(action in ['created', 'opened']):
    return

  if not github.issue_check_assignee(sender):
    react(comment_id, '%s is not allowed to assign users.' % sender)
    return

  users = command.args

  if not users:
      # no arguments -> assume sender.
      users.append(sender)

  nopes = [user for user in users if not github_issue_check_assignee(user)]

  if len(nopes) == 1:
    react(comment_id, '%s cannot be assigned to this issue.' % nopes[0])
  elif len(nopes) > 1:
    react(comment_id, 'neither of %s can be assigned to this issue.' % ', '.join(nopes))
  else:
    # yay!
    github.issue_assign(*users)
    react(comment_id, None)


def _unassign(comment_id, action, sender, command):
  if action != 'created':
    return

  if not github.issue_check_assignee(sender):
    react(comment_id, '%s is not allowed to unassign users.' % sender)
    return

  users = command.args

  if not users:
    # no arguments -> assume sender.
    users.append(sender)

  github.issue_unassign(*users)
  react(comment_id, None)


command(name='assign', func=_assign)
command(name='unassign', func=_unassign)
