version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'jsonapi-serializable'
  spec.version       = version
  spec.author        = 'Lucas Hosseini'
  spec.email         = 'lucas.hosseini@gmail.com'
  spec.summary       = 'Build and render JSON API resources.'
  spec.description   = 'DSL for building resource classes to be rendered by jsonapi-renderer.'
  spec.homepage      = 'https://github.com/beauby/jsonapi-serializable'
  spec.license       = 'MIT'

  spec.files         = Dir['README.md', 'lib/**/*']
  spec.require_path  = 'lib'

  spec.add_dependency 'jsonapi-renderer'
end
