require "json"
require "selenium-webdriver"

@driver = Selenium::WebDriver.for :firefox
@base_url = "http://challengers.mohja.fr/"
@driver.manage.timeouts.implicit_wait = 30

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
