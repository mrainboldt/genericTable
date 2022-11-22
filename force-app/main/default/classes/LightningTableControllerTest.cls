/**
 * @description test coverage for LightningTableController
 * @author      M Rainboldt
 * @created     AUG 2018
 */
@isTest(isParallel=false)
private class LightningTableControllerTest {
    /**
     * @description create manager and 2 users
     */
    @TestSetup
    static void setup(){
        User manager = UserTestDataFactory.generateTestUser();
        manager.Alias = 'Manager';
        insert manager;

        User user1 = UserTestDataFactory.generateTestUser();
        user1.Username = user1.Username + '1';
        user1.ManagerId = manager.Id;

        User user2 = UserTestDataFactory.generateTestUser();
        user2.Username = user2.Username + '2';
        user2.ManagerId = manager.Id;

        insert new List<User>{user1, user2};

        Contact contact = ContactTestDataFactory.generateContact();
        insert contact;
    }
    /**
     * @description test general functionality
     */
    @isTest static void general()
    {
        //ARRANGE
        User sourceRecord = [SELECT Id, ManagerId 
                                FROM User 
                                WHERE Manager.Alias = 'Manager'
                                LIMIT 1];
        String recordId = sourceRecord.ManagerId;
        String relatedObject = 'User';
        String relatedField = 'ManagerId';
        String fieldSet = 'TEST';
        String whereClause = '';
        Integer recLimit = 1;

        //ACT
        Test.startTest();
        TableWrapper result = LightningTableController.initTable(recordId
                                                                , relatedField
                                                                , relatedObject
                                                                , fieldSet
                                                                , whereClause
                                                                , recLimit
                                                                , null
                                                                , null);
        List<SObject> allResult = LightningTableController.loadAllRecords(result.fieldSOQL, result.sObjectType, result.whereClause);
        Test.stopTest();

        //ASSERT
        System.assert(!result.records.isEmpty(), 'Records should not be empty.');
        System.assert(result.rowCount > 0, 'RowCount should be greater than 1.');
        System.assert(result.totalRowCount > result.rowCount, 'Total row count should be greater than row count.');
        System.assertEquals(result.totalRowCount, allResult.size());
        System.assertNotEquals(null, result.columns);
    }

    /**
     * @description test where clause functionality
     */
    @isTest static void test_WhereClause()
    {
        //ARRANGE

        User sourceRecord = [SELECT Id
                            , ManagerId
                            , Name 
                            FROM User 
                            WHERE Manager.Alias = 'Manager'
                            LIMIT 1];
        
        String recordId = sourceRecord.ManagerId;
        String relatedObject = 'User';
        String relatedField = 'ManagerId';
        String fieldSet = 'TEST';
        Integer recLimit = 1;
        String whereClause = 'Name != \'' + sourceRecord.Name + '\'';

        //ACT
        Test.startTest();
        TableWrapper result = LightningTableController.initTable(recordId, relatedField, relatedObject, fieldSet, whereClause , recLimit, null, null);
        Test.stopTest();

        //ASSERT
        System.assertEquals(0, result.rowCount);
        System.assertNotEquals(null, result.columns);
        System.assert(result.records.isEmpty());
    }

    /**
     * @description initialize a table for a single record
     */
    @isTest static void asPortalUser()
    {
        //Arrange
        User portalUser = UnitTestHelper.createPortalUser('table', 'table@test.com', true);
        insert portalUser;

        Task task = new Task();
        task.WhoId = portalUser.ContactId;
        task.Subject = 'Call';
        task.OwnerId = portalUser.Id;
        insert task;

        //ACT
        Test.startTest();
        TableWrapper result;
        System.runAs(portalUser)
        {
            result = LightningTableController.initTableForRecord(portalUser.Id, 'TEST', 'User');
        }
        Test.stopTest();

        //ASSERT
        System.assertEquals(1, result.records.size());
        System.assertEquals(portalUser.Id, result.records[0].Id);

    }

    /**
     * @description test init table json functionality
     */
    @isTest static void initTableJSON()
    {
        //ARRANGE
        User sourceRecord = [SELECT Id, ManagerId 
                                FROM User 
                                WHERE Manager.Alias = 'Manager'
                                LIMIT 1];
        String recordId = sourceRecord.ManagerId;
        String relatedObject = 'User';
        String relatedField = 'ManagerId';
        String fieldSet = 'TEST';
        String whereClause = '';
        Integer recLimit = 1;

        //ACT
        Test.startTest();
        String resultJSON = LightningTableController.initTableJSON(recordId
                                                                , relatedField
                                                                , relatedObject
                                                                , fieldSet
                                                                , whereClause
                                                                , recLimit
                                                                , 'Username'
                                                                , 'desc');
        Test.stopTest();

        //ASSERT
        System.assert(resultJSON.containsIgnoreCase('Nulls Last'));
    }

    /**
     * @description test that json is converted and saved correctly
     */
    @isTest static void saveRecordSuccess()
    {
        //ARRANGE
        Contact contact = [SELECT Id
                                , LastName
                            FROM Contact
                            LIMIT 1];
        contact.LastName = 'Success';

        //ACT
        Test.startTest();
        LightningTableController.saveRecords(JSON.serialize(new List<Contact>{contact}));
        Test.stopTest();

        //ASSERT
        Contact result = [SELECT Id
                            , LastName
                        FROM Contact
                        WHERE Id = :contact.Id
                        LIMIT 1];
        System.assertEquals(contact.LastName, result.LastName, 'LastName should have been updated.');
    }
}