#!/usr/bin/env ruby
require "pry"

require_relative "channel"
require_relative "user"
require "httparty"
require "dotenv"
Dotenv.load

class SlackError < StandardError; end

class Slack
  attr_reader :channels, :users

  def initialize()
    @channels = []
    @users = []
    get_lists
  end

  def get_lists()
    query_parameters = {
      token: ENV["SLACK_API_TOKEN"],
      pretty: 1,
    }
    url = "https://slack.com/api/conversations.list?"
    response = HTTParty.get(url, query: query_parameters)
    response["channels"].each do |x|
      @channels << Channel.new(x["name"], x["topic"]["value"], x["num_members"], x["id"])
    end
    url2 = "https://slack.com/api/users.list?"
    response2 = HTTParty.get(url2, query: query_parameters)
    response2["members"].each do |x|
      @users << User.new(x["name"], x["id"], x["real_name"])
    end
  end

  def lists_channels
    puts "\nHere are the channels:"
    @channels.each do |x|
      puts "   - #{x.name}"
    end
    puts "---\n"
  end

  def lists_users
    puts "\nHere are the users:"
    @users.each do |x|
      puts "   - #{x.user_name}"
    end
    puts "---\n"
  end

  def select_user(search)
    user = @users.find { |x| x.user_name.downcase == search.downcase || x.user_id.downcase == search.downcase }
  end

  def select_channel(search)
    channel = @channels.find { |x| x.name.downcase == search.downcase || x.slack_id.downcase == search.downcase }
  end

  def self.send_msg(recipient, text)
    if recipient == nil
      puts "Please select a channel or user first."
      main
    end

    url = "https://slack.com/api/chat.postMessage"
    if recipient.class == Channel
      query_parameters = {
        token: ENV["SLACK_API_TOKEN"],
        channel: recipient.slack_id,
        text: text,
      }
    elsif recipient.class == User
      query_parameters = {
        token: ENV["SLACK_API_TOKEN"],
        channel: recipient.user_id,
        text: text,
      # as_user: true, <-- use this in the future for allowing to send as a user
      }
    end

    response = HTTParty.post(url,
                             headers: {"Content-Type" => "application/x-www-form-urlencoded"},
                             query: query_parameters)
    if response["ok"]
      return true
    else
      raise SlackError, "Error when posting '#{text}' to #{recipient}, error: #{response["error"]}"
    end
  end
end

def main
  slack = Slack.new

  puts "Welcome to the Kasey-Elle Slack CLI!
There are #{slack.channels.length} channels and #{slack.users.length} members in this instance of Slack."

  def name_checker(who)
    while who == ""
      puts "Please enter a valid name/ID."
      who = gets.chomp
    end
  end

  def options
    puts "What should we do next? You can:
    list channels / list users / select user / select channel / show details / send message / quit"
    return gets.chomp
  end

  continue = true

  chosen_user = ""
  while (continue)
    response = options
    case response
    when "list channels"
      slack.lists_channels
    when "list users"
      slack.lists_users
    when "select user"
      puts "Enter the name or ID of the user you wish to select."
      who = gets.chomp
      name_checker(who)
      chosen_user = slack.select_user(who)
      puts "That user was not found. Please check your spelling or try another selection." if chosen_user == nil
    when "select channel"
      puts "Enter the name or ID of the channel you wish to select."
      who = gets.chomp
      name_checker(who)
      chosen_user = slack.select_channel(who)
      puts "That channel was not found. Please try again." if chosen_user == nil
    when "show details"
      if chosen_user == "" || chosen_user == nil
        puts "Please select a channel or user first."
      else
        chosen_user.details
      end
    when "send message"
      puts "What message would you like to send?"
      text = gets.chomp
      Slack.send_msg(chosen_user, text)
    when "quit"
      continue = false
    else
      puts "Oops! That is not a valid option. Please try again."
    end
  end

  puts "Thank you for using the Kasey-Elle Slack CLI"
end

main if __FILE__ == $PROGRAM_NAME

# NOTE for Elle: Run ruby lib/slack.rb from slack-cli folder to run the CLI program.
