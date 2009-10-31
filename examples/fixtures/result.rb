=begin
Expected result. Transform are
@transform.file_transform(
  SvnTransform::Transform::PropsToYaml,
  [['ws:tags', 'topics'], [/\Aws:(.*)\Z/, '\1']]
)
@transform.dir_transform(
  SvnTransform::Transform::PropsToYaml,
  [['ws:tags', 'topics'], [/\Aws:(.*)\Z/, '\1']] # TODO tags aren't tested
)
@transform.file_transform(
  SvnTransform::Transform::Newline
)
@transform.file_transform(
  SvnTransform::Transform::Extension,
  :txt => :md
)
=end

SvnFixture.repo('result') do
  revision(1, 'Create articles directory',
           :date => Time.parse("2009-01-01")) do
    dir 'articles'
  end
  
  revision 2, 'Create articles about computers and philosophy', :date => '2009-01-02' do
    dir 'articles' do
      file 'meta.yml' do
        body "--- \ntitle: Articles\n"
      end
      
      file 'philosophy.md' do
        body "--- \ntitle: Philosophy\npublished_at: 2009-07-01 12:00:00\n\---\n\nMy philosophy is to eat a lot of salsa!"
      end
      
      file 'computers.md' do
        body "--- \ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\nComputers do not like salsa so much."
      end
    end
  end
  
  revision 3, 'Change text of articles, with different newline styles', :author => "author", :date => '2009-01-03' do
    dir 'articles' do
      file 'philosophy.md' do
        body "--- \ntitle: Philosophy\npublished_at: 2009-07-01 12:00:00\n\---\n\nMy philosophy is \n\nto eat a lot of salsa!\n"
      end
      
      file 'computers.md' do
        body "--- \ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\nComputers do not \n\nlike salsa so much."
      end
    
      file 'old-apple.md' do
        body "One line.\n  Two line.\n"
      end
    end
  end
  
  revision 4, 'Add some YAML props', :date => '2009-01-04' do
    dir 'articles' do
      file 'philosophy.md' do
        # Subversion property overrides new yaml prop (TODO is this ideal?)
        body "--- \ntitle: Philosophy\npublished_at: 2009-07-01 12:00:00\n---\n\nMy philosophy is \n\nto eat a lot of salsa!\n"
      end
      
      file 'computers.md' do
        prop 'todelete', 'delete this'
        body "--- \ntitle: Computers\neol: CRLF\npublished_at: 2009-07-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much."
      end
    end
  end
  
  revision 5, 'Add a directory property', :date => '2009-01-05' do
    dir 'articles' do
      file 'meta.yml' do
        body "--- \nname: Articles\ntitle: Articles\n"
      end
    end
  end
  
  revision 6, 'Add property with different prefix', :date => '2009-01-06' do
    dir 'articles' do
      file 'computers.md' do
        prop 'alt:title', 'Computers'
        propdel 'todelete'
        body "--- \ntitle: Computers\neol: CRLF\npublished_at: 2009-07-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much."
      end
    end
  end
  
  revision 7, 'Moves and copies', :date => '2009-01-07' do
    dir 'articles' do
      move 'philosophy.md', 'phil.md'
      copy 'computers.md', 'computations.md'
    end
  end
  
  revision 8, 'Revise properties', :date => '2009-01-08' do
    dir 'articles' do
      file 'computers.md' do
        prop 'alt:title', 'Computers'
        body "--- \ntitle: Computers\neol: CRLF\npublished_at: 2009-08-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much."
      end
    end
  end
end

SvnFixture.repo('result').commit
