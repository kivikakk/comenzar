# frozen_string_literal: true

SPIDER = spider do
  free(:i).qsp("https://google.com/search?hl=en&tbm=isch", :q)
  free(:sw).replace("https://en.wiktionary.org/wiki/{query}#Spanish", space: "_")
  free(:rw).replace("https://en.wiktionary.org/wiki/{query}#Russian", space: "_")
  free(:ew).replace("https://en.wiktionary.org/wiki/{query}#Estonian", space: "_")
  free(:sv).replace("https://sonaveeb.ee/search/unif/dlall/dsall/{query}?lang=en")
  free(:auslan).qsp("https://find.auslan.fyi/search", :query)

  free(:iben).qsp("http://dict.ibs.ee/translate.cgi?language=English", :word)
  free(:ibet).qsp("http://dict.ibs.ee/translate.cgi?language=Estonian", :word)

  %w(en es ru ja et nl de).permutation(2).each do |sl, tl|
    free(:"#{sl}#{tl}").replace("https://translate.google.com/?source=osdd&sl=#{sl}&tl=#{tl}&text={query}&op=translate")
  end

  static(:adc).redirect("https://adc.hrzn.ee")
  static(:ynab).redirect("https://app.ynab.com/")
  static(:ing).redirect("https://www.ing.com.au/securebanking/")
  static(:lhv).redirect("https://www.lhv.ee/ibank/cf/portfolio/view?vi=0")

  static(:hi, :hello, :hey, :heya, :chewwo, :nyonk, :yawonk, :hola, :howdy).message(<<~HTML)
   Chewwo!!!! <span class='bunnywave'></span>
  HTML
end
