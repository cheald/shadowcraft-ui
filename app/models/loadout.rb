class Loadout
  include Mongoid::Document
  embedded_in :character, :inverse_of => :loadout
  INV_MAIN_HAND = "16"
  INV_OFF_HAND = "17"
  EXPERTISE_RATINGS = [
    0.090185798704624, 0.090185798704624,  0.090185798704624,  0.090185798704624, 0.090185798704624,
    0.090185798704624, 0.090185798704624, 0.090185798704624,  0.090185798704624,  0.090185798704624,
    0.135278999805450, 0.180371999740601, 0.225464999675751,  0.270556986331940,  0.315649002790451,
    0.360742002725601, 0.405835002660751, 0.450928002595901,  0.496021002531052,  0.541113972663879,
    0.586206972599030, 0.631299972534180, 0.676392972469330,  0.721485972404480,  0.766578972339630,
    0.811671972274780, 0.856764018535614, 0.901856005191803,  0.946949005126953,  0.992042005062103,
    1.037140011787415, 1.082229971885681, 1.127320051193237,  1.172410011291504,  1.217509984970093,
    1.262599945068359, 1.307690024375916, 1.352789998054504,  1.397879958152771,  1.442970037460327,
    1.488059997558594, 1.533159971237183, 1.578250050544739,  1.623340010643005,  1.668439984321594,
    1.713529944419861, 1.758620023727417, 1.803709983825684,  1.848809957504272,  1.893900036811829,
    1.938989996910095, 1.984089970588684, 2.029180049896240,  2.074270009994507,  2.119359970092773,
    2.164459943771362, 2.209549903869629, 2.254640102386475,  2.299740076065063,  2.344830036163330,
    2.433870077133179, 2.529949903488159, 2.633919954299927,  2.746799945831299,  2.869790077209473,
    3.004309892654419, 3.152060031890869, 3.315099954605103,  3.495929956436157,  3.697609901428223,
    3.978460073471069, 4.280630111694336, 4.605750083923340,  4.955570220947266,  5.331960201263428,
    5.736929893493652, 6.172669887542725, 6.641499996185303,  7.145939826965332,  7.688690185546875,
   10.095899581909180, 13.257599830627441, 17.416299819946289, 22.868499755859375, 30.027200698852539
  ]

  # field :gear, :type => Hash
  field :talents, :type => Hash
  field :glyphs, :type => Hash
  field :gear, :type => Hash
  field :stats, :type => Hash

  references_many :items

  field :agi, :type => Integer
  field :attack_power, :type => Integer

  # Ratings
  field :crit_rating, :type => Integer
  field :hit_rating, :type => Integer
  field :expertise_rating, :type => Integer
  field :haste_rating, :type => Integer
  field :mastery_rating_rating, :type => Integer

  # before_save :sum_stats

  private

  def stat(key, val)
    stats[key] = (stats[key] || 0) + val.to_i
  end

  def sum_stats
    # Sum stats from gear (without gems)
#    self.stats = {}
#    items.each do |item|
#      item.properties.keys.grep(/bonus/).each do |bonus|
#        key = bonus.gsub(/^bonus/, "").snake_case
#        stat key, item.properties[bonus]
#      end
#    end

    # Sum stats from gems

    # Sum stats from talents

    # TODO: Add race weapon specializations

    stat "mainhand_expertise", stats["expertise"] || 0
    stat "offhand_expertise", stats["expertise"] || 0

    mh_type = oh_type = nil
    if weapon = items.select {|i| i.remote_id == gear[INV_MAIN_HAND] }.first
      mh_type = weapon.properties["equipData"]["subclassName"]
    end
    if weapon = items.select {|i| i.remote_id == gear[INV_OFF_HAND] }.first
      oh_type = weapon.properties["equipData"]["subclassName"]
    end
  end
end
