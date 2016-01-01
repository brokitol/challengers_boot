#!/usr/bin/env ruby

require_relative 'bot'


argument = {} 
ARGV.each do |a|
  argument[a.intern] = true
end

argument[:affiche_log] = true

bot = Bot.new('/home/bot/config/skynet', argument)
bot.run
