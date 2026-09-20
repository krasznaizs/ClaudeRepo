/**
 * Backing controller for the myAccounts LWC dashboard card.
 * Uses @AuraEnabled(cacheable=true) with a single wrapper (rather than two
 * separate calls) so the displayed slice and the total count are always
 * computed together in one query context, avoiding the two numbers drifting
 * apart when independent @wire caches refresh at different times. This
 * intentionally departs from FlexTemplateController's imperative,
 * button-triggered pattern because this component auto-loads on render.
 */
public with sharing class MyAccountsController {
  private static final Integer MIN_ACCOUNTS = 2;
  private static final Integer MAX_ACCOUNTS = 5;
  private static final Integer DEFAULT_ACCOUNTS = 3;

  public class MyAccountsResult {
    @AuraEnabled
    public List<Account> accounts;
    @AuraEnabled
    public Integer totalCount;
  }

  @AuraEnabled(cacheable=true)
  public static MyAccountsResult getMyAccounts(Integer numberOfAccounts) {
    try {
      Integer recordLimit = clamp(numberOfAccounts);

      List<Account> accounts = [
        SELECT Id, Name, Industry, Phone, AnnualRevenue, Rating
        FROM Account
        WHERE OwnerId = :UserInfo.getUserId()
        WITH SECURITY_ENFORCED
        ORDER BY AnnualRevenue DESC NULLS LAST
        LIMIT :recordLimit
      ];

      Integer totalCount = [
        SELECT COUNT()
        FROM Account
        WHERE OwnerId = :UserInfo.getUserId()
      ];

      MyAccountsResult result = new MyAccountsResult();
      result.accounts = accounts;
      result.totalCount = totalCount;
      return result;
    } catch (Exception e) {
      System.debug(e.getMessage());
      throw e;
    }
  }

  private static Integer clamp(Integer requested) {
    Integer value = (requested == null) ? DEFAULT_ACCOUNTS : requested;
    if (value < MIN_ACCOUNTS) {
      value = MIN_ACCOUNTS;
    }
    if (value > MAX_ACCOUNTS) {
      value = MAX_ACCOUNTS;
    }
    return value;
  }
}
