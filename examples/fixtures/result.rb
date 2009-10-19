# Expected result. Options are
# :ignore => [\Aalt:\],
# :replace => {/\A(ws:)(.*)/ => '\2'}
# :eol => "\n",
# :dir_meta => 'meta.yml'

SvnFixture.repo('result') do
  revision(1, 'Create articles directory',
           :date => Time.parse("2009-01-01")) do
    dir 'articles'
  end
  
  revision 2, 'Create articles about computers and philosophy' do
    dir 'articles' do
      prop 'ws:title', 'Articles'
      
      file 'philosophy.txt' do
        body '---\ntitle: Philosophy\npublished_at: 2009-07-01 12:00:00\n\---\n\nMy philosophy is to eat a lot of salsa!'
      end
      
      file 'computers.txt' do
        body '---\ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\nComputers do not like salsa so much.'
      end
    end
  end
  
  revision 3, 'Change text of articles, with different newline styles', :author => "author" do
    dir 'articles' do
      file 'philosophy.txt' do
        body '---\ntitle: Philosophy\npublished_at: 2009-07-01 12:00:00\n\---\n\nMy philosophy is \n\nto eat a lot of salsa!\n'
      end
      
      file 'computers.txt' do
        body '---\ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\nComputers do not \n\nlike salsa so much.'
      end
    
      file 'old-apple.txt' do
        body "One line.\n  Two line.\n"
      end
    end
  end
  
  revision 4, 'Add some YAML props' do
    dir 'articles' do
      file 'philosophy.txt' do
        body '---\ntitle: New Philosophy\npublished_at: 2009-07-01 12:00:00\n---\n\nMy philosophy is \n\nto eat a lot of salsa!\n'
      end
      
      file 'computers.txt' do
        body '---\neol: CRLF\ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much.'
      end
    end
  end
  
  revision 5, 'Add a directory property' do
    dir 'articles' do
      file 'meta.yml' do
        body '---\nname: Articles\n---\n\n'
      end
    end
  end
  
  revision 6, 'Add property with different prefix' do
    dir 'articles' do
      file 'computers.txt' do
        prop 'alt:title', 'Computers'
        body '---\neol: CRLF\ntitle: Computers\npublished_at: 2009-07-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much.'
      end
    end
  end
  
  revision 7, 'Moves and copies' do
    dir 'articles' do
      move 'philosophy.txt', 'phil.txt'
      copy 'computers.txt', 'computations.txt'
    end
  end
  
  revision 8, 'Revise properties' do
    dir 'articles' do
      file 'computers.txt' do
        prop 'alt:title', 'Computers'
        body '---\neol: CRLF\ntitle: Computers\npublished_at: 2009-08-01 12:00:00\n---\n\ncomputers do not \nlike salsa so much.'
      end
    end
  end
end

SvnFixture.repo('result').commit
