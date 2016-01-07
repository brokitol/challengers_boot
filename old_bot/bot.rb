#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

#addresse du site
URL_CHALLENGERS = 'http://challengers.mohja.fr'

require 'mechanize'
require 'logger'
require_relative 'glad'

# class global et point d'entré du bot
# on peut donnée des ordres manuellent au bot en appelant ses méthodes
# le bot agira plus vraisenblablement seul suite a l'appel de la méthode run()
class Bot

	# point d'entré du bot
	# @param path [String] chemin vers le fichier de configuration
	def initialize(path, argument)
		raise "le chemin est vide" if path.nil? or path.length <= 0
#		log = argument[:log]
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

	# Cette fonction crée une nouvelle écurie avec les parametres de config
	# format réel a revoir, le mail étant en plein milieux
	# @return [Boolean] si la création a réussi ou non
	def create_ecurie
		return false unless @config[:creation][:create] == 'true'

		agent = Mechanize.new
		agent.log = Logger.new "/home/bot/log/connexion.log"
	
		page = agent.get URL_CHALLENGERS
		form = page.form_with :id => "formjoueurnew"
		form.field_with(:name => "challengerslogin").value = @config[:login]
		form.field_with(:name => "challengerspassword").value = @config[:mdp]
		form.field_with(:name => "challengersmail").value = @config[:creation][:mail]
		form.field_with(:name => "cgu").checked = true

		p = agent.submit form

		# TODO vérifie la création
		# quid du mail ?
		# TODO set le nom de l'écurie

		# si tout c'est bien passé, envoie le message configuré sur le forum
		return forum_new_sujet(@config[:creation][:message_forum][:titre], @config[:creation][:message_forum][:message])
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
		acceuil = connexion(@config[:login], @config[:mdp])
		# gestion glad
		gestion_glad(acceuil)
		# gestion clan
		# gestion écurie
		gestion_écurie(acceuil)
		#		achat hébergement
		#		gestion amélioration
	end

	def gestion_glad(acceuil)
		# commence par innitialiser les glads en faisant leur liste
		glad = Array.new
		menu = acceuil.iframe_with(:src => "./menu.php").click
		menu.links.each do |l|
			next unless l.href != nil and l.href.include? "javascript:document.formcombattant" and l.text != "*"
			glad.push get_glad l.text, acceuil, l.href.split(".")[1]
		end
		glad.each {|g| puts "#{g.modele}, #{g.nom}"}
		puts "----------"

		# achette de nouveau glad si certain manque a l'appel
		@config[:glad].each do |c|
			existe = false
			glad.each do |g|
				existe = true if c[:nom] == g.nom
			end
			achat_glad(c[:modele], acceuil, c[:nom]) unless existe
		end

		# pour chaque glad a partir du premier, le fait tourner en automatique
		glad.each {|g| g.run}
	end

	# Cette fonction retourne un objet de type gladiateur qui est initialisé a partir du nom fournit
	# @param name [String] le nom du glad
	# @return [Glad] un objet de type glad si il existe dans l'écurie courrante
	# @return [nil] nil si aucun glad ne correspond
	def get_glad(nom, acceuil, href)
		@config[:glad].each do |g|
			return Glad.new(@global_path, g[:modele], g[:nom], acceuil, href, @argument, @log_file) if g[:nom] == nom
		end
		return nil
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
		menu = acceuil.iframe_with(:src => "./menu.php").click
		ecurie = menu.link_with(:text => "Mon écurie").click
		form = ecurie.form_with(:name => "formagrandirhebergement")
		return false if form.nil?
		form.submit
		log("achat hebergement")
		return true
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
	# @return [Mechanize::page] la page d'acceuil après s'ètre logué
	def connexion(login, mdp)
		agent = Mechanize.new
		agent.log = Logger.new "/home/bot/log/connexion.log"
	
		page = agent.get URL_CHALLENGERS
		form = page.form_with :id => "FORMLOGIN"
		form.field_with(:id => "challenger_login").value = login
		form.field_with(:id => "challenger_pwd").value = mdp
	
		return agent.submit form
	end
end
