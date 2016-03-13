class Talent
  include Mongoid::Document
  include Mongoid::Timestamps
  include WowArmory::Constants

  field :remote_id, :type => Integer
  field :name, :type => String
  field :tier, :type => Integer
  field :column, :type => Integer
  field :icon, :type => String
  field :spec, :type => String

  index({remote_id: 1}, {unique: true})

  def as_json(options={})
    json = { 
      :oid => remote_id,
      :id => remote_id,
      :n => name,
      :i => icon,
      :tier => "#{tier}",
      :column => "#{column}",
      :spec => spec
    }
  end

  def self.populate()

    begin
      talents = WowArmory::Talents.new('US','legion')
      talents.talents.each do |spec,spec_talents|
        spec_talents.each do |talent|
          db_item = Talent.find_or_initialize_by({:remote_id => talent[:spell].to_i, :spec => spec})
          db_item.name = talent[:name]
          db_item.icon = talent[:icon]
          db_item.tier = talent[:tier].to_i
          db_item.column = talent[:column].to_i
          db_item.spec = spec
          if db_item.new_record?
            db_item.save()
          end
        end
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end
end
