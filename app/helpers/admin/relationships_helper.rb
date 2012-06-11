module Admin

  module RelationshipsHelper

    def setup_relationship(field)
      @field = field
      @model_to_relate = @resource.reflect_on_association(field.to_sym).class_name.typus_constantize
      @model_to_relate_as_resource = @model_to_relate.to_resource
      @reflection = @resource.reflect_on_association(field.to_sym)
    end

    def typus_form_has_many(field)
      setup_relationship(field)

      @items_to_relate = @model_to_relate.where(@reflection.foreign_key => nil) - @item.send(field)

      if set_condition && @items_to_relate.any?
        form = build_relate_form
      end

      unless @reflection.through_reflection
        foreign_key = @reflection.foreign_key
      end

      options = { foreign_key => @item.id }

      build_pagination

      render "admin/templates/has_n",
             :model_to_relate => @model_to_relate,
             :model_to_relate_as_resource => @model_to_relate_as_resource,
             :foreign_key => foreign_key,
             :add_new => build_add_new(options),
             :form => form,
             :table => build_relationship_table
    end

    def typus_form_has_and_belongs_to_many(field)
      setup_relationship(field)

      @items_to_relate = @model_to_relate.all - @item.send(field)

      if set_condition && @items_to_relate.any?
        form = build_relate_form
      end

      options = { :resource => @resource.to_resource }

      build_pagination

      render "admin/templates/has_n",
             :model_to_relate => @model_to_relate,
             :model_to_relate_as_resource => @model_to_relate_as_resource,
             :add_new => build_add_new(options),
             :form => form,
             :table => build_relationship_table
    end

    def build_pagination
      options = { :order => @model_to_relate.typus_order_by, :conditions => set_conditions }
      items_per_page = @model_to_relate.typus_options_for(:per_page)
      data = @resource.unscoped.find(params[:id]).send(@field).all(options)
      @items = data.paginate(:per_page => items_per_page, :page => params[:page])
    end

    def build_relate_form
      render "admin/templates/relate_form",
             :model_to_relate => @model_to_relate,
             :items_to_relate => @items_to_relate
    end

    def build_relationship_table
      build_list(@model_to_relate,
                 @model_to_relate.typus_fields_for(:relationship),
                 @items,
                 @model_to_relate_as_resource,
                 {},
                 @reflection.macro)
    end

    def build_add_new(options = {})
      default_options = { :controller => "/admin/#{@field}", :action => "new",
                          :resource => @resource.to_resource.singularize, :resource_id => @item.id,
                          :back_to => @back_to }

      if set_condition && current_user.can?("create", @model_to_relate)
        link_to _t("Add new"), default_options.merge(options)
      end
    end

    def set_condition
      if @resource.typus_user_id? && current_user.is_not_root?
        @item.owned_by?(current_user)
      else
        true
      end
    end

    def set_conditions
      if @model_to_relate.typus_options_for(:only_user_items) && current_user.is_not_root?
        { Typus.user_fk => current_user }
      end
    end

    #--
    # TODO: Move html code to partial.
    #++
    def typus_form_has_one(field)
      html = ""

      model_to_relate = @resource.reflect_on_association(field.to_sym).class_name.typus_constantize
      model_to_relate_as_resource = model_to_relate.to_resource

      reflection = @resource.reflect_on_association(field.to_sym)
      association = reflection.macro

      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships" id="#{model_to_relate_as_resource}">
  <h2>
  #{link_to model_to_relate.model_name.human, :controller => "/admin/#{model_to_relate_as_resource}"}
  </h2>
      HTML
      items = Array.new
      items << @resource.find(params[:id]).send(field) unless @resource.find(params[:id]).send(field).nil?
      unless items.empty?
        options = { :back_to => @back_to, :resource => @resource.to_resource, :resource_id => @item.id }
        html << build_list(model_to_relate,
                           model_to_relate.typus_fields_for(:relationship),
                           items,
                           model_to_relate_as_resource,
                           options,
                           association)
      else
        message = _t("No %{resources} found.",
                     :resources => model_to_relate.model_name.human.pluralize.downcase)
        html << <<-HTML
  <div id="flash" class="notice"><p>#{message}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML

      return html
    end

    def typus_belongs_to_field(attribute, form)
      ##
      # We can only pass parameters to 'new' and 'edit'. This hack replaces
      # the current action.
      #
      params[:action] = (params[:action] == 'create') ? 'new' : params[:action]

      back_to = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id])

      related = @resource.reflect_on_association(attribute.to_sym).class_name.typus_constantize
      related_fk = @resource.reflect_on_association(attribute.to_sym).foreign_key

      if params[:action] == 'edit'
        options = { :resource => @resource.to_resource,
                    :resource_id => @item.id }
      else
        options = { :resource => @resource.to_resource }
      end

      default = { :controller => "/admin/#{related.to_resource}", :action => 'new', :back_to => back_to }

      if current_user.can?('create', related)
        message = link_to _t("Add"), default.merge(options)
      end

      render "admin/templates/belongs_to",
             :resource => @resource,
             :attribute => attribute,
             :form => form,
             :related_fk => related_fk,
             :message => message,
             :label_text => @resource.human_attribute_name(attribute),
             :values => related.order(related.typus_order_by).map { |p| [p.to_label, p.id] },
             # :html_options => { :disabled => attribute_disabled?(attribute) },
             :html_options => {},
             :options => { :include_blank => true }
    end

  end

end
