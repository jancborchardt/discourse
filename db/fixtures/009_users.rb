# kind of odd, but we need it, we also need to nuke usage of User from inside migrations
#  very poor form
user = User.find_by("id <> -1 and username_lower = 'system'")
if user
  user.username = UserNameSuggester.suggest("system")
  user.save
end

User.seed do |u|
  u.id = -1
  u.name = "system"
  u.username = "system"
  u.username_lower = "system"
  u.email = "no_email"
  u.password = SecureRandom.hex
  u.active = true
  u.admin = true
  u.moderator = true
  u.approved = true
  u.trust_level = TrustLevel[4]
end

UserOption.where(user_id: -1).update_all(
  email_private_messages: false,
  email_direct: false
)

Group.user_trust_level_change!(-1, TrustLevel[4])


ColumnDropper.drop(
  table: 'users',
  after_migration: 'AddUserAuthTokens',
  columns:  %w[
      email_always
      mailing_list_mode
      email_digests
      email_direct
      email_private_messages
      external_links_in_new_tab
      enable_quoting
      dynamic_favicon
      disable_jump_reply
      edit_history_public
      automatically_unpin_topics
      digest_after_days
      auto_track_topics_after_msecs
      new_topic_duration_minutes
      last_redirected_to_top_at
      auth_token
      auth_token_updated_at ],
  on_remove: ->(){
    STDERR.puts 'Removing superflous users columns!'
  }
)

# User for the smoke tests
if ENV["SMOKE"] == "1"
  smoke_user = User.seed do |u|
    u.id = 0
    u.name = "smoke_user"
    u.username = "smoke_user"
    u.username_lower = "smoke_user"
    u.email = "smoke_user@discourse.org"
    u.password = "P4ssw0rd"
    u.active = true
    u.approved = true
    u.approved_at = Time.now
    u.trust_level = TrustLevel[3]
  end.first

  UserOption.where(user_id: smoke_user.id).update_all(
    email_direct: false,
    email_digests: false,
    email_private_messages: false,
  )

  EmailToken.where(user_id: smoke_user.id).update_all(confirmed: true)
end

