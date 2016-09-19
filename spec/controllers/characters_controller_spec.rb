require 'rails_helper'

describe CharactersController do
  describe "#show" do
    let!(:character) { FactoryGirl.create :character }

    before do
      stub_request(:get, %r{https://us.api.battle.net/wow/character/cenarion-circle/adrine}).to_return(:status => 200, :body => fixture("adrine.json"), :headers => {})

      [139742, 135652, 134491, 136862, 135647, 139746, 135649, 135653, 135651, 135648, 137533, 135690, 135692, 137419].each do |item_id|
        stub_request(:get, %r{https://us.api.battle.net/wow/item/#{item_id}}).to_return(:status => 200, :body => fixture("items/#{item_id}.json"), :headers => {})
      end
    end

    it "refreshes the character if it has old data" do
      expect {
        get :show, region: "us", realm: "cenarion-circle", name: "adrine"
      }.to change { character.reload.data_version }.from(nil).to(2)
    end
  end
end