# Variables
BLUEPRINT_RUBY = "2.1.1"

# Helper methods
def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def copy_from_repo(filename, destination)
  repo = 'https://raw.github.com/hwrd/blueprint/master/files/'
  get repo + filename, destination
end

say 'Application Blueprint'

# Add Ruby version to Gemfile
gsub_file 'Gemfile', /source 'https:\/\/rubygems.org'/, "source 'https://rubygems.org'\nruby '#{BLUEPRINT_RUBY}'"

# Switch from Sqlite3 to Postgres
gsub_file 'Gemfile', 'sqlite3', 'pg'

gem_group :production do
  gem 'rails_12factor'
end

gem 'bootstrap-sass'
gem 'bourbon'

group :development do
  gem 'annotate', git: 'git://github.com/ctran/annotate_models.git'
end

gem 'activeadmin', github: 'gregbell/active_admin'
gem 'devise'
gem 'haml-rails'
gem "simple_form", git: "https://github.com/plataformatec/simple_form"

gem 'unicorn'
# Add Unicorn config
copy_from_repo 'common/config/unicorn.rb', 'config/unicorn.rb'

gem 'newrelic_rpm'
# Add newrelic.yml
copy_from_repo 'common/config/newrelic.yml', 'config/newrelic.yml'

# Add a Procfile
copy_from_repo 'common/Procfile', 'Procfile'

# Add a .env file for local environment variables
copy_from_repo 'common/env', '.env'

# Add .env_sample for sample local variables 
copy_from_repo 'common/env_sample', '.env_sample'

# Remove database.yml
remove_file 'config/database.yml'

# Replace with postgres friendly database.yml for local development
copy_from_repo 'common/config/database.yml', 'config/database.yml'

# Replace development database name with one extracted from application name
gsub_file "config/database.yml", /myapp/, "#{app_name.downcase}"



# Clean up Assets
# ==================================================
# Use SASS extension for application.css
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
# Remove the require_tree directives from the SASS and JavaScript files.
# It's better design to import or require things manually.
run "sed -i '' /require_tree/d app/assets/javascripts/application.js"
run "sed -i '' /require_tree/d app/assets/stylesheets/application.css.scss"
# Add bourbon to stylesheet file
run "echo >> app/assets/stylesheets/application.css.scss"
run "echo '@import \"bourbon\";' >>  app/assets/stylesheets/application.css.scss"
run "echo '@import \"bootstrap-sprockets\";' >> app/assets/stylesheets/application.css.scss"
run "echo '@import \"bootstrap\";' >> app/assets/stylesheets/application.css.scss"



# Ignore rails doc files, Vim/Emacs swap files, .DS_Store, and more
# ===================================================
run "cat << EOF >> .gitignore
/.bundle
/db/*.sqlite3
/db/*.sqlite3-journal
/log/*.log
/tmp
database.yml
doc/
*.swp
*~
.project
.idea
.secret
.DS_Store
.env
EOF"



# Run Configs and Generators
# ==================================================
run "rails g active_admin:install"
run "rails g simple_form:install --bootstrap"
run "rake db:create"
run "rake db:migrate"



# Git: Initialize
# ==================================================
git :init
git add: "."
git commit: %Q{ -m 'Initial commit' }

if yes?("Initialize GitHub repository?")
  git_uri = `git config remote.origin.url`.strip
  unless git_uri.size == 0
    say "Repository already exists:"
    say "#{git_uri}"
  else
    username = ask "What is your GitHub username?"
    run "curl -u #{username} -d '{\"name\":\"#{app_name}\", \"private\": true}' https://api.github.com/user/repos"
    git remote: %Q{ add origin git@github.com:#{username}/#{app_name}.git }
    git push: %Q{ origin master }
  end
end