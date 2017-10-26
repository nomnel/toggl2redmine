require 'csv'
require 'togglv8'

# https://qiita.com/watanata/items/8619783203108d6cc433
module TogglV8::Connection
  def self.open(username=nil, password=API_TOKEN, url=nil, opts={})
    raise 'Missing URL' if url.nil?

    Faraday.new(:url => url, :ssl => {:verify => true}) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger, Logger.new('faraday.log') if opts[:log]
      faraday.adapter Faraday.default_adapter
      faraday.headers = { "Content-Type" => "application/json" }
      faraday.basic_auth username.chomp, password
    end
  end
end

class Entry
  attr_reader :date, :hours, :ticket

  def self.new_from_report(report)
    m = report['description'].match(/#(\d+)/)
    return nil unless m
    ticket = m[1]
    date = report['start'][0..9]
    hours = (report['dur'].to_f / 1000 / 60 / 60).round(2)
    new(date: date, hours: hours, ticket: ticket)
  end

  def initialize(date:, hours:, ticket:)
    @date = date
    @hours = hours
    @ticket = ticket
  end

  def +(other)
    raise if date != other.date || ticket != other.ticket
    hours = (self.hours + other.hours).round(2)
    self.class.new(date: date, hours: hours, ticket: ticket)
  end
end

toggl_api = TogglV8::API.new
workspace_id = toggl_api.my_workspaces(toggl_api.me).first['id']
reports_api = TogglV8::ReportsV2.new
reports_api.workspace_id = workspace_id

since = ARGV[0]
reports = (1..Float::INFINITY).lazy.
  map {|page| sleep 1; reports_api.details('', since: since, page: page) }.
  take_while {|xs| !xs.empty? }.
  inject(:concat)

entries = reports.
  map {|x| Entry.new_from_report(x) }.
  compact.
  group_by {|x| [x.date, x.ticket] }.
  sort_by(&:first).
  map {|_, xs| xs.inject(:+) }

CSV.open('intermediate.csv', 'w') do |w|
  entries.each do |x|
    w.puts [x.date, x.ticket, x.hours]
  end
end
