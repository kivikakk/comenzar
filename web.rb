# frozen_string_literal: true
# typed: strict

SPIDER = T.let(spider do
  free(:i).qsp("https://google.com/search?hl=en&tbm=isch", :q)
  free(:sw).replace("https://en.wiktionary.org/wiki/{query}#Spanish", space: "_")
  free(:auslan).replace("https://find.auslan.fyi/search?query={query}")
  free(:enes).replace("https://translate.google.com/?source=osdd&sl=en&tl=es&text={query}&op=translate")
  free(:esen).replace("https://translate.google.com/?source=osdd&sl=es&tl=en&text={query}&op=translate")

  static(:adc).redirect("https://adc.hrzn.ee")
  static(:ynab).redirect("https://app.youneedabudget.com/")
  static(:ing).redirect("https://www.ing.com.au/securebanking/")
  static(:"28d").redirect("https://servicecentre.latitudefinancial.com.au/login")

  static(:hi, :hello, :hey, :heya, :chewwo, :yawonk, :hola, :howdy).message(<<~HTML)
   Chewwo!!!! <span class='bunnywave'></span>
  HTML
end, Spider)
