module Admin

  module BaseHelper

    def typus_render(*args)
      options = args.extract_options!
      options[:resource] ||= @resource.to_resource

      template_file = Rails.root.join("app", "views", "admin", options[:resource], "_#{options[:partial]}.html.erb")
      resource = File.exists?(template_file) ? options[:resource] : "resources"

      render "admin/#{resource}/#{options[:partial]}", :options => options
    end

    def title(page_title)
      content_for(:title) { page_title }
    end

    def header
      render "admin/helpers/header"
    end

    def apps
      render "admin/helpers/apps"
    end

    def login_info
      unless current_user.is_a?(FakeUser)
        render "admin/helpers/login_info"
      end
    end

    def display_flash_message(message = flash)
      if message.keys.any?
        locals = { :flash_type => message.keys.first, :message => message }
        render "helpers/admin/base/flash_message", locals
      end
    end

  end

end