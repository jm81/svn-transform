# For text PropsToYaml for Directories

SvnFixture.repo('dir_props') do
  revision(1, 'create dirs') do
    dir 'noprops'
    
    dir 'svnprops' do
      prop 'one', 'o'
      prop 'two', 't'
    end
    
    dir 'yamlprops' do
      file 'meta.yml' do
        body "---\none: yaml\n"
      end
    end
    
    dir 'bothprops' do
      prop 'one', 'o'
      
      file 'meta.yml' do
        body "---\none: yaml\ntwo: yaml"
      end
    end
  end
  
end

SvnFixture.repo('dir_props').commit
