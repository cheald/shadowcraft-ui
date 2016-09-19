require 'rails_helper'

describe Character do
  let(:character) { FactoryGirl.create :character }

  describe "#outdated?" do
    context "with no data version" do
      subject { FactoryGirl.create :character, data_version: nil }
      its(:outdated?) { eq true }
    end

    context "with an old data version" do
      subject { FactoryGirl.create :character, data_version: 1 }
      its(:outdated?) { eq true }
    end

    context "with the current data version" do
      subject { FactoryGirl.create :character, data_version: Character::CURRENT_DATA_VERSION }
      its(:outdated?) { eq false }
    end
  end

  describe "#update_from_armory!" do
    before do
      stub_request(:get, %r{https://us.api.battle.net/wow/character/cenarion-circle/adrine}).to_return(:status => 200, :body => fixture("adrine.json"), :headers => {})

      [139742, 135652, 134491, 136862, 135647, 139746, 135649, 135653, 135651, 135648, 137533, 135690, 135692, 137419].each do |item_id|
        stub_request(:get, %r{https://us.api.battle.net/wow/item/#{item_id}}).to_return(:status => 200, :body => fixture("items/#{item_id}.json"), :headers => {})
      end
    end

    it "updates the character's data version" do
      expect { character.update_from_armory! true }.to change { character.data_version }.from(nil).to(Character::CURRENT_DATA_VERSION)
    end
  end
end