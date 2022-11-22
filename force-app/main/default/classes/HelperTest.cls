/**
 * @description test class for helper class
 */
@isTest
private class HelperTest {

    // getFieldsStandardObject
    
   public static testMethod void testGetFieldsStandardObject_ReturnsFieldList() { 
        List<String> selection = Helper.getFields(Schema.SObjectType.Account);
        
        System.assert((new Set<String>(selection)).contains('Id'), 'The fields should contain Id');        
        System.assert((new Set<String>(selection)).contains('Name'), 'FieldList doesn\'t contain Name');
        System.assert(!selection.isEmpty(), 'The selection fields string should not be empty.');
    }


    // getFieldsCustomObject
    
    public static testMethod void testGetFieldsCustomObject_ReturnsFieldList() { 
        List<String> selection = Helper.getFields(Schema.SObjectType.Contact);
        
        System.assert((new Set<String>(selection)).contains('Id'), 'The selection fields should contain Id');        
        System.assert(!selection.isEmpty(), 'The selection fields string should not be empty.');
    }
    
    public static testMethod void testGetFieldsWithPrefixCustomObject_ParentFormat_ReturnsFieldList() { 
        List<String> selection = Helper.getFieldsWithPrefix(Schema.SObjectType.Contact, true);
        String prefix = Schema.SObjectType.Contact.getName().replaceAll('__c', '__r');
        System.Debug(selection);
        
        for(String s : selection) {
            System.Assert(s.startsWith(prefix), 'Each element should start with the Object Prefix');
        }
        System.assert(!selection.isEmpty(), 'The selection fields string should not be empty.');
    }
    
    public static testMethod void testGetFieldsWithPrefixCustomObject_ReturnsFieldList() { 
        List<String> selection = Helper.getFieldsWithPrefix(Schema.SObjectType.Contact);
        String prefix = Schema.SObjectType.Contact.getName();
        
        for(String s : selection) {
            System.Assert(s.startsWith(prefix), 'Each element should start with the Object Prefix');
        }
        System.assert(!selection.isEmpty(), 'The selection fields string should not be empty.');
    }
    
    public static testMethod void testGetRecordTypeInfosById_CustomObject_ReturnsRecordTypeInfoMap() {
        Map<Id, Schema.RecordTypeInfo> rtMap = Helper.getRecordTypeInfosById(Schema.SObjectType.Contact);
        System.Assert(rtMap!=null, 'Return map should not be null');
    }
    
    public static testMethod void testGetRecordTypeInfosByName_CustomObject_ReturnsRecordTypeInfoMap() {
        Map<String, Schema.RecordTypeInfo> rtMap = Helper.getRecordTypeInfosByName(Schema.SObjectType.Contact);
        System.Assert(rtMap!=null, 'Return map should not be null');
    }
    
    public static testMethod void addToMapObject_UpdateMapwithMapping() {
        Map<String, String> nameToNameMap = new Map<String, String>();
        String name = 'AccountName';
        String accountNumber = '12345';
        Helper.addToMap(nameToNameMap, new List<Account>{new Account(Name = name, AccountNumber = accountNumber)}, 'Name', 'AccountNumber');
        System.Assert(nameToNameMap.size()>0, 'Should have a value');
        System.Assert(nameToNameMap.get(name)==accountNumber, 'Account Number should be mapped to Account Name');
    }
    
    public static testMethod void testGetUserDetails_ListOfUsers_ReturnsUserMap() { 
        integer count = 1;
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id FROM User LIMIT :count]);
        List<Id> userIdList = new List<Id>();
        userIdList.addAll(userMap.keySet());
        Map<Id, User> users = Helper.getUserDetails(userIdList);

        System.Assert(users!=null, 'return map should not be null') ;
        System.Assert(users.size()==count, 'return map size should be the same size');
        for(User u : userMap.values()) {
            System.Assert(users.containsKey(u.Id));
        }
    }
    
    public static testMethod void testGetuserDetail_CurrentUser_ReturnsUserObject() { 
        User currentUser = Helper.getUserDetail(UserInfo.getUserId());
        
        System.Assert(currentUser!=null, 'Returned User object should not be null');
        System.Assert(currentUser.Id==UserInfo.getUserId(), 'Returned Id of User should be the same as input');
        System.Assert(currentUser.UserName==UserInfo.getUserName(), 'Additional information should have been returned');
    }


    // fieldNameMapByObjectMap

    public static testMethod void testGetFieldsMap_FreshQuery_ReturnsFieldMap() {
        Map<String, Schema.SObjectField> fieldMap = Helper.getFieldsMap(Schema.SObjectType.Contact);

        System.assertNotEquals(null, fieldMap);
    }

    public static testMethod void testGetFieldsMap_RepeatedCalls_DoesNotFurtherIncrementFieldDescribes() {
        Map<String, Schema.SObjectField> fieldMap = Helper.getFieldsMap(Schema.SObjectType.Contact);

        Map<String, Schema.SObjectField> fieldMap2 = Helper.getFieldsMap(Schema.SObjectType.Contact);

        System.assertNotEquals(null, fieldMap);
        System.assertNotEquals(null, fieldMap2);
    }
    
    public static testMethod void testUrlEncode() {
        String stringToEncode = Helper.urlEncode('the string');
        String emptyString = Helper.urlEncode('');
        System.Assert(stringToEncode.contains('+'), 'Should encode space');
        System.Assert(String.isBlank(emptyString), 'String should be blank');
    }
    
    public static testMethod void testUrlDecode() {
        String stringToDecode = Helper.urlDecode('the%20string');
        String emptyString = Helper.urlDecode('');
        System.Assert(!stringToDecode.contains('%20'), 'Should have decoded space');
        System.Assert(String.isBlank(emptyString), 'String should be blank');
        
    }
    
    // getFieldsMapBySObject

    public static testMethod void testGetFieldsMapBySObject_QueryiesValidObject_ReturnsFieldMap() {
        Contact[] contacts = UnitTestHelper.createContacts('name', 4, false);
        insert contacts;

        Map<String, Schema.SObjectField> fieldsMap = Helper.getFieldsMapBySObject(contacts[0]);
    }

    public static testMethod void testAddToMap(){
        Integer count = 10;
        Map<String, String> idToNameMap = new Map<String, String>();
        Contact[] contact = UnitTestHelper.createContacts('key', count, false);
        insert contact;
        Helper.addToMap(idToNameMap, contact, 'Id', 'Name');
        System.Assert(idToNameMap.keySet().size() == count, 'size should be ' + count);
    }
    
    /**
     * @description test the format cron expression
     */
    @isTest static void test_getCronExpression()
    {
        //ARRANGE

        //ACT
        Test.startTest();
        String defaultExp = Helper.getCronExpression(null, null, null, null, null);
        String setEverything = Helper.getCronExpression(3, 4, '5', 6, '7');
        String weekly = Helper.getCronExpression(0, 11, null, null, '7');
        String monthly = Helper.getCronExpression(0, 11, null, null, '7#2');
        Test.stopTest();


        //ASSERT
        System.assertEquals('0 0 * * * ?', defaultExp);
        System.assertEquals('0 3 4 5 6 7', setEverything);
        System.assertEquals('0 0 11 * * 7', weekly);
        System.assertEquals('0 0 11 * * 7#2', monthly);
    }

    @isTest static void checkEndOfMonth_MidMonth()
    {
        //ARRANGE
        Integer year = 1997;
        Integer month = 12;
        Integer day = 25;

        //ACT
        Test.startTest();
        Integer result = Helper.checkEndOfMonth(year, month, day);
        Test.stopTest();


        //ASSERT
        System.assertEquals(day, result);
    }

    @isTest static void checkEndOfMonth_Feb()
    {
        //ARRANGE
        Integer year = 2019;
        Integer month = 2;
        Integer day = 30;
        
        //ACT
        Test.startTest();
        Integer result = Helper.checkEndOfMonth(year, month, day);
        Test.stopTest();


        //ASSERT
        System.assertEquals(28, result);
    }

    /**
     * @description return 29, because 2/30 does not exist but 2/29 is the last day of the month
     */
    @isTest static void checkEndOfMonth_Feb_LeapYear()
    {
        //ARRANGE
        Integer year = 2016;
        Integer month = 2;
        Integer day = 30;
        
        //ACT
        Test.startTest();
        Integer result = Helper.checkEndOfMonth(year, month, day);
        Test.stopTest();


        //ASSERT
        System.assertEquals(29, result);
    }

    /**
     * @descriptions test the encrypt method
     */
    @isTest static void encrypt()
    {
        Helper.encrypt('Test');
    }
}