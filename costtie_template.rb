def git_commit(message)
  git add: "."
  git commit: "-n -m '#{message}'"
end

def bundle_install
  Bundler.with_unbundled_env do
    run "bundle install --jobs=4 --without="
  end
end

remove_file "Gemfile.lock"
bundle_install
git_commit "rails new"

rails_command "webpacker:install"
git_commit "rails webpacker:install"

# rspec
gem_group :test do
  gem "rspec-rails", group: :development
end
bundle_install
git_commit "add rspec-rails gem"
generate "rspec:install"
git_commit "rails g rspec:install"

# add factory_bot, faker
gem_group :test do
  gem "factory_bot_rails", group: :development
  gem "faker", group: :development
end
bundle_install
git_commit "add factory_bot_rails, faker gem"

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

# scaffold has_many :through models
#   +--------+
#   |  user  |
#   +----+---+
#        |
#   +----+----+    +-----+
#   | article |    | tag |
#   +-------+-+    +-+---+
#           |        |
#        +--+--------+-+
#        | article_tag |
#        +-------------+
#
generate :scaffold, "tag name"
generate :scaffold, "article_tag tag:references article:references"
rake "db:migrate"
inject_into_class "app/models/article.rb", "Article", <<EOF
  has_many :article_tags
  has_many :tags, through: :article_tags
EOF
inject_into_class "app/models/tag.rb", "Tag", <<EOF
  has_many :article_tags
  has_many :articles, through: :article_tags
EOF
git_commit "scaffold Tag, ArticleTag"

# localize
inject_into_file "config/application.rb", <<EOF, after: "config.load_defaults 6.1\n"
    config.time_zone = "Asia/Tokyo"
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}").to_s]
    config.i18n.default_locale = :ja
EOF
run "curl -o config/locales/ja.yml -L https://raw.githubusercontent.com/svenfuchs/rails-i18n/master/rails/locale/ja.yml"
git_commit "localize to japan"
