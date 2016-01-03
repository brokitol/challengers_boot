#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

#addresse du site
URL_CHALLENGERS = 'http://challengers.mohja.fr/'

require "json"
require "selenium-webdriver"

require_relative 'glad'

@driver = Selenium::WebDriver.for :firefox
@driver.manage.timeouts.implicit_wait = 30

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
	def initialize(path, argument)
		raise "le chemin est vide" if path.nil? or path.length <= 0
		log = "/home/bot/log/bot.log"
		@log_file = open(log, "a")
		@argument = argument

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
	end
=begin
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
=end
	def gestion_glad(acceuil)
		# commence par innitialiser les glads en faisant leur liste
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:css, "#menu_mes_combattants > div").click

		glad = Array.new

		# achette de nouveau glad si certain manque a l'appel
		@config[:glad].each do |c|
			if not @driver.find_element(:link, c[:nom])
				achat_glad(c[:modele], acceuil, c[:nom]) unless existe
			else
				glad.push get_glad(c)
				puts "#{c[:modele]}, #{c[:nom]}"}
		end
		puts "----------"

		# pour chaque glad a partir du premier, le fait tourner en automatique
		glad.each {|g| g.run}
	end

	# Cette fonction retourne un objet de type gladiateur qui est initialisé a partir de la config fournit
	# @param config [Array] la config du glad
	# @return [Glad] un objet de type glad si il existe dans l'écurie courrante
	def get_glad(config)
		return Glad.new(@global_path, config[:modele], config[:nom], @argument, @log_file)
	end

	# cette fonction gère l'écurie a propement parlé
	def gestion_écurie(acceuil)
		# gestion des groupe de fan
		# achat hébergement
		while achat_hébergement(acceuil);end # tourne en boucle
		# gestion des améliorations
		gestion_améliorations()
		# gestion de l'apparence
	end

	def achat_hébergement(acceuil)
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:css, "#menu_mon_ecurie > div").click
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_principale")
		@driver.find_element(:css, "form[name=\"formagrandirhebergement\"] > img").click
		#return false if form.nil?
		#log("achat hebergement")
		#return true
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
	# @return [Boolean] si l'achat est réussi ou pas
	def achat_glad(file_name, acceuil, nom)
		config = YAML.load(open("#{@global_path}/gladiateur/#{file_name}.yaml"))[:creation]
		menu = acceuil.iframe_with(:src => "./menu.php").click
		page_ecurie = menu.link_with(:href => "./ecurie_gestion.php").click
		form_creation = page_ecurie.form_with(:name => "formcreercombattant")
		return false if form_creation.nil? # imposible de créer un glad
		page_creation = form_creation.submit
		form = page_creation.form_with(:name => "formcombattantnew")
		form.combattant_nom = nom
		# TODO gérer le cas ou la somme ne convient pas
		form.Reflexe		= config[:REF]
		form.Souplesse	= config[:SOU]
		form.Puissance	= config[:PUI]
		form.Resistance	= config[:RES]
		form.Endurance	= config[:END]
		form.Energie		= config[:ENE]
		form.combattant_description = config[:description]
		form.field_with(:name => "liste_sexe").option_with(:text => config[:gender]).click
		form.field_with(:name => "liste_temperament").option_with(:text => config[:temperament]).click
		form.field_with(:name => "liste_carac_privilegiee").option_with(:text => config[:carac_privi]).click
		form.liste_bonus = config[:bonus]
		form.submit
		log("achat gladiateur #{nom}:#{file_name}")
		return true
	end

	# Se connecte au site avec le couple login/mdp reçus en params
	# @param login [String] le login
	# @param mdp [String] le mots de passe
	def connexion(login, mdp)
		@driver.get(URL_CHALLENGERS + "/index.php")
		@driver.find_element(:id, "challenger_login").clear
		@driver.find_element(:id, "challenger_login").send_keys login
		@driver.find_element(:id, "challenger_pwd").clear
		@driver.find_element(:id, "challenger_pwd").send_keys mdp
		@driver.find_element(:id, "bouton_connexion").click
	end
end
