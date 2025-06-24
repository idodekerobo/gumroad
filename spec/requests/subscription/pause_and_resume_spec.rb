# frozen_string_literal: true

require "spec_helper"

describe "Membership pause and resume functionality", type: :feature, js: true do
  include ManageSubscriptionHelpers

  before do
    setup_subscription
    setup_subscription_token
    
    # Ensure email notifications are enabled for consistent test behavior
    @subscription.seller.update!(enable_payment_email: true)
  end

  context "as a buyer" do
    before do
      visit "/subscriptions/#{@subscription.external_id}/manage?token=#{@subscription.token}"
    end

    it "can pause a subscription" do
      expect(page).to have_button("Pause membership")

      # Mock mailers
      allow(CustomerLowPriorityMailer).to receive_message_chain(:subscription_paused, :deliver_later)
      allow(ContactingCreatorMailer).to receive_message_chain(:subscription_paused_by_customer, :deliver_later)

      click_on "Pause membership"
      wait_for_ajax

      expect(page).to have_alert(text: "Membership paused")
      expect(page).to have_button("Resume membership")
      expect(@subscription.reload.paused_at).not_to be_nil

      # Assert that emails were sent
      expect(CustomerLowPriorityMailer).to have_received(:subscription_paused).with(@subscription.id)
      expect(ContactingCreatorMailer).to have_received(:subscription_paused_by_customer).with(@subscription.id)
    end

    it "can resume a subscription" do
      @subscription.pause!(by_seller: false)
      visit "/subscriptions/#{@subscription.external_id}/manage?token=#{@subscription.token}"

      expect(page).to have_button("Resume membership")

      # Mock mailers
      allow(CustomerLowPriorityMailer).to receive_message_chain(:subscription_resumed, :deliver_later)
      allow(ContactingCreatorMailer).to receive_message_chain(:subscription_resumed_by_customer, :deliver_later)

      click_on "Resume membership"
      wait_for_ajax

      expect(page).to have_alert(text: "Membership resumed")
      expect(page).to have_button("Pause membership")
      expect(@subscription.reload.paused_at).to be_nil

      # Assert that emails were sent
      expect(CustomerLowPriorityMailer).to have_received(:subscription_resumed).with(@subscription.id)
      expect(ContactingCreatorMailer).to have_received(:subscription_resumed_by_customer).with(@subscription.id)
    end
  end

  context "as a seller" do
    before do
      sign_in @subscription.seller
      visit "/audience/customers"
      find("td", text: @subscription.user.email).click
    end

    it "can pause a subscription" do
      expect(page).to have_button("Pause")

      # Mock mailers
      allow(CustomerLowPriorityMailer).to receive_message_chain(:subscription_paused_by_seller, :deliver_later)
      allow(ContactingCreatorMailer).to receive_message_chain(:subscription_paused, :deliver_later)

      click_on "Pause"
      wait_for_ajax

      expect(page).to have_alert(text: "Membership paused")
      expect(page).to have_button("Resume")
      expect(@subscription.reload.paused_at).not_to be_nil

      # Assert that emails were sent
      expect(CustomerLowPriorityMailer).to have_received(:subscription_paused_by_seller).with(@subscription.id)
      expect(ContactingCreatorMailer).to have_received(:subscription_paused).with(@subscription.id)
    end

    it "can resume a subscription" do
      @subscription.pause!(by_seller: true)
      page.refresh

      expect(page).to have_button("Resume")

      # Mock mailers
      allow(CustomerLowPriorityMailer).to receive_message_chain(:subscription_resumed_by_seller, :deliver_later)
      allow(ContactingCreatorMailer).to receive_message_chain(:subscription_resumed, :deliver_later)

      click_on "Resume"
      wait_for_ajax

      expect(page).to have_alert(text: "Membership resumed")
      expect(page).to have_button("Pause")
      expect(@subscription.reload.paused_at).to be_nil

      # Assert that emails were sent
      expect(CustomerLowPriorityMailer).to have_received(:subscription_resumed_by_seller).with(@subscription.id)
      expect(ContactingCreatorMailer).to have_received(:subscription_resumed).with(@subscription.id)
    end
  end

  context "when email notifications are disabled" do
    before do
      @subscription.seller.update!(enable_payment_email: false)
    end

    it "does not send creator emails when buyer pauses subscription" do
      visit "/subscriptions/#{@subscription.external_id}/manage?token=#{@subscription.token}"
      
      # Mock mailers
      allow(CustomerLowPriorityMailer).to receive_message_chain(:subscription_paused, :deliver_later)
      allow(ContactingCreatorMailer).to receive_message_chain(:subscription_paused_by_customer, :deliver_later)

      click_on "Pause membership"
      wait_for_ajax

      expect(CustomerLowPriorityMailer).to have_received(:subscription_paused).with(@subscription.id)
      expect(ContactingCreatorMailer).not_to have_received(:subscription_paused_by_customer)
    end
  end
end