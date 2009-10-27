# Original repository for conversion

SvnFixture.repo('original') do
  revision(1, 'Create articles directory',
           :date => Time.parse("2009-01-01")) do
    dir 'articles'
  end
  
  revision 2, 'Create articles about computers and philosophy', :date => '2009-01-02' do
    dir 'articles' do
      prop 'ws:title', 'Articles'
      
      file 'philosophy.txt' do
        prop 'ws:title', 'Philosophy'
        prop 'ws:published_at', '2009-07-01 12:00:00'
        body 'My philosophy is to eat a lot of salsa!'
      end
      
      file 'computers.txt' do
        prop 'ws:title', 'Computers'
        prop 'ws:published_at', '2009-07-01 12:00:00'
        body 'Computers do not like salsa so much.'
      end
    end
  end
  
  revision 3, 'Change text of articles, with different newline styles', :author => "author", :date => '2009-01-03' do
    dir 'articles' do
      file 'philosophy.txt' do
        body "My philosophy is \n\nto eat a lot of salsa!\n"
      end
      
      file 'computers.txt' do
        body "Computers do not \r\n\r\nlike salsa so much."
      end
    
      file 'old-apple.txt' do
        body "One line.\r  Two line.\r"
      end
    end
  end
  
  revision 4, 'Add some YAML props', :date => '2009-01-04' do
    dir 'articles' do
      file 'philosophy.txt' do
        body "---\ntitle: New Philosophy\n---\n\nMy philosophy is \n\nto eat a lot of salsa!\n"
      end
      
      file 'computers.txt' do
        body "---\r\neol: CRLF\r\n\---\r\n\r\ncomputers do not \r\nlike salsa so much."
      end
    end
  end
  
  revision 5, 'Add a directory property', :date => '2009-01-05' do
    dir 'articles' do
      prop 'ws:name', 'Articles'
    end
  end
  
  revision 6, 'Add property with different prefix', :date => '2009-01-06' do
    dir 'articles' do
      file 'computers.txt' do
        prop 'alt:title', 'Computers'
      end
    end
  end
  
  revision 7, 'Moves and copies', :date => '2009-01-07' do
    dir 'articles' do
      move 'philosophy.txt', 'phil.txt'
      copy 'computers.txt', 'computations.txt'
    end
  end
  
  revision 8, 'Revise properties', :date => '2009-01-08' do
    dir 'articles' do
      file 'computers.txt' do
        prop 'ws:published_at', '2009-08-01 12:00:00'
        prop 'alt:title', 'Computers'
      end
    end
  end
end

SvnFixture.repo('original').commit
