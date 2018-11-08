def react(comment_id, err):
  if err:
    github_issue_create_comment(err)
    if comment_id:
      github_issue_create_comment_reaction(comment_id, 'confused')
  else:
    if comment_id:
      github_issue_create_comment_reaction(comment_id, '+1')
