# == Schema Information
#
# Table name: scrums
#
#  id         :uuid             not null, primary key
#  team_id    :uuid
#  date       :date
#  points     :integer          default(0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Scrum < ActiveRecord::Base

  belongs_to :team
  has_many :entries
  has_many :players, through: :entries

  scope :today, -> { where(date: Date.today) }

  def tally
    points = 0
    cron = CronParser.new(team.summary_at)
    entries_due_at = cron.last(ActiveSupport::TimeZone.new(team.timezone).now)
    entries_due_at.change(year: date.year, month: date.month, day: date.day)

    players.uniq.map do |player|
      entries = Entry.where(scrum_id: id, player_id: player.id)
      entries = entries.where('created_at < ?', ActiveSupport::TimeZone.new(team.timezone).local_to_utc(entries_due_at))
      entries = entries.group_by { |entry| entry[:category] }

      points += 5 if entries.keys.include? 'today'
      points += 5 if entries.keys.include? 'yesterday'
    end

    update_column :points, points
    team.tally
  end

  def serialized_players
    players.uniq.map do |player|

      # Group the entries by category
      categories = Entry.where(scrum_id: id, player_id: player.id).group_by { |entry| entry[:category] }

      {
        id: player.id,
        email: player.email,
        slack_id: player.slack_id,
        name: player.name,
        real_name: player.real_name,
        points: player.points,
        categories: categories.map { |k,v| { category: k, entries: v.map { |entry| entry.slice(:body, :points) } }}
      }
    end
  end

  # FIXME: do this in a sane way
  def recipient_variables
    Hash[ *players.uniq.collect { |v| [ v.email, {name: v.name, points: v.points} ] }.flatten ]
  end

  def deliver_summary_email
    recipients = players.uniq

    to = recipients.map {|recipient| "#{recipient.real_name} <#{recipient.email}>" }

    text_path = Rails.root.join('lib/mailers/summary.text')
    text = Mustache.render(File.read(text_path), players: serialized_players)

    # TODO: Fix html template
    html_path = Rails.root.join('lib/mailers/summary.html')
    html = Mustache.render(File.read(html_path), players: serialized_players)

    # TODO: Extract the mailer methods more discretly
    RestClient.post ENV['MAILGUN_URL'],
        "from"     => "Scrum Bot <bot@astroscrum.com>",
        "to"       => to.join(','),
        "subject"  => "[Astroscrum] Summary for team #{team.name} - #{date}",
        "text"     => text,
        "html"     => html,
        "recipient-variables" => recipient_variables.to_json

  end

end
