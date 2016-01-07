#!/usr/bin/env ruby

require 'mechanize'
require 'logger'

class Glad

	# Cette méthode initialise un gladiateur
	def initialize(path, modele, nom, acceuil, href, argument, log_file)
		raise "le chemin est vide" if path.nil? or path.length <= 0
		raise "le modele est vide" if modele.nil? or modele.length <= 0
		raise "le nom est vide" if nom.nil? or nom.length <= 0
		raise "pas de page d'acceuil fourni" if acceuil.nil?
		raise "pas de href fourni" if href.nil?
		raise "pas de log fourni" if log_file.nil?
		@argument = argument
		@log_file = log_file
		@log_file ||= open("/home/bot/log/glad.log", 'a')

		config(path, modele, nom, acceuil, href)
	end

	def log(str)
		return if str.nil? or str.empty?

		@log_file.write str + "\n"
		puts str if @argument[:affiche_log]
	end

	# cette fonction charge les fichiers de configuration
	# elle recréer l'arboresense si besoin
	def config(path, modele, nom, acceuil, href)
		@config = YAML.load open("#{path}/gladiateur/#{modele}.yaml")
		@global_path = path
		@nom = nom
		@modele = modele
		@acceuil = acceuil
		@href = href

		# TODO recrée l'arboresence de base si elle n'existe pas (sous tableau et dico)
		# pour évité les erreurs fatal suite au une tentative d'aubetenir une variable
		# vérifier a chaque fois chaque sous tab c'est chiant :p
	end

	def get_page
		menu = @acceuil.iframe_with(:src => "./menu.php").click
		return menu.form_with(:name => @href).submit
	end

	def nom
		return @nom
	end

	def modele
		return @modele
	end

	# Cette méthode lance la gestion automatique du gladiateur
	# la gestion commence par la depense d'xp
	# puis la gestion des équipements
	# puis les missions
	# puis les tactiques
	def run
		init_current(get_page())
		competence(get_page())
		entrainement(get_page())
		equipement(get_page())
		mission(get_page())
		tactique(get_page())
	end

	# initie le dico @current avec les valeurs du gladiateur
	# cle :
	#		:REF
	#		:SOU
	#		:PUI
	#		:RES
	#		:END
	#		:ENE
	#		idem + _equipement (:REF_equipement)
	#		idem + _cost (:REF_cost)
	#		:ACT
	#		:ESQ
	#		:TOU
	#		:DEG
	#		:VIE
	#		:ARM
	#		:SUR
	#		:FAT
	#		:xp_entrainement
	def init_current(page)
		t = page.parser.text
		s = t.split("Naturelle")
		s2 = s[1].split("Modifiée")
		s3 = s2[1].split("ATTRIBUTS")
		natu = s2[0]
		modi = s3[0]
		attri = s3[1]
		natu = natu.split(" ")
		@current ||= {}
		@current[:REF] = natu[0].to_i
		@current[:SOU] = natu[1].to_i
		@current[:PUI] = natu[2].to_i
		@current[:RES] = natu[3].to_i
		@current[:END] = natu[4].to_i
		@current[:ENE] = natu[5].to_i
		modi = modi.split(" ")
		@current[:REF_equipement] = modi[0].to_i
		@current[:SOU_equipement] = modi[1].to_i
		@current[:PUI_equipement] = modi[2].to_i
		@current[:RES_equipement] = modi[3].to_i
		@current[:END_equipement] = modi[4].to_i
		@current[:ENE_equipement] = modi[5].to_i
		attri = attri.split(" ")
		@current[:ACT] = attri[0].to_i
		@current[:ESQ] = attri[1].to_i
		@current[:TOU] = attri[2].to_i
		@current[:DEG] = attri[3].to_i
		@current[:VIE] = attri[4].to_i
		@current[:ARM] = attri[5].to_i
		@current[:SUR] = attri[6].to_i
		@current[:FAT] = attri[7].to_i
		xp_entrainement = s3[1].split("A dépenser : ")[1].split(" ")[0]
		@current[:xp_entrainement] = xp_entrainement.to_i
		f = page.form_with(:name => "formentrainementreflexe"); @current[:REF_cost] = if f then f.cout.to_i else -1 end
		f = page.form_with(:name => "formentrainementsouplesse"); @current[:SOU_cost] = if f then f.cout.to_i else -1 end
		f = page.form_with(:name => "formentrainementpuissance"); @current[:PUI_cost] = if f then f.cout.to_i else -1 end
		f = page.form_with(:name => "formentrainementresistance"); @current[:RES_cost] = if f then f.cout.to_i else -1 end
		f = page.form_with(:name => "formentrainementendurance"); @current[:END_cost] = if f then f.cout.to_i else -1 end
		f = page.form_with(:name => "formentrainementenergie"); @current[:ENE_cost] = if f then f.cout.to_i else -1 end
	end

	# Cette fonction dépense l'xp des competences
	# elle change aussi les voies active en fonction des besoins de répartition d'xp
	# le choix des tactiques est prioritaire pour les voies actives si un combat a lieu le soir
	#	le tout en ce basant sur la config
	def competence(page)
	end

	# Cette fonction dépense l'xp des carac
	#	le tout en ce basant sur la config
	def entrainement(page)
		carac = @config[:objectif][:carac]
		const = [:REF, :SOU, :PUI, :RES, :END, :ENE]
		# tant que xp dispo
		suite = true
		while suite
		
			# liste des carac devant être monté (min pas attein)	
			valable = {} ; const.each {|c| valable[c] = true if @current[c] < carac[:min][c] and @current["#{c}_cost".intern] > 0 }

			# cle => :carac, value => niveaux de la carac / le facteur du ratios
			list = [] ;	const.each {|c|	list.push ({:cle => c, :value => (@current[c].to_f / carac[:ratio][c])}) if valable[c]}

			# trié la liste en fonction des valeurs pour que la première sois celle avec la plus petite valeur
			list.sort_by {|l| l[:value]}

			# monté la première carac, recommencer
			suite = false if list.length <= 0 or !boost(:carac => list.pop[:cle])
		end

		# tant que xp dispo
		suite = true
		while suite
			
			valable = {} # liste des carac pouvant monté (max pas atteind)
			const.each {|c| valable[c] = true if @current[c] < carac[:max][c] and @current["#{c}_cost".intern] > 0 }

			list = []
			# cle => :carac, value => niveaux de la carac / le facteur du ratios
			const.each {|c|	list.push ({:cle => c, :value => (@current[c].to_f / carac[:ratio][c])}) if valable[c]}

			# trié la liste en fonction des valeurs pour que la première sois celle avec la plus petite valeur
			list.sort_by {|l| l[:value]}

			# monté la première carac, recommencer
			suite = false if list.length <= 0 or !boost(:carac => list.pop[:cle])
		end
	end

	# Cette fonction fait la dépence effective des points d'xp
	# reçois le param :carac OR :comp
	# tente de dépensé des xp dans la carac ou la comp correspondante
	# return true si réussite, false sinon
	def boost(list = {})
		tab = {:REF => "reflexe", :SOU => "souplesse", :PUI => "puissance", :RES => "resistance", :END => "endurance", :ENE => "energie"}
		if list[:carac]
			f = get_page().form_with(:name => "formentrainement#{tab[list[:carac]]}")
			l = "#{@nom}\t: tentative boost #{tab[list[:carac]]} (#{@current[list[:carac]]} -> #{@current[list[:carac]] + 1})"
			if f
				old = @current[list[:carac]]
				f.submit
				init_current(get_page())
				unless old == @current[list[:carac]]
					log(l + " reussite")
					return true
				end
				log(l + " echec")
				return false
			else
				log(l + " furmulaire inexistant")
				return false
			end
		end
		return false
	end

	# Cette fonction gère les équipements du glad
	# elle tente d'avoir toujours la meilleur combinaison d'équipement possible pour le glad
	# dans la limite et selon les paramettres des config bien sur
	def equipement(page)
		#	ne prend en compte que les équipements correspondant a la config
		#	si la taille du stock ne suffit pas, le bot l'augmente => bot::gestion_écurie::stock
		#	si ene dispo
		#		regarde si un équipement est en stock et l'équipe si possible
		#		sinon regarde si un équipement est dispo a l'achat et l'achette puis l'équipe
		#	si pas d'ene dispo
		#		comparé les équipements porté et ceux dispo en stock
		#			change d'équipement si une meilleur config est trouvé
		#		comparé les équipements porté et ceux dispo a l'achat
		#			change d'équipement si une meilleur config est trouvé
	end

	# Cette fonction tente de faire les missions
	# par la suite, elle utilisera des fichiers de conf pour adapter les tactiques
	def mission(page)
	end

	# Cette fonction change et adapte les tactiques du gladiateur
	# elle utilisera des fichiers de conf et la situation actuel pour crée la tactique la plus adapté
	# elle peut aussi changer les voies actives si besoin et est prioritaire sur la repartition des xp si un combat a lieu le soir
	#	quid des tournoi et CDC ?
	# !! elle appel la fonction message() et exploite sont rendu comme ordre prioritaire de tactique
	def tactique(page)
		# format simple
		# tactique prédéfinie
		# seul les ciblages change en fonction des paramètres

		# format complexe
		# ensemble de réaction possible classé par importance
		# pour chaque réaction des conditions de mise en place (exemple : un pareur en face)
		# les ciblages (% et carac) sont ajusté en fonction du combat
		# les valeur de soin et au comp de protection sont ajusté pour en minimiser le nombre
		# la tactique final peut donc varier du tout au tout en deux combat
	end

	# Cette fonction gère les envois et reception de message
	# cela consiste en 2 partie
	# 	- les taunts. Petit message auto pioché aléatoirement dans une liste
	# 		voir possibilité de réglage plus fin (celon résultat du précédent match par exemple)
	# 	- les messages tactique. c-a-d réception d'un ordre de tactique a travers les messages d'équipe
	# 		et envois d'un acusé de réçeption.
	def message(page)
	end
end
