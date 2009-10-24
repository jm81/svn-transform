require 'micronaut'
require 'svn-transform'

def not_in_editor?
  !(ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM'))
end

Micronaut.configure do |c|
  c.color_enabled = not_in_editor?
  c.filter_run :focused => true
end

def (SvnTransform::File).example
  SvnTransform::File.new(
    '/path/to/file.txt', # Actually a Pathname
    ['body of file', {'prop:svn' => 'property value'}],
    10,
    {'svn:author' => 'me'}
  )
end

def (SvnTransform::Dir).example
  SvnTransform::Dir.new(
    '/path/to/dir', # Actually a Pathname
    [{'entry.txt' => nil}, {'prop:svn' => 'property value'}],
    10,
    {'svn:author' => 'me'},
    :repos, # Actually a Svn::Ra::Session
    :fixture_dir
  )
end
