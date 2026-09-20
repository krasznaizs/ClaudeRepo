/**
 * SCRUM-1: finds open Leads (not converted, not closed) older than 60 days
 * and creates a follow-up Task on each, assigned to the Lead owner, due in 2 days.
 */
public with sharing class OpenLeadFollowUpBatch implements Database.Batchable<SObject> {
    private static final Integer OPEN_DAYS_THRESHOLD = 60;
    private static final Integer DUE_IN_DAYS = 2;
    private static final String TASK_SUBJECT = 'Close the Lead or mark as bogus';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoffDate = Date.today().addDays(-OPEN_DAYS_THRESHOLD);
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Lead
            WHERE IsConverted = false
            AND Status != 'Closed - Not Converted'
            AND CreatedDate <= :cutoffDate
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Task> followUpTasks = new List<Task>();
        for (Lead ld : scope) {
            followUpTasks.add(new Task(
                Subject = TASK_SUBJECT,
                WhoId = ld.Id,
                OwnerId = ld.OwnerId,
                ActivityDate = Date.today().addDays(DUE_IN_DAYS)
            ));
        }
        insert followUpTasks;
    }

    public void finish(Database.BatchableContext bc) {
    }
}
