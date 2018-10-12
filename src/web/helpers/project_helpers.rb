module ProjectHelpers

  include EmailHelpers
  include GithubHelpers
  include FabricHelpers

  def import_project(import_context)
    # save project
    if Project.project_not_exist?(import_context[:github_project_id])
      puts "Persisting project #{import_context[:github_project_id]} by user"
      DB.transaction do
        project = Project.create(name: import_context[:name],
                                 created_at: Time.now,
                                 owner: import_context[:owner],
                                 img: import_context[:img],
                                 secret: SecureRandom.hex,
                                 symbol: SecureRandom.hex,
                                 eth_account: Digest::SHA1.hexdigest(import_context[:github_project_id]),
                                 first_word: import_context[:first_word],
                                 custom_name: import_context[:custom_name],
                                 token_name: import_context[:token_name],
                                 discuss_method: import_context[:discuss_method],
                                 github_project_id: import_context[:github_project_id])
        User[current_user.id].add_project(project)
      end
    end


    project = Project.get_by_github_project_id(import_context[:github_project_id])
    import_context[:id] = project.id
    import_context[:token_name] = project.id
    import_context[:secret] = project.secret
    import_context[:symbol] = project.symbol
    import_context[:eth_account] = project.eth_account
    import_context[:init_supply] = project.init_supply
    # register webhook
    # register_webhook import_context

    # init hyper ledger and create a special event in github_events
    # so that we can get the detail of the event by block chain transaction id
    # bc_resp = init_ledger import_context
    GithubEvent.insert(github_delivery_id: project.symbol,
                       github_event: PROJECT_IMPORT_EVENT,
                       sender_login: current_user.login,
                       sender_id: current_user.id,
                       repository_name: project.name,
                       repository_id: project.github_project_id,
                       repository_full_name: project.name,
                       repository_owner_login: current_user.login,
                       repository_owner_id: current_user.id,
                       received_at: Time.now,
                       # payload: bc_resp.to_s,
                       # transaction_id: bc_resp['transactionId'],
                       processing_time: Time.now,
                       processing_state: WEBHOOK_EVENT_STATUS_PERSISTED)

    # send email to other member from project
    import_context[:import_user] = current_user.name
    # send_project_import_email(import_context, current_user)

    true
  end

end