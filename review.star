load("github.com/repokitteh/modules/lib/utils.star", "react")


def _review(comment_id, action, sender, command):
  if action != 'created':
    return

  if not github_repo_is_collaborator(sender):
    react(comment_id, '%s is not a collaborator, thus allowed to assign users.' % sender)
    return

  users = command.args

  if not users:
    react(comment_id, 'no reviewer specified, a PR author cannot be assigned as a reviewer.')
    return

  nopes = [user for user in users if not github_repo_is_collaborator(user)]

  if len(nopes) == 1:
    react(comment_id, '%s cannot be assigned as a reviewer to this issue.' % nopes[0])
  elif len(nopes) > 1:
    react(comment_id, 'neither of %s can be assigned as a reviewer to this issue.' % ', '.join(nopes))
  else:
    github_pr_request_review(*users)
    react(comment_id, None)


def _unreview(comment_id, action, sender, command):
  if action != 'created':
    return

  if not github_repo_is_collaborator(sender):
    react(comment_id, '%s is not a collabrator, thus allowed to remove reviewers.' % sender)
    return

  users = command.args

  if not users:
    # no arguments -> assume sender.
    users.append(sender)

  github_pr_remove_reviewer(*users)
  react(comment_id, None)


command(name='review', func=_review)
command(name='unreview', func=_unreview)
