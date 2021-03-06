# frozen_string_literal: true
require 'ffaker'

FactoryBot.define do
  factory :alert_management_alert, class: 'AlertManagement::Alert' do
    project
    title { FFaker::Lorem.sentence }
    started_at { Time.current }

    trait :with_issue do
      issue
    end

    trait :with_fingerprint do
      fingerprint { SecureRandom.hex }
    end

    trait :with_service do
      service { FFaker::App.name }
    end

    trait :with_monitoring_tool do
      monitoring_tool { FFaker::App.name }
    end

    trait :with_host do
      hosts { FFaker::Internet.public_ip_v4_address }
    end

    trait :resolved do
      status { :resolved }
    end
  end
end
