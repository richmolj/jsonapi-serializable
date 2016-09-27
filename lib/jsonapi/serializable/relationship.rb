require 'jsonapi/serializable/link'

module JSONAPI
  module Serializable
    class Relationship
      def initialize(param_hash = {}, &block)
        param_hash.each { |k, v| instance_variable_set("@#{k}", v) }
        @_param_hash = param_hash
        @_links = {}
        instance_eval(&block)
      end

      # Declare/access the data for this relationship.
      #
      # @yieldreturn [JSONAPI::Serializable::Resource,
      #               Array<JSONAPI::Serializable::Resource>,
      #               nil] The data for this relationship.
      #
      # @example
      #   data :posts do
      #     @user.posts.map { |p| PostResource.new(post: p) }
      #   end
      #
      # @example
      #   data :author do
      #     @user.author && UserResource.new(user: @user.author)
      #   end
      def data(&block)
        if block.nil?
          @_data ||= (@_data_block && @_data_block.call)
        else
          @_data_block = block
        end
      end

      # Declare the linkage data for this relationship. Useful when linkage
      #   can be computed in a more efficient way than the data itself.
      #
      # @yieldreturn [Hash] The block to compute linkage data.
      #
      # @example
      #   linkage_data do
      #     { id: @post.author_id.to_s, type: 'users' }
      #   end
      def linkage_data(&block)
        @_linkage_data_block = block
      end

      # @overload meta(value)
      #   Declare the meta information for this relationship.
      #   @param [Hash] value The meta information hash.
      #
      #   @example
      #     meta paginated: true
      #
      # @overload meta(&block)
      #   Declare the meta information for this relationship.
      #   @yieldreturn [Hash] The meta information hash.
      #
      #   @example
      #     meta do
      #       { paginated: true }
      #     end
      def meta(value = nil)
        @_meta = value || yield
      end

      # Declare a link for this relationship. The properties of the link are set
      #   by providing a block in which the DSL methods of
      #   +JSONAPI::Serializable::Link+ are called.
      # @see JSONAPI::Serialiable::Link
      #
      # @param [Symbol] name The key of the link.
      # @yieldreturn [Hash, String, nil] The block to compute the value, if any.
      #
      # @example
      #   link(:self) do
      #     "http://api.example.com/users/#{@user.id}/relationships/posts"
      #   end
      #
      # @example
      #    link(:related) do
      #      href "http://api.example.com/users/#{@user.id}/posts"
      #      meta authorization_needed: true
      #    end
      def link(name, &block)
        @_links[name] = Link.as_jsonapi(@_param_hash, &block)
      end

      def as_jsonapi(included)
        hash = {}
        hash[:links] = @_links if @_links.any?
        hash[:meta] = @_meta unless @_meta.nil?
        hash[:data] = eval_linkage_data if included && (@_linkage_data_block ||
                                                        @_data_block)

        hash
      end

      private

      def eval_linkage_data
        @_linkage_data ||=
          if @_linkage_data_block
            @_linkage_data_block.call
          elsif data.respond_to?(:each)
            data.map { |res| { type: res.jsonapi_type, id: res.jsonapi_id } }
          elsif data.nil?
            nil
          else
            { type: data.jsonapi_type, id: data.jsonapi_id }
          end
      end
    end
  end
end
