#!/usr/bin/env ruby

#addresse du site
URL_CHALLENGERS = 'http://challengers.mohja.fr'

require 'mechanize'
require 'logger'

# class global et point d'entré du bot
# on peut donnée des ordres manuellent au bot en appelant ses méthodes
# le bot agira plus vraisenblablement seul suite a l'appel de la méthode run()
class Bot

	# point d'entré du bot
	# @param path [String] chemin vers le fichier de configuration
	def initialize(path)
		raise "le chemin est vide" if path.nil? or path.length <= 0

		config(path)
	end

	def config(path)
		@config = YAML.load open("#{path}/ecurie.yaml")
		@global_path = path
		# TODO recrée l'arboresence de base si elle n'existe pas (sous tableau et dico)
		# pour évité les erreurs fatal suite au une tentative d'aubetenir une variable
		# vérifier a chaque fois chaque sous tab c'est chiant :p
	end

	def get_acceuil
		return connexion(@config[:login], @config[:mdp])
	end
	def get_menu
			acceuil = get_acceuil
		menu = acceuil.frame_with(:src => "./menu.php").click
	end

	def self.get_new
		return Bot.new "config/skynet"
	end

	# Se connecte au site avec le couple login/mdp reçus en params
	# @param login [String] le login
	# @param mdp [String] le mots de passe
	# @return [Mechanize::page] la page d'acceuil après s'ètre logué
	def connexion(login, mdp)
		agent = Mechanize.new
		agent.log = Logger.new "log/connexion.log"
	
		page = agent.get URL_CHALLENGERS
		form = page.form_with :id => "FORMLOGIN"
		form.field_with(:id => "challenger_login").value = login
		form.field_with(:id => "challenger_pwd").value = mdp
	
		return agent.submit form
	end
end
