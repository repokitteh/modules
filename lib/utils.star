def react(comment_id, err):
  """Reacts on a specific comment."""

  if err:
    github.issue_create_comment(err)
    reaction = 'confused'
  else:
    reaction = '+1'

  if comment_id:
    github.issue_create_comment_reaction(comment_id, reaction)
