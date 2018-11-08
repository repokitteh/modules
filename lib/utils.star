def react(comment_id, err):
  github_issue_create_comment('bla')
  
  if err:
    github_issue_create_comment(err)
    reaction = '+1'
  else:
    reaction = 'confused'
  
  if comment_id:
    github_issue_create_comment_reaction(comment_id, reaction)
