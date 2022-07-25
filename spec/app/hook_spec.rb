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
        .with(headers: {'Content-Type' => 'application/x-www-form-urlencoded'})
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

  it 'does not call HTTP endpoint if it is not configured' do
    ENV.delete('HTTP_ENDPOINT')

    post '/'

    assert_not_requested :any, 'https://deployhook.receiver.com/hook'
    expect(last_response.status).to eq(204)
    expect(last_response.body).to be_empty
  end
end
