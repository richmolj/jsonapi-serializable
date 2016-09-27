# jsonapi-serializable
Ruby gem for building and rendering [JSON API](http://jsonapi.org) resources.
Built upon the [jsonapi gem](https://github.com/beauby/jsonapi).

## Installation
```ruby
# In Gemfile
gem 'jsonapi-serializable'
```
then
```
$ bundle
```
or manually via
```
$ gem install jsonapi-serializable
```

## Usage

First, require the gem:
```ruby
require 'jsonapi/serializable'
```

Then, define some resource classes:
```ruby
class PostResource < JSONAPI::Serializable::Resource
  type 'posts'

  id do
    @post.id.to_s
  end

  attribute :title do
    @post.title
  end

  attribute :date do
    @post.date
  end

  relationship :author do
    link(:self) do
      href @url_helper.link_for_rel('posts', @post.id, 'author')
      meta link_meta: 'some meta'
    end
    link(:related) { @url_helper.link_for_res('users', @post.author.id) }
    data do
      if @post.author.nil?
        nil
      else
        UserResource.new(user: @post.author, url_helper: @url_helper)
      end
    end
    meta do
      { relationship_meta: 'some meta' }
    end
  end

  meta do
    { resource_meta: 'some meta' }
  end

  link(:self) do
    @url_helper.link_for_res('posts', @post.id)
  end
end
```
Finally, build your resources from your models and render them:
```ruby
# post = some post model
# UrlHelper is some helper class
resource = PostResource.new(post: post, url_helper: UrlHelper)
document = JSONAPI.render(resource)
```

## License

jsonapi-serializable is released under the [MIT License](http://www.opensource.org/licenses/MIT).
