require 'csv'
require 'pp'
 
# Dumb team class
class Team
  attr_accessor :players, :score
  def initialize( players = [], score = 0.00 )
    @players = players
    @score = score
  end
end

# Read in k/d statistics, sort by score
scores = Hash.new
CSV.open('scores_1.txt').each do |row|
  scores[row[0].to_f] = row[1].chop
end
scores = Hash[*scores.sort.reverse.flatten]

# As per PUGs / Captains games, picks are 1 2 2 1 2 1 2 ...
teams = Array.new

# Seed first three players
teams << Team.new([scores.values[0]], scores.keys[0])
teams << Team.new(scores.values[1..2], scores.keys[1] + scores.keys[2])
3.times do scores.shift end

# Alternate remaining players
scores.each_with_index do |k,i|
  teams[i%2].score = teams[i%2].score + k[0]
  teams[i%2].players  <<  k[1]
end

# Convert raw score to k/d
teams[0].score = teams[0].score / teams[0].players.size
teams[1].score = teams[1].score / teams[1].players.size

pp teams
