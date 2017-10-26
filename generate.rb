# REST API でうまく POST できなかったので
# rails c で実行する用の ruby スクリプトを生成する(妥協)

require 'csv'

xs = []
CSV.foreach('intermediate.csv') do |r|
  xs << <<-RUBY
Issue.find(#{r[1]}).time_entries.create(user: user, hours: #{r[2]}, spent_on: '#{r[0]}')
  RUBY
end

login = ARGV[0]
puts <<-RUBY
user = User.where(login: '#{login}').first
ActiveRecord::Base.transaction do
#{xs.join}
end
RUBY
