#!/usr/bin/env ruby

require_relative 'bot_sel'

driver = Selenium::WebDriver.for :firefox
driver.manage.timeouts.implicit_wait = 30

argument = {} 
ARGV.each do |a|
  argument[a.intern] = true
end

argument[:affiche_log] = true

bot = Bot.new('./config/skynet', argument, driver)
bot.run
