def git_commit(message, with_rubocop: true)
  if with_rubocop
    Bundler.with_clean_env do
      run "bundle exec rubocop -a"
    end
  end
  git add: "."
  git commit: "-n -m '#{message}'"
end

def bundle_install
  Bundler.with_clean_env do
    run "bundle install --jobs=4 --without="
  end
end

remove_file "Gemfile.lock"
bundle_install
git_commit "rails new", with_rubocop: false

# rubocop
gem_group :development do
  gem "rubocop"
  gem "onkcop"
end
bundle_install
git_commit "add rubocop gem", with_rubocop: false

Bundler.with_clean_env do
  run "bundle exec onkcop init"
  run "bundle exec rubocop -a"
end
git_commit "rubocop -a", with_rubocop: false

# pre-commit
gem_group :development do
  gem "pre-commit"
end
bundle_install
git_commit "add pre-commit gem"

Bundler.with_clean_env do
  run "bundle exec pre-commit install"
  run "bundle exec pre-commit disable yaml checks common rails"
  run "bundle exec pre-commit enable yaml checks rubocop"
end
git_commit "setup pre-commit"

# add pry
gem_group :development do
  gem "pry"
  gem "pry-byebug"
  gem "pry-doc"
  gem "pry-rails"
end
bundle_install
git_commit "add pry gems"

# add slim-rails, stylus
gem "stylus"
gem "slim-rails"
bundle_install
git_commit "add slim-rails and stylus gem"

# add unicorn
gem "unicorn"
bundle_install
create_file("config/unicorn.rb", <<EOF)
worker_processes 4
listen 3000, tcp_nopush: true
EOF
git_commit "add unicorn gem"

# rspec
gem_group :test do
  gem "rspec-rails", group: :development
end
bundle_install
git_commit "add rspec-rails gem"
generate "rspec:install"
git_commit "rails g rspec:install"

# guard
gem_group :test do
  gem "guard-rspec", group: :development
end
bundle_install
Bundler.with_clean_env do
  run "bundle exec guard init rspec"
end
git_commit "add guard-rspec gem"

# Use database with port
gsub_file "config/database.yml", /localhost/, "127.0.0.1"
git_commit "Use database with port"

# scaffold
generate :scaffold, "user name birthday:datetime"
rake "db:drop"
rake "db:create"
rake "db:migrate"
git_commit "rails g scaffold user name birthday:datetime"

# scaffold references
# has_one
generate :scaffold, "user_profile user:references gender:integer"
rake "db:migrate"
inject_into_class "app/models/user.rb", "User", <<EOF
  has_one :user_profile
EOF
git_commit "scaffold user_profile with has_one association"
# has_many
generate :scaffold, "article user:references title body:text published_at:datetime"
rake "db:migrate"
inject_into_class "app/models/user.rb", "User", <<EOF
  has_many :articles
EOF
git_commit "scaffold article with has_many association"

# redis-objects
# user has last_logged_in_at
gem "redis-objects"
bundle_install
inject_into_class "app/models/user.rb", "User", <<EOF
  include Redis::Objects
  value :last_logged_in_at
EOF
git_commit "add redis-objects gem"


# scaffold has_many :through models
#   +--------+
#   |  user  |
#   +----+---+
#        |
#   +----+----+  +--------+
#   | article |  | topics |
#   +-------+-+  +-+------+
#           |      |
#         +-+------+-+
#         |  linker  |
#         +----------+
#
generate :scaffold, "topic title"
generate :scaffold, "linker topic:references article:references"
rake "db:migrate"
inject_into_class "app/models/article.rb", "Article", <<EOF
  has_many :linkers
EOF
inject_into_class "app/models/topic.rb", "Topic", <<EOF
  has_many :linkers
  has_many :articles, through: :linkers
EOF
git_commit "scaffold topics, linkers"

# localize
inject_into_file "config/application.rb", <<EOF, after: "# config.time_zone = 'Central Time (US & Canada)'\n"
    config.time_zone = "Tokyo"
EOF
inject_into_file "config/application.rb", <<EOF, after: "# config.i18n.default_locale = :de\n"
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}").to_s]
    config.i18n.default_locale = :ja
EOF
run "curl -o config/locales/ja.yml -L https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml"
git_commit "localize to japan"
