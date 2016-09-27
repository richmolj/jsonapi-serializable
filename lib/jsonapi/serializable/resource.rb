require 'jsonapi/serializable/link'
require 'jsonapi/serializable/relationship'

module JSONAPI
  module Serializable
    class Resource
      class << self
        attr_accessor :type_val, :type_block, :id_block, :attribute_blocks,
                      :relationship_blocks, :link_blocks, :meta_val, :meta_block

        # @overload type(value)
        #   Declare the JSON API type of this resource.
        #   @param [String] value The value of the type.
        #
        #   @example
        #     type 'users'
        #
        # @overload type(value)
        #   Declare the JSON API type of this resource.
        #   @yieldreturn [String] The value of the type.
        #
        #   @example
        #     type { @user.admin? ? "admin" : "users" }
        def type(value = nil, &block)
          self.type_val = value
          self.type_block = block
        end

        # Declare the JSON API id of this resource.
        #
        # @yieldreturn [String] The id of the resource.
        #
        # @example
        #   id { @user.id.to_s }
        def id(&block)
          self.id_block = block
        end

        # @overload meta(value)
        #   Declare the meta information for this resource.
        #   @param [Hash] value The meta information hash.
        #
        #   @example
        #     meta key: value
        #
        # @overload meta(&block)
        #   Declare the meta information for this resource.
        #   @yieldreturn [String] The meta information hash.
        #   @example
        #     meta do
        #       { key: value }
        #     end
        def meta(value = nil, &block)
          self.meta_val = value
          self.meta_block = block
        end

        # Declare an attribute for this resource.
        #
        # @param [Symbol] name The key of the attribute.
        # @yieldreturn [Hash, String, nil] The block to compute the value.
        #
        # @example
        #   attribute(:name) { @user.name }
        def attribute(name, &block)
          attribute_blocks[name] = block
        end

        # Declare a relationship for this resource. The properties of the
        #   relationship are set by providing a block in which the DSL methods
        #   of +JSONAPI::Serializable::Relationship+ are called.
        # @see JSONAPI::Serializable::Relationship
        #
        # @param [Symbol] name The key of the relationship.
        #
        # @example
        #   relationship :posts do
        #     data { @user.posts.map { |p| PostResource.new(post: p) } }
        #   end
        #
        # @example
        #   relationship :author do
        #     data do
        #       @post.author && UserResource.new(user: @post.author)
        #     end
        #     linkage_data do
        #       { type: 'users', id: @post.author_id }
        #     end
        #     link(:self) do
        #       "http://api.example.com/posts/#{@post.id}/relationships/author"
        #     end
        #     link(:related) do
        #       "http://api.example.com/posts/#{@post.id}/author"
        #     end
        #     meta do
        #       { author_online: @post.author.online? }
        #     end
        #   end
        def relationship(name, &block)
          relationship_blocks[name] = block
        end

        # Declare a link for this resource. The properties of the link are set
        #   by providing a block in which the DSL methods of
        #   +JSONAPI::Serializable::Link+ are called, or the value of the link
        #   is returned directly.
        # @see JSONAPI::Serialiable::Link
        #
        # @param [Symbol] name The key of the link.
        # @yieldreturn [Hash, String, nil] The block to compute the value, if
        #   any.
        #
        # @example
        #   link(:self) do
        #     "http://api.example.com/users/#{@user.id}"
        #   end
        #
        # @example
        #    link(:self) do
        #      href "http://api.example.com/users/#{@user.id}"
        #      meta is_self: true
        #    end
        def link(name, &block)
          link_blocks[name] = block
        end
      end

      self.attribute_blocks = {}
      self.relationship_blocks = {}
      self.link_blocks = {}

      def self.inherited(klass)
        super
        klass.attribute_blocks = attribute_blocks.dup
        klass.relationship_blocks = relationship_blocks.dup
        klass.link_blocks = link_blocks.dup
      end

      def initialize(param_hash = {})
        param_hash.each { |k, v| instance_variable_set("@#{k}", v) }
        @_id = instance_eval(&self.class.id_block)
        @_type = self.class.type_val || instance_eval(&self.class.type_block)
        @_meta = if self.class.meta_val
                   self.class.meta_val
                 elsif self.class.meta_block
                   instance_eval(&self.class.meta_block)
                 end
        @_attributes = {}
        @_relationships = self.class.relationship_blocks
                              .each_with_object({}) do |(k, v), h|
          h[k] = Relationship.new(param_hash, &v)
        end
        @_links = self.class.link_blocks.each_with_object({}) do |(k, v), h|
          h[k] = Link.as_jsonapi(param_hash, &v)
        end
      end

      def as_jsonapi(params = {})
        hash = {}
        hash[:id] = @_id
        hash[:type] = @_type
        attr = attributes(params[:fields] || self.class.attribute_blocks.keys)
        hash[:attributes] = attr if attr.any?
        rels = relationships(params[:fields] || @_relationships.keys,
                             params[:include] || [])
        hash[:relationships] = rels if rels.any?
        hash[:links] = @_links if @_links.any?
        hash[:meta] = @_meta unless @_meta.nil?

        hash
      end

      def jsonapi_type
        @_type
      end

      def jsonapi_id
        @_id
      end

      def jsonapi_related(include)
        @_relationships
          .select { |k, _| include.include?(k) }
          .each_with_object({}) { |(k, v), h| h[k] = Array(v.data) }
      end

      private

      def attributes(fields)
        self.class.attribute_blocks
            .select { |k, _| !@_attributes.key?(k) && fields.include?(k) }
            .each { |k, v| @_attributes[k] = instance_eval(&v) }
        @_attributes.select { |k, _| fields.include?(k) }
      end

      def relationships(fields, include)
        @_relationships
          .select { |k, _| fields.include?(k) }
          .each_with_object({}) do |(k, v), h|
          h[k] = v.as_jsonapi(include.include?(k))
        end
      end
    end
  end
end
