# name: discourse-anonymous-categories
# about: Always-anonymous categories for Discourse
# version: 0.5.1
# authors: Communiteq
# url: https://github.com/communiteq/discourse-anonymous-categories

enabled_site_setting :anonymous_categories_enabled

after_initialize do

  require_dependency 'category'
  require_dependency 'guardian'
  require_dependency 'site_setting'
  require_dependency 'user'
  require_dependency 'anonymous_shadow_creator'
  require_dependency 'new_post_result'
  require_dependency 'post_creator'

  class ::Category
      after_save :reset_anonymous_categories_cache

      protected
      def reset_anonymous_categories_cache
        ::Guardian.reset_anonymous_categories_cache
      end
  end

  class ::Guardian
    @@anonymous_categories_cache = DistributedCache.new("anonymous_categories")

    def self.reset_anonymous_categories_cache
      @@anonymous_categories_cache["allowed"] =
        begin
          Set.new(
            CategoryCustomField
              .where(name: "force_anonymous_posting", value: "true")
              .pluck(:category_id)
          )
        end
    end
  end

  class ::AnonymousShadowCreator
    def get_bypass_sitesettings()
      return unless user
      return if SiteSetting.must_approve_users? && !user.approved?

      shadow = user.shadow_user

      if shadow && (shadow.post_count + shadow.topic_count) > 0 &&
          shadow.last_posted_at &&
          shadow.last_posted_at < SiteSetting.anonymous_account_duration_minutes.minutes.ago
          shadow = nil
      end

      shadow || create_shadow!
    end
  end

  @anon_handler = lambda do |manager|
    if !SiteSetting.anonymous_categories_enabled
      return nil
    end

    args = manager.args
    return nil if args[:whisper] == "true"

    # Note that an uncategorized topic post comes through as an empty category
    # rather than category "1".  We need to special case this for now...
    category_id = args[:category]
    category_id = SiteSetting.uncategorized_category_id.to_s if category_id.blank?

    # Have to figure out what category the post is in to see if it needs to be
    # anonymized.
    category = Category.find(category_id)

    if category.custom_fields["force_anonymous_posting"] != "true"
      return nil
    end

    user = manager.user
    creator = AnonymousShadowCreator.new(user)
    anon_user = creator.get_bypass_sitesettings()

    # The client-side UI seems to get upset if the returned post was made by
    # "another" user, and will refuse to clear the field.
    # We leverage the route_to functionality to explicitly route back to the post.
    # It also happens to give us an opportunity to point out that the post has been
    # automatically anonymized!
    #
    result = NewPostResult.new(:create_post)
    creator = PostCreator.new(anon_user, args)

    post = creator.create
    result.check_errors_from(creator)

    if result.success?
      result.post = post
      result.message = "Your post has been anonymized."
      result.route_to = "/t/#{post.topic.slug}/#{post.topic.id}/#{post.post_number}"
    else
      user.flag_linked_posts_as_spam if creator.spam?
    end

    return result
  end

  # NewPostManager doesn't get to see if it's a whisper if we don't pass it
  add_permitted_post_create_param("whisper")
  NewPostManager.add_handler(&@anon_handler)

end
