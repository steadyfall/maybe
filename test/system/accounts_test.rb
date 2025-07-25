require "application_system_test_case"

class AccountsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    Family.any_instance.stubs(:get_link_token).returns("test-link-token")

    visit root_url
    open_new_account_modal
  end

  test "can create depository account" do
    assert_account_created("Depository")
  end

  test "can create investment account" do
    assert_account_created("Investment")
  end

  test "can create crypto account" do
    assert_account_created("Crypto")
  end

  test "can create property account" do
    # Step 1: Select property type and enter basic details
    click_link "Property"

    account_name = "[system test] Property Account"
    fill_in "Name*", with: account_name
    select "Single Family Home", from: "Property type*"
    fill_in "Year Built (optional)", with: 2005
    fill_in "Area (optional)", with: 2250

    click_button "Next"

    # Step 2: Enter balance information
    assert_text "Value"
    fill_in "account[balance]", with: 500000
    click_button "Next"

    # Step 3: Enter address information
    assert_text "Address"
    fill_in "Address Line 1", with: "123 Main St"
    fill_in "City", with: "San Francisco"
    fill_in "State/Region", with: "CA"
    fill_in "Postal Code", with: "94101"
    fill_in "Country", with: "US"

    click_button "Save"

    # Verify account was created and is now active
    assert_text account_name

    created_account = Account.order(:created_at).last
    assert_equal "active", created_account.status
    assert_equal 500000, created_account.balance
    assert_equal "123 Main St", created_account.property.address.line1
    assert_equal "San Francisco", created_account.property.address.locality
  end

  test "can create vehicle account" do
    assert_account_created "Vehicle" do
      fill_in "Make", with: "Toyota"
      fill_in "Model", with: "Camry"
      fill_in "Year", with: "2020"
      fill_in "Mileage", with: "30000"
    end
  end

  test "can create other asset account" do
    assert_account_created("OtherAsset")
  end

  test "can create credit card account" do
    assert_account_created "CreditCard" do
      fill_in "Available credit", with: 1000
      fill_in "account[accountable_attributes][minimum_payment]", with: 25.51
      fill_in "APR", with: 15.25
      fill_in "Expiration date", with: 1.year.from_now.to_date
      fill_in "Annual fee", with: 100
    end
  end

  test "can create loan account" do
    assert_account_created "Loan" do
      fill_in "account[accountable_attributes][initial_balance]", with: 1000
      fill_in "Interest rate", with: 5.25
      select "Fixed", from: "Rate type"
      fill_in "Term (months)", with: 360
    end
  end

  test "can create other liability account" do
    assert_account_created("OtherLiability")
  end

  private

    def open_new_account_modal
      within "[data-controller='DS--tabs']" do
        click_button "All"
        click_link "New account"
      end
    end

    def assert_account_created(accountable_type, &block)
      click_link Accountable.from_type(accountable_type).display_name.singularize
      click_link "Enter account balance" if accountable_type.in?(%w[Depository Investment Crypto Loan CreditCard])

      account_name = "[system test] #{accountable_type} Account"

      fill_in "Account name*", with: account_name
      fill_in "account[balance]", with: 100.99

      yield if block_given?

      click_button "Create Account"

      within_testid("account-sidebar-tabs") do
        click_on "All"
        find("details", text: Accountable.from_type(accountable_type).display_name).click
        assert_text account_name
      end

      visit accounts_url
      assert_text account_name

      created_account = Account.order(:created_at).last

      visit account_url(created_account)

      within_testid("account-menu") do
        find("button").click
        click_on "Edit"
      end

      fill_in "Account name", with: "Updated account name"
      click_button "Update Account"
      assert_selector "h2", text: "Updated account name"
    end

    def humanized_accountable(accountable_type)
      Accountable.from_type(accountable_type).display_name.singularize
    end
end
