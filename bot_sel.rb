#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

#addresse du site
URL_CHALLENGERS = 'http://challengers.mohja.fr/'

require "json"
require "selenium-webdriver"
require "yaml"

require_relative 'glad_sel'

#@driver = Selenium::WebDriver.for :firefox
#@driver.manage.timeouts.implicit_wait = 30

=begin
@driver.get(@base_url + "/index.php")
@driver.find_element(:id, "challenger_login").clear
@driver.find_element(:id, "challenger_login").send_keys "skynet"
@driver.find_element(:id, "challenger_pwd").clear
@driver.find_element(:id, "challenger_pwd").send_keys "13891bob"
@driver.find_element(:id, "bouton_connexion").click
@driver.switch_to().frame("iframe_menu")
@driver.find_element(:css, "#menu_mes_combattants > div").click
@driver.find_element(:link, "T-803").click
@driver.switch_to().default_content()
@driver.switch_to().frame("iframe_principale")
@driver.find_element(:id, "link_onglet_entrainements").click
@driver.find_element(:id, "link_onglet_equipements").click

#@driver.quit
=end


# class global pour la gestion d'ecurie, les point d'entre sont initialize (init de la class) et run (execution du bot)
class Bot

	# point d'entré du bot
	# @param path [String] chemin vers le fichier de configuration
	def initialize(path, argument, driver)
		raise "le chemin est vide" if path.nil? or path.length <= 0
		raise "pas de driver" if driver.nil?
		log = "./log/bot.log"
		@log_file = open(log, "a")
		@argument = argument
		@driver = driver

		config(path)
	end

	def config(path)
		@config = YAML.load open("#{path}/ecurie.yaml")
		@global_path = path
		# TODO recrée l'arboresence de base si elle n'existe pas (sous tableau et dico)
		# pour évité les erreurs fatal suite au une tentative d'aubetenir une variable
		# vérifier a chaque fois chaque sous tab c'est chiant :p
	end

	# Cette fonction crée un nouveau sujet sur l'agora
	# @param titre [String] le titre du sujet
	# @param message [String] le message
	# @return [Boolean] si le post c'est bien passer ou non
	def forum_new_sujet(titre, message)
		# TODO
	end

	# Cette fonction lance le bot en mode automatique
	# le bot commence par achété de nouveau glad si besoin
	# il gère ensuite le clan // rien de fait pour le moment
	# il vois ensuite pour la gestion d'écurie (groupe de fan, amélioration, etc.)
	# puis il fait le tour des glad et les gères grace a la méthode run de la class Glad
	# Concrètement, c'est la class Glad qui gère les gladiateurs.
	def run
		# connection
		connexion(@config[:login], @config[:mdp])
		# gestion glad
		gestion_glad()
		# gestion clan
		# gestion écurie
		gestion_écurie()
		#		achat hébergement
		#		gestion amélioration
		@driver.quit
	end

	def gestion_glad()
		log("debut gestion glad")
		# commence par innitialiser les glads en faisant leur liste
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:css, "#menu_mes_combattants > div").click

		glad = Array.new

		# achette de nouveau glad si certain manque a l'appel
		@config[:glad].each do |c|
			log("glad suivant")
			begin
				@driver.find_element(:link, c[:nom])
  			rescue Selenium::WebDriver::Error::NoSuchElementError
				achat_glad(c[:modele], c[:nom])
			else
				glad.push get_glad(c)
				puts "#{c[:modele]}, #{c[:nom]}"
			end
		end
		puts "----------"

		# pour chaque glad a partir du premier, le fait tourner en automatique
		glad.each {|g| g.run}
		log("fin gestion glad")
	end

	# Cette fonction retourne un objet de type gladiateur qui est initialisé a partir de la config fournit
	# @param config [Array] la config du glad
	# @return [Glad] un objet de type glad si il existe dans l'écurie courrante
	def get_glad(config)
		return Glad.new(@global_path, config[:modele], config[:nom], @driver, @argument, @log_file)
	end

	# cette fonction gère l'écurie a propement parlé
	def gestion_écurie()
		# gestion des groupe de fan
		# achat hébergement
		while achat_hébergement();end # tourne en boucle
		# gestion des améliorations
		gestion_améliorations()
		# gestion de l'apparence
	end

	def achat_hébergement()
		log("tentative d'achat hebergement")
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:css, "#menu_mon_ecurie > div").click
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_principale")
		begin
			@driver.find_element(:css, "form[name=\"formagrandirhebergement\"] > img").click
		rescue
			return false
		else
			log("achat hebergement")
			return true
		end
	end

	def log(str)
		return if str.nil? or str.empty?

		@log_file.write str + "\n"
		puts str if @argument[:affiche_log]
	end

	def gestion_améliorations()
	end

	# Cette fonction répartie les groupes de fan selon les paramettres fournits
	# @param param [Array<dico>] un tableau de dico avec :nom => "le nom du glad" et :nb_groupe => "le nombre de groupe de fan"
	# @return [Boolean] si l'affectation a réussi ou pas
	def repartition_fan_groupe
	end

	# Cette fonction achette un nouveau équipement dont le nom est passé en parametre
	# elle est appeler par les glads directements quant ils veullent un équipement non en stock
	# c'est fonction achette toute seul des slots de stockage si besoin (ce qui peut entrainé l'echec de l'achats par manque de fond)
	# @param name [String] le nom de l'équipement
	# @return [Boolean] si l'achat est réussi ou pas
	def achat_equipement
	end

	# Cette fonction achette un nouveau glad en utilisant les paramettres fournit
	# @param path [String] le chemin vers le fichier yaml décrivant le glad
	# @param path [nom] le nom du glad
	# @return [Boolean] si l'achat est réussi ou pas
	def achat_glad(file_name, nom)

		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:css, "#menu_mon_ecurie > div").click
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_principale")
		@driver.find_element(:css, "div.tableau_td_formulaire > span").click
		@driver.switch_to().alert().accept()

		config = YAML.load(open("#{@global_path}/gladiateur/#{file_name}.yaml"))[:creation]

		tmp = @driver.find_element(:name, "combattant_nom"); tmp.clear; tmp.send_keys nom
		log(nom)
		# TODO gérer le cas ou la somme ne convient pas
		tmp = @driver.find_element(:name, "Reflexe");				tmp.clear; tmp.send_keys config[:REF]
		tmp = @driver.find_element(:name, "Souplesse");				tmp.clear; tmp.send_keys config[:SOU]
		tmp = @driver.find_element(:name, "Puissance");				tmp.clear; tmp.send_keys config[:PUI]
		tmp = @driver.find_element(:name, "Resistance");			tmp.clear; tmp.send_keys config[:RES]
		tmp = @driver.find_element(:name, "Endurance");				tmp.clear; tmp.send_keys config[:END]
		tmp = @driver.find_element(:name, "Energie");				tmp.clear; tmp.send_keys config[:ENE]
		tmp = @driver.find_element(:name, "combattant_description"); tmp.clear; tmp.send_keys config[:description]
		Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "liste_sexe")).select_by(:text, config[:gender])
		Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "liste_temperament")).select_by(:text, config[:temperament])
		Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "liste_carac_privilegiee")).select_by(:text, config[:carac_privi])
		#Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "liste_bonus")).select_by(:text, config[:bonus]) #TODO revoir les valeur de ce choix 
		log("achat gladiateur #{nom}:#{file_name}")
		@driver.find_element(:id, "Bouton_valider").click
		@driver.switch_to().alert().accept()
		return true
	end

	# Se connecte au site avec le couple login/mdp reçus en params
	# @param login [String] le login
	# @param mdp [String] le mots de passe
	def connexion(login, mdp)
		@driver ||= Selenium::WebDriver.for :firefox
		@driver.get(URL_CHALLENGERS + "/index.php")
		@driver.find_element(:id, "challenger_login").clear
		@driver.find_element(:id, "challenger_login").send_keys login
		@driver.find_element(:id, "challenger_pwd").clear
		@driver.find_element(:id, "challenger_pwd").send_keys mdp
		@driver.find_element(:id, "bouton_connexion").click
	end
end
