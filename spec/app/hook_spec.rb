# frozen_string_literal: true

require 'rspec'

RSpec.describe HookAdapter do
  def app
    HookAdapter
  end

  after do
    WebMock.reset!
  end

  context 'HTTP endpoint accepts the message' do
    let(:stubbed_hook_request) do
      stub_request(:post, 'https://deployhook.receiver.com/hook')
        .to_return(status: 204)
    end

    before do
      ENV['HTTP_ENDPOINT'] = 'https://deployhook.receiver.com/hook'
      stubbed_hook_request
    end

    after do
      assert_requested(stubbed_hook_request)
    end

    it 'returns status 204' do
      post '/'
      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end
end
