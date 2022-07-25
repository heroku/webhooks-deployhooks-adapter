# frozen_string_literal: true

require 'rspec'

RSpec.describe HookAdapter do
  def app
    HookAdapter
  end

  after do
    WebMock.reset!
  end

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
    ENV.delete('HTTP_ENDPOINT')
  end

  context 'HTTP endpoint configured and responding' do
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

    it 'ignores release phase started message' do
      post '/', webhook_release_phase_started_payload.to_json
      post '/', webhook_release_started_payload.to_json
      post '/', webhook_release_finished_payload.to_json

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end

    it 'replaces params on the URL' do
      ENV['HTTP_ENDPOINT'] = 'https://deployhook.receiver.com/hook?app={{app}}&user={{user}}&head={{head}}&head_long={{head_long}}&git_log={{git_log}}'
      stubbed_hook_request.with(query: {
                                  app: 'awesome-app-42',
                                  user: 'jane@comapny.com',
                                  head: '48AKJH',
                                  head_long: '48AKJH48758769671293ALFKJHL',
                                  git_log: '* jane: sample commit message'
                                })

      post '/', webhook_release_finished_payload.to_json

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end
  end

  it 'fails if the endpoint does not respond' do
    ENV['HTTP_ENDPOINT'] = 'https://broken-deployhook.receiver.com/hook'
    stub_request(:post, 'https://broken-deployhook.receiver.com/hook')
      .to_return(status: 503)

    post '/', webhook_release_finished_payload.to_json

    expect(last_response.status).to eq(500)
    expect(last_response.body).to be_empty
  end

  it 'does not call HTTP endpoint if it is not configured' do
    ENV.delete('HTTP_ENDPOINT')

    post '/'

    assert_not_requested :any, 'https://deployhook.receiver.com/hook'
    expect(last_response.status).to eq(204)
    expect(last_response.body).to be_empty
  end

  context 'with authorization' do
    before do
      ENV['AUTHORIZATION'] = 'Bearer 01234567-89ab-cdef-0123-456789abcdef'
    end

    after do
      ENV.delete('AUTHORIZATION')
    end

    it 'succeeds if the authorization header matches the configured value' do
      post '/', webhook_release_finished_payload.to_json, 'Authorization' => 'Bearer 01234567-89ab-cdef-0123-456789abcdef'

      expect(last_response.status).to eq(204)
      expect(last_response.body).to be_empty
    end

    it 'fails if the authorization header does not match the configured value' do
      post '/', webhook_release_finished_payload.to_json, 'Authorization' => 'wrong-authorization'

      expect(last_response.status).to eq(403)
      expect(last_response.body).to be_empty
    end
  end

  def webhook_release_phase_started_payload
    {
      'id' => '01234567-89ab-cde0-1234-56789abcde00',
      'data' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde00',
        'app' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'name' => 'awesome-app-42'
        },
        'slug' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde00',
          'commit' => '48AKJH48758769671293ALFKJHL',
          'commit_description' => '  * jane: sample commit message'
        },
        'user' => {
          'id' => '01234567-89ab-cde0-1234-56789abcde01',
          'email' => 'jane@comapny.com'
        },
        'status' => 'pending',
        'current' => false,
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
        'updated_at' => '2022-08-01T20:20:21Z',
        'description' => 'Deploy 48AKJH',
      },
      'actor' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'email' => 'jane@comapny.com'
      },
      'action' => 'create',
      'resource' => 'release',
      'created_at' => '2022-08-01T20:20:20.20Z',
      'updated_at' => '2022-08-01T20:20:20.21Z',
      'published_at' => '2022-08-01T20:20:21Z'
    }
  end

  def webhook_release_finished_payload
    {
      'id' => '01234567-89ab-cde0-1234-56789abcde02',
      'data' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde02',
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
        'updated_at' => '2022-08-01T20:20:22Z',
        'description' => 'Deploy 48AKJH',
      },
      'actor' => {
        'id' => '01234567-89ab-cde0-1234-56789abcde01',
        'email' => 'jane@comapny.com'
      },
      'action' => 'update',
      'resource' => 'release',
      'created_at' => '2022-08-01T20:20:20.20Z',
      'updated_at' => '2022-08-01T20:20:20.22Z',
      'published_at' => '2022-08-01T20:20:22Z'
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
