#!/usr/bin/env ruby

require_relative 'bot_sel'

argument = {} 
argument[:affiche_log] = true
argument[:port] = 4444

current = nil
ARGV.each do |a|
	if current != nil
		argument[current] = a
		current = nil
	elsif a == "-help" or a == "--help" or a == "-h" or a == "--h"
		puts "run.rb [-port 4444]"
		exit
	elsif a == "-port"
		current = :port
	else
		argument[a.intern] = true
	end
end

#utile pour le developement mais ne fonctionne pas sur un serveur
#driver = Selenium::WebDriver.for :firefox

#fonctionne sur un serveur mais est lier a un un server selenium
caps = Selenium::WebDriver::Remote::Capabilities.htmlunit(:javascript_enabled => true)
driver = Selenium::WebDriver.for :remote, :url => "http://localhost:#{argument[:port]}/wd/hub", :desired_capabilities => caps

driver.manage.timeouts.implicit_wait = 2




bot = Bot.new('./config/skynet', argument, driver)
bot.run
