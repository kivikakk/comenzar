# frozen_string_literal: true

SPIDER = spider do
  free(:i).qsp("https://google.com/search?hl=en&tbm=isch", :q)
  free(:sw).replace("https://en.wiktionary.org/wiki/{query}#Spanish", space: "_")
  free(:auslan).replace("https://find.auslan.fyi/search?query={query}")

  %w(en es ru).permutation(2).each do |sl, tl|
    free(:"#{sl}#{tl}").replace("https://translate.google.com/?source=osdd&sl=#{sl}&tl=#{tl}&text={query}&op=translate")
  end

  static(:adc).redirect("https://adc.hrzn.ee")
  static(:ynab).redirect("https://app.youneedabudget.com/")
  static(:ing).redirect("https://www.ing.com.au/securebanking/")

  static(:hi, :hello, :hey, :heya, :chewwo, :yawonk, :hola, :howdy).message(<<~HTML)
   Chewwo!!!! <span class='bunnywave'></span>
  HTML
end