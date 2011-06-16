$spec_files = Dir["spec/**/*.rb"]

desc "Test specs"
task :spec do |t|
  system "bacon -q #{$spec_files.join(' ')}"
end

desc "Test specs and create coverage with rcov"
task :rcov do |t|
  system "rcov --exclude lib/spec,lib/ruby,bacon,spec/ --sort coverage --text-summary -o coverage /usr/bin/bacon -- -q #{$spec_files.join(' ')}"
end


