def react(comment_id, err):
  if err:
    github.issue_create_comment(err)
    reaction = 'confused'
  else:
    reaction = '+1'

  if comment_id:
    github.issue_create_comment_reaction(comment_id, reaction)
