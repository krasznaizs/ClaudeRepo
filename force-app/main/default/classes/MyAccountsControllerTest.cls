@isTest
private class MyAccountsControllerTest {
  @TestSetup
  static void setupTestData() {
    List<Account> accounts = new List<Account>();
    accounts.add(
      new Account(
        Name = 'Acme Corporation',
        Industry = 'Technology',
        Phone = '415-555-1234',
        AnnualRevenue = 5200000,
        Rating = 'Hot'
      )
    );
    accounts.add(
      new Account(
        Name = 'Global Industries',
        Industry = 'Manufacturing',
        Phone = '312-555-9876',
        AnnualRevenue = 1850000,
        Rating = 'Warm'
      )
    );
    accounts.add(
      new Account(
        Name = 'Frosty Beverages',
        Industry = 'Food & Beverage',
        Phone = '212-555-0001',
        AnnualRevenue = 950000,
        Rating = 'Cold'
      )
    );
    accounts.add(
      new Account(
        Name = 'No Rating Co',
        Industry = 'Retail',
        Phone = '212-555-0002',
        AnnualRevenue = 500000,
        Rating = null
      )
    );
    accounts.add(
      new Account(
        Name = 'Small Shop',
        Industry = 'Retail',
        Phone = '212-555-0003',
        AnnualRevenue = 100000,
        Rating = 'Warm'
      )
    );
    accounts.add(
      new Account(
        Name = 'Unknown Revenue Inc',
        Industry = 'Technology',
        Phone = '212-555-0004',
        AnnualRevenue = null,
        Rating = 'Hot'
      )
    );
    insert accounts;

    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];
    User otherUser = new User(
      FirstName = 'Other',
      LastName = 'Owner',
      Alias = 'other',
      Email = 'other.owner@myaccountstest.invalid',
      Username = 'other.owner@myaccountstest.invalid.' +
        UserInfo.getOrganizationId(),
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = standardProfile.Id
    );
    insert otherUser;

    Account otherUsersAccount = new Account(
      Name = 'Not Mine Inc',
      Industry = 'Technology',
      Phone = '212-555-9999',
      AnnualRevenue = 9999999,
      Rating = 'Hot'
    );
    System.runAs(otherUser) {
      insert otherUsersAccount;
    }
  }

  @isTest
  static void testGetMyAccounts_defaultCount() {
    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      3
    );
    Test.stopTest();

    System.assertEquals(
      3,
      result.accounts.size(),
      'Should return exactly the requested number of accounts'
    );
    System.assertEquals(
      6,
      result.totalCount,
      'Total count should reflect all accounts owned by the running user'
    );
    System.assertEquals(
      'Acme Corporation',
      result.accounts[0].Name,
      'Highest annual revenue should sort first'
    );
    System.assertEquals(
      'Global Industries',
      result.accounts[1].Name,
      'Second highest annual revenue should sort second'
    );
  }

  @isTest
  static void testGetMyAccounts_nullRevenueSortsLast() {
    // Remove one account so the 5 remaining (including the null-revenue one)
    // all fit within the max clamp of 5, letting us observe its sort position.
    delete [SELECT Id FROM Account WHERE Name = 'Small Shop'];

    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      5
    );
    Test.stopTest();

    System.assertEquals(5, result.accounts.size());
    System.assertEquals(
      'Unknown Revenue Inc',
      result.accounts[4].Name,
      'Null annual revenue should sort last'
    );
  }

  @isTest
  static void testGetMyAccounts_clampBelowMin() {
    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      0
    );
    Test.stopTest();

    System.assertEquals(
      2,
      result.accounts.size(),
      'Requested count below the minimum should be clamped up to 2'
    );
  }

  @isTest
  static void testGetMyAccounts_clampAboveMax() {
    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      10
    );
    Test.stopTest();

    System.assertEquals(
      5,
      result.accounts.size(),
      'Requested count above the maximum should be clamped down to 5'
    );
    System.assertEquals(
      6,
      result.totalCount,
      'Total count is unaffected by the display clamp'
    );
  }

  @isTest
  static void testGetMyAccounts_nullParamFallsBackToDefault() {
    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      null
    );
    Test.stopTest();

    System.assertEquals(
      3,
      result.accounts.size(),
      'A null parameter should fall back to the default of 3'
    );
  }

  @isTest
  static void testGetMyAccounts_excludesOtherUsersAccounts() {
    Test.startTest();
    MyAccountsController.MyAccountsResult result = MyAccountsController.getMyAccounts(
      5
    );
    Test.stopTest();

    for (Account acc : result.accounts) {
      System.assertNotEquals(
        'Not Mine Inc',
        acc.Name,
        'Accounts owned by another user must not be returned'
      );
    }
    System.assertEquals(
      6,
      result.totalCount,
      'Total count must not include accounts owned by another user'
    );
  }

  @isTest
  static void testGetMyAccounts_noAccountsForUser() {
    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];
    User emptyUser = new User(
      FirstName = 'Empty',
      LastName = 'Owner',
      Alias = 'empty',
      Email = 'empty.owner@myaccountstest.invalid',
      Username = 'empty.owner@myaccountstest.invalid.' +
        UserInfo.getOrganizationId(),
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      ProfileId = standardProfile.Id
    );
    insert emptyUser;

    MyAccountsController.MyAccountsResult result;
    System.runAs(emptyUser) {
      Test.startTest();
      result = MyAccountsController.getMyAccounts(3);
      Test.stopTest();
    }

    System.assertEquals(
      0,
      result.accounts.size(),
      'A user who owns no accounts should get an empty list'
    );
    System.assertEquals(
      0,
      result.totalCount,
      'A user who owns no accounts should get a total count of 0'
    );
  }
}
