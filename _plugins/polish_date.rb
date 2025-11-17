module Jekyll
  module PolishDate
    MONTHS = {
      "January" => "stycznia",
      "February" => "lutego",
      "March" => "marca",
      "April" => "kwietnia",
      "May" => "maja",
      "June" => "czerwca",
      "July" => "lipca",
      "August" => "sierpnia",
      "September" => "września",
      "October" => "października",
      "November" => "listopada",
      "December" => "grudnia"
    }

    def polish_date(input)
      date = input.is_a?(String) ? Time.parse(input) : input
      formatted = date.strftime("%d %B %Y")
      MONTHS.each { |en, pl| formatted.gsub!(en, pl) }
      formatted
    end
  end
end

Liquid::Template.register_filter(Jekyll::PolishDate)

