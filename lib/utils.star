def react(comment_id, err):
  if err:
    github_issue_create_comment(err)
    github_issue_create_comment_reaction(comment_id, 'confused')
  else:
    github_issue_create_comment_reaction(comment_id, '+1')
