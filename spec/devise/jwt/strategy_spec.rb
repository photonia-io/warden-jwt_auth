# frozen_string_literal: true

require 'spec_helper'

describe Devise::Jwt::Strategy do
  before do
    Devise::Jwt.configure do |config|
      config.secret = '123'
    end
  end

  let(:config) { Devise::Jwt.config }

  describe '#valid?' do
    context 'when Authorization header is set' do
      it 'returns true' do
        env = { 'HTTP_AUTHORIZATION' => 'Bearer 123' }
        strategy = described_class.new(env, :user)

        expect(strategy).to be_valid
      end
    end

    context 'when Authorization header is not set' do
      it 'returns false' do
        env = {}
        strategy = described_class.new(env, :user)

        expect(strategy).not_to be_valid
      end
    end
  end

  describe '#authenticate!' do
    context 'when token is invalid' do
      let(:env) { { 'HTTP_AUTHORIZATION' => 'Bearer 123' } }
      let(:strategy) { described_class.new(env, :user) }

      before { strategy.authenticate! }

      it 'fails authentication' do
        expect(strategy).not_to be_successful
      end

      it 'halts authentication' do
        expect(strategy).to be_halted
      end
    end

    context 'when token is valid' do
      let(:user_class) do
        Class.new do
          def id
            1
          end

          def self.find_for_jwt_authentication(_)
            :an_user
          end
        end
      end
      let(:token) do
        Devise::Jwt::TokenCoder.encode({ 'sub' => user_class.new.id }, config)
      end
      let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token}" } }
      let(:strategy) { described_class.new(env, :user) }

      before do
        Devise::Jwt.configure do |config|
          config.mappings = { user: user_class }
        end
        strategy.authenticate!
      end

      it 'successes authentication' do
        expect(strategy).to be_successful
      end

      it 'logs in user returned by current mapping' do
        expect(strategy.user).to eq(:an_user)
      end
    end
  end
end