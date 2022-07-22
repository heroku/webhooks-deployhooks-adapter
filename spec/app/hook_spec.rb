require 'rspec'

RSpec.describe Hook do
  def app
    Hook
  end

  describe "POST" do
    it "returns status 204" do
      post "/"
      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end
end