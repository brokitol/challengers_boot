#!/usr/bin/env ruby

class Glad

	# Cette méthode initialise un gladiateur
	def initialize(path, modele, nom, driver, argument, log_file)
		raise "le chemin est vide" if path.nil? or path.length <= 0
		raise "le modele est vide" if modele.nil? or modele.length <= 0
		raise "le nom est vide" if nom.nil? or nom.length <= 0
		raise "pas de driver fourni" if driver.nil?
		raise "pas de log fourni" if log_file.nil?
		@argument = argument
		@log_file = log_file
		@log_file ||= open("./log/glad.log", 'a')

		config(path, modele, nom, driver)
	end

	def log(str)
		return if str.nil? or str.empty?

		@log_file.write str + "\n"
		puts str if @argument[:affiche_log]
	end

	# cette fonction charge les fichiers de configuration
	# elle recréer l'arboresense si besoin
	def config(path, modele, nom, driver)
		@config = YAML.load open("#{path}/gladiateur/#{modele}.yaml")
		@global_path = path
		@nom = nom
		@modele = modele
		@driver = driver

		# TODO recrée l'arboresence de base si elle n'existe pas (sous tableau et dico)
		# pour évité les erreurs fatal suite au une tentative d'aubetenir une variable
		# vérifier a chaque fois chaque sous tab c'est chiant :p
	end

	def get_page
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_menu")
		@driver.find_element(:link, @nom).click
		@driver.switch_to().default_content()
		@driver.switch_to().frame("iframe_principale")
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
		#init_current(get_page())
		competence(get_page())
		#entrainement(get_page())
		#equipement(get_page())
		#mission(get_page())
		#tactique(get_page())
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
		@current ||= {}
		@current[:REF] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:SOU] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(3) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:PUI] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(4) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:RES] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(5) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:END] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(6) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:ENE] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(7) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:REF_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(2) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:SOU_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(3) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:PUI_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(4) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:RES_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(5) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:END_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(6) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:ENE_equipement] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(1) > tbody:nth-child(1) > tr:nth-child(3) > td:nth-child(7) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:ACT] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:ESQ] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(3) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:TOU] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(4) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:DEG] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(5) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:VIE] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(6) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:ARM] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(7) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:SUR] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(8) > p:nth-child(1) > font:nth-child(1)").text.to_i
		@current[:FAT] = @driver.find_element(:css, "table.combattant_infos_caracs:nth-child(3) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(9) > p:nth-child(1) > font:nth-child(1)").text.to_i

		@driver.find_element(:css, "#link_onglet_entrainements").click

		begin
			@current[:xp_entrainement] = @driver.find_element(:css, "#onglet_entrainements > table:nth-child(2) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(1)").text
		rescue
			@current[:xp_entrainement] = -1
		end
		begin
			@current[:REF_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(1) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:REF_cost] = -1
		end
		begin
			@current[:SOU_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(2) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:SOU_cost] = -1
		end
		begin
			@current[:PUI_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(3) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:PUI_cost] = -1
		end
		begin
			@current[:RES_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(4) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:RES_cost] = -1
		end
		begin
			@current[:END_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(5) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:END_cost] = -1
		end
		begin
			@current[:ENE_cost] = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(6) > form:nth-child(1) > a:nth-child(4)").text.to_i
		rescue
			@current[:ENE_cost] = -1
		end
	end

	# Cette fonction dépense l'xp des competences
	# elle change aussi les voies active en fonction des besoins de répartition d'xp
	# le choix des tactiques est prioritaire pour les voies actives si un combat a lieu le soir
	#	le tout en ce basant sur la config
	def competence(page)
		d = @driver.find_element(:css, "#onglet_voies > form:nth-child(1) > table:nth-child(2) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(5) > input:nth-child(1)")
		#@driver.find_element(:css, "form[name=\"formvoie_selection\"] > input.css_button_valider").click

		puts "[#{d.text}]"
		puts "[#{d.selected?}]"
		puts "[#{d.class}]"

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
		tab = {:REF => 1, :SOU => 2, :PUI => 3, :RES => 4, :END => 5, :ENE => 6}
		if list[:carac]
			begin
				l = "#{@nom}\t: tentative boost #{list[:carac]} (#{@current[list[:carac]]} -> #{@current[list[:carac]] + 1})"
				@driver.find_element(:css, "#link_onglet_entrainements").click
				d = @driver.find_element(:css, "table.combattant_infos_voies:nth-child(4) > tbody:nth-child(1) > tr:nth-child(2) > td:nth-child(#{tab[list[:carac]]}) > form:nth-child(1) > a:nth-child(4)")
			rescue
				log(l + " furmulaire inexistant")
				return false
			else
				old = @current[list[:carac]]
				d.click
				init_current(get_page())
				unless old == @current[list[:carac]]
					log(l + " reussite")
					return true
				end
				log(l + " echec")
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
