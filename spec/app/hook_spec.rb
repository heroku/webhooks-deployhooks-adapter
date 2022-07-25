# frozen_string_literal: true

require 'rspec'

RSpec.describe HookAdapter do
  def app
    HookAdapter
  end

  after do
    WebMock.reset!
  end

  context 'HTTP endpoint configured' do
    let(:stubbed_hook_request) do
      stub_request(:post, 'https://deployhook.receiver.com/hook')
        .with(body: deployhooks_formated_event_details.to_json,
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
        .to_return(status: 204)
    end

    before do
      ENV['HTTP_ENDPOINT'] = 'https://deployhook.receiver.com/hook'
      stubbed_hook_request
    end

    after do
      assert_requested(stubbed_hook_request)
    end

    it 'formats the body the way deployhooks does' do
      post '/', webhook_release_finished_payload.to_json

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end

    it 'only calls the endpoint when receives the final message' do
      post '/', webhook_release_started_payload.to_json
      post '/', webhook_release_finished_payload.to_json

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

  def webhook_release_started_payload
    {
      'id' => '01234567-89ab-cde0-1234-56789abcde01',
      'data' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'app' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'name' => 'awesome-app-42'
        },
        'slug' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'commit' => '48AKJH48758769671293ALFKJHL',
          'commit_description' => '  * jane: sample commit message'
        },
        'user' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'email' => 'jane@comapny.com'
        },
        'status' => 'succeeded',
        'current' => true,
        'version' => 42,
        'created_at' => '2022-08-01T20:20:20Z',
        'updated_at' => '2022-08-01T20:20:20Z',
        'description' => 'Deploy 48AKJH',
      },
      'actor' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'email' => 'jane@comapny.com'
      },
      'action' => 'create',
      'resource' => 'release',
      'created_at' => '2022-08-01T20:20:20.20Z',
      'updated_at' => '2022-08-01T20:20:20.20Z',
      'published_at' => '2022-08-01T20:20:20Z'
    }
  end

  def webhook_release_finished_payload
    {
      'id' => '01234567-89ab-cde0-1234-56789abcde01',
      'data' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'app' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'name' => 'awesome-app-42'
        },
        'slug' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'commit' => '48AKJH48758769671293ALFKJHL',
          'commit_description' => '  * jane: sample commit message'
        },
        'user' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'email' => 'jane@comapny.com'
        },
        'status' => 'succeeded',
        'current' => true,
        'version' => 42,
        'created_at' => '2022-08-01T20:20:20Z',
        'updated_at' => '2022-08-01T20:20:20Z',
        'description' => 'Deploy 48AKJH',
      },
      'actor' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'email' => 'jane@comapny.com'
      },
      'action' => 'update',
      'resource' => 'release',
      'created_at' => '2022-08-01T20:20:20.20Z',
      'updated_at' => '2022-08-01T20:20:20.20Z',
      'published_at' => '2022-08-01T20:20:20Z'
    }
  end

  def deployhooks_formated_event_details
    {
      'app' => 'awesome-app-42',
      'user' => 'jane@comapny.com',
      'url' => '',
      'head' => '48AKJH',
      'head_long' => '48AKJH48758769671293ALFKJHL',
      'git_log' => '* jane: sample commit message'
    }
  end
end
