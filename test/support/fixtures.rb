::Fixtury.define do
  fixture "earth" do
    "Earth"
  end

  namespace "countries" do
    fixture "country" do
      "Country"
    end

    fixture "reverse_country", deps: :country do |store|
      store[:country].reverse
    end

    fixture "earth" do
      "Relative Earth"
    end

    fixture "relative_country", deps: %w[country earth] do |store|
      "#{store[:country]}, #{store[:earth]}"
    end

    fixture "absolute_country", deps: %w[country /earth] do |store|
      "#{store[:country]}, #{store["earth"]}"
    end

    namespace "towns" do
      fixture "unknown_town", deps: "./earth" do |deps|
        "Town, #{deps.earth}"
      end

      fixture "relative_town", deps: "../earth" do |deps|
        "Town, #{deps.earth}"
      end

      fixture "absolute_town", deps: "/earth" do |deps|
        "Town, #{deps["earth"]}"
      end
    end
  end

  namespace "masses", isolate: true do

    fixture("core") { "Earth's Core" }

    namespace "continents" do
      fixture("asia") { "Asia" }
      fixture("africa") { "Africa" }
    end

  end
end
