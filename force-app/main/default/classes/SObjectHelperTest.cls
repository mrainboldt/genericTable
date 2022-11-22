@isTest
public with sharing class SObjectHelperTest {
    
    public static final String TEST_FIELDSET_NAME = 'FieldsetForApexUnitTests';
    
    /**
    * @description provide unit testing for the getSObjectFieldMapByObjectName method
    */
    @isTest static void testGetSObjectFieldMapByObjectName(){
        Map<String, Schema.SObjectField> fieldMap = SObjectHelper.getSObjectFieldMapByObjectName('Account');
        System.assert(!fieldMap.isEmpty());
    }
    
    /**
    * @description provide unit testing for the generateQueryStringByObjectName method
    */
    @isTest static void testGenerateQueryStringByObjectName(){
        String queryString = SObjectHelper.generateQueryStringByObjectName('Account', true);
        System.assert(String.isNotBlank(queryString));
    }
    
    /**
    * @description provide unit testing for the getSimplifiedFieldSetMapByFieldSetName method
    */
    @isTest static void testGetSimplifiedFieldSetMapByFieldSetName(){
        Map<String, Schema.FieldSetMember> fieldMap = SObjectHelper.getSimplifiedFieldSetMapByFieldSetName('User', 'TEST');
        System.assert(!fieldMap.isEmpty());
    }
    
    /**
    * @description provide unit testing for the getFieldSetMembersByFieldSetName method
    */
    @isTest static void testGetFieldSetMembersByFieldSetName(){
        List<Schema.FieldSetMember> fieldList = SObjectHelper.getFieldSetMembersByFieldSetName('User', 'TEST');
        System.assert(!fieldList.isEmpty());
    }
    
    /**
    * @description provide unit testing for the getFieldSetMembersByFieldSetName method
    */
    @isTest static void testGetPicklistValues(){
        List<Schema.PicklistEntry> valueList = SObjectHelper.getPicklistValues('Opportunity', 'StageName');
        System.assert(!valueList.isEmpty());
    }
    
    @isTest static void testGroupByIdField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        Map<Id, List<Contact>> m = SObjectHelper.groupByIdField(c, 'AccountId');

        //Assert
        System.assert(m.isEmpty(), 'There should be no results ' + m);
        Test.stopTest();
    }
    
    @isTest static void testGroupByIdField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 4, true);
        Helper.forcedInsert(a);
        
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].AccountId = a[0].Id;
        c[1].AccountId = a[0].Id;
        c[2].AccountId = a[1].Id;
        c[3].AccountId = a[2].Id;
        c[4].AccountId = null;
        Helper.forcedInsert (c);

        //Act
        Test.startTest();
        Map<Id, List<Contact>> m = SObjectHelper.groupByIdField(c, 'AccountId');

        //Assert
        System.assertEquals(4, m.size(), 'The contacts should be separated into 4 groups ' + m);
        System.assert(m.keySet().containsAll(new Set<Id>{
            a[0].Id, a[1].Id, a[2].Id, null
        }), 'The Contacts were not sorted properly ' + m);
        Test.stopTest();
    }
    
    //SObjectHelper.groupByField()///////////////////////////////////////
    
    @isTest static void testGroupByField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        Map<String, List<Contact>> m = SObjectHelper.groupByField(c, 'FirstName');

        //Assert
        System.assert(m.isEmpty(), 'There should be no results ' + m);
        Test.stopTest();
    }
    
    @isTest static void testGroupByField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].FirstName = 'One';
        c[1].FirstName = 'One';
        c[2].FirstName = 'Two';
        c[3].FirstName = 'Three';
        c[4].FirstName = null;
        Helper.forcedInsert(c);

        //Act
        Test.startTest();
        Map<String, List<Contact>> m = SObjectHelper.groupByField(c, 'FirstName');

        //Assert
        System.assertEquals(4, m.size(), 'The contacts should be separated into 4 groups ' + m);
        System.assert(m.keySet().containsAll(new Set<String>{
            'One', 'Two', 'Three', null
        }), 'The Contacts were not sorted properly ' + m);
        Test.stopTest();
    }    
    
    //SObjectHelper.mapByField()///////////////////////////////////////
    
    @isTest static void testMapByField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        Map<String, SObject> m = SObjectHelper.mapByField(c, 'FirstName');

        //Assert
        System.assert(m.isEmpty(), 'There should be no results ' + m);
        Test.stopTest();
    }
    
    @isTest static void testMapByField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].FirstName = 'One';
        c[1].FirstName = 'One';
        c[2].FirstName = 'Two';
        c[3].FirstName = 'Three';
        c[4].FirstName = null;
        Helper.forcedInsert(c);

        //Act
        Test.startTest();
        Map<String, SObject> m = SObjectHelper.mapByField(c, 'FirstName');

        //Assert
        System.assertEquals(3, m.size(), 'The contacts should be separated into 3 groups ' + m);
        System.assert(m.keySet().containsAll(new Set<String>{
            'One', 'Two', 'Three'
        }), 'The Contacts were not sorted properly ' + m);
        Test.stopTest();
    }    
    
    //SObjectHelper.mapByIdField()///////////////////////////////////////
    
    @isTest static void testMapByIdField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        Map<Id, SObject> m = SObjectHelper.mapByIdField(c, 'AccountId');

        //Assert
        System.assert(m.isEmpty(), 'There should be no results ' + m);
        Test.stopTest();
    }
    
    @isTest static void testMapByIdField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 4, true);
        Helper.forcedInsert(a);
        
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].AccountId = a[0].Id;
        c[1].AccountId = a[0].Id;
        c[2].AccountId = a[1].Id;
        c[3].AccountId = a[2].Id;
        c[4].AccountId = null;
        Helper.forcedInsert(c);

        //Act
        Test.startTest();
        Map<Id, SObject> m = SObjectHelper.mapByIdField(c, 'AccountId');

        //Assert
        System.assertEquals(3, m.size(), 'The contacts should be separated into 3 groups ' + m);
        System.assert(m.keySet().containsAll(new Set<Id>{
            a[0].Id, a[1].Id, a[2].Id
        }), 'The Contacts were not sorted properly ' + m);
        Test.stopTest();
    }   
    
    //SObjectHelper.collectIdsByField()///////////////////////////////////////
    
    @isTest static void testCollectIdsByField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        Set<Id> s = SObjectHelper.collectIdsByField(c, 'AccountId');

        //Assert
        System.assert(s.isEmpty(), 'There should be no results ' + s);
        Test.stopTest();
    }
    
    @isTest static void testCollectIdsByField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 4, true);
        Helper.forcedInsert(a);
        
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].AccountId = a[0].Id;
        c[1].AccountId = a[0].Id;
        c[2].AccountId = a[1].Id;
        c[3].AccountId = a[2].Id;
        c[4].AccountId = null;
        Helper.forcedInsert(c);

        //Act
        Test.startTest();
        Set<Id> s = SObjectHelper.collectIdsByField(c, 'AccountId');

        //Assert
        System.assertEquals(3, s.size(), 'The contacts should be separated into 3 groups ' + s);
        System.assert(s.containsAll(new Set<Id>{
            a[0].Id, a[1].Id, a[2].Id
        }), 'The Contacts were not sorted properly ' + s);
        Test.stopTest();
    } 
    
    //SObjectHelper.collectSObjectsByField()///////////////////////////////////////
    
    @isTest static void testCollectSObjectsByField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        List<Account> s = SObjectHelper.collectSObjectsByField(c, 'Account');

        //Assert
        System.assert(s.isEmpty(), 'There should be no results ' + s);
        Test.stopTest();
    }
    
    @isTest static void testCollectSObjectsByField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 4, true);
        Helper.forcedInsert(a);
        
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].AccountId = a[0].Id;
        c[1].AccountId = a[0].Id;
        c[2].AccountId = a[1].Id;
        c[3].AccountId = a[2].Id;
        c[4].AccountId = null;
        Helper.forcedInsert(c);
        
        Set<Id> contactIds = (new Map<Id, Contact>(c)).keySet();
        c = [SELECT Id, Account.Id FROM Contact WHERE Id IN :contactIds];

        //Act
        Test.startTest();
        List<Account> s = SObjectHelper.collectSObjectsByField(c, 'Account');

        //Assert
        System.assertEquals(4, s.size(), 'The contacts should be separated into 4 groups ' + s);
        System.assert((new Map<Id, Account>(s)).keySet().containsAll(new Set<Id>{
            a[0].Id, a[1].Id, a[2].Id
        }), 'The Contacts were not sorted properly ' + s);
        Test.stopTest();
    }  
    
    //SObjectHelper.collectAllSObjectsByField()///////////////////////////////////////
    
    @isTest static void testCollectAllSObjectsByField_NullObjects_ReturnsEmptyMap() {
        //Arrange
        Contact[] c = null;

        //Act
        Test.startTest();
        List<Account> s = SObjectHelper.collectAllSObjectsByField(c, 'Account');

        //Assert
        System.assert(s.isEmpty(), 'There should be no results ' + s);
        Test.stopTest();
    }
    
    @isTest static void testCollectAllSObjectsByField_VariousObject_ReturnsGroupedMap() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 4, true);
        Helper.forcedInsert(a);
        
        Contact[] c = UnitTestHelper.createContacts('group2', 5, true);
        c[0].AccountId = a[0].Id;
        c[1].AccountId = a[0].Id;
        c[2].AccountId = a[1].Id;
        c[3].AccountId = a[2].Id;
        c[4].AccountId = null;
        Helper.forcedInsert(c);
        
        Set<Id> accountIds = (new Map<Id, Account>(a)).keySet();
        a = [SELECT Id, (SELECT Id FROM Contacts) FROM Account WHERE Id IN :accountIds];

        //Act
        Test.startTest();
        List<Contact> s = SObjectHelper.collectAllSObjectsByField(a, 'Contacts');

        //Assert
        System.assertEquals(4, s.size(), 'The contacts should be separated into 3 groups ' + s);
        System.assert((new Map<Id, Contact>(s)).keySet().containsAll(new Set<Id>{
            c[0].Id, c[1].Id, c[2].Id, c[3].Id
        }), 'The Contacts were not sorted properly ' + s);
        Test.stopTest();
    }     



    @isTest static void testOrderedMapConstructor_NoErrors() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 5, true);
        Helper.forcedInsert(a);

        //Act
        Test.startTest();
        SObjectHelper.OrderedMap m1 = new SObjectHelper.OrderedMap();
        SObjectHelper.OrderedMap m2 = new SObjectHelper.OrderedMap(a);
        SObjectHelper.OrderedMap m3 = new SObjectHelper.OrderedMap(new Map<Id, Account>(a));

        //Assert
        System.assertNotEquals(null, m1);
        System.assertNotEquals(null, m2);
        System.assertNotEquals(null, m3);
        Test.stopTest();
    }
    
    @isTest static void testOrderedMapConstructor_ListTest_NoErrors() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 5, true);
        Helper.forcedInsert(a);
        
        Map<Id, Account> mapping = new Map<Id, Account>(a);
        Set<Id> ids = mapping.keySet();

        //Act
        Test.startTest();
        SObjectHelper.OrderedMap m = new SObjectHelper.OrderedMap();
        m.addAll(a);
        
        m.sort();

        System.assertEquals(ids, m.keySet());
        System.assertEquals(mapping, m.toMap());
        System.assertEquals(a, m.values());
                
        for (Integer i = 0; i < a.size(); i++) {
            System.assert(m.contains(a[i]));
            System.assert(m.containsKey(a[i].Id));
            System.assertEquals(a[i], m.get(i));
            System.assertEquals(a[i], m.get(a[i].Id));
        }
        
        System.assert(m.equals(m.values()));
        System.assert(m.equals(m.toMap()));

        //Assert
        Test.stopTest();
    }
    
    
    @isTest static void testOrderedMapConstructor_MapTest_NoErrors() {
        //Arrange
        Account[] a = UnitTestHelper.createAccounts('group1', 5, true);
        Helper.forcedInsert(a);
        
        Map<Id, Account> mapping = new Map<Id, Account>(a);
        Set<Id> ids = mapping.keySet();

        //Act
        Test.startTest();
        SObjectHelper.OrderedMap m = new SObjectHelper.OrderedMap();
        m.putAll(mapping);
        
        m.sort();

        System.assertEquals(ids, m.keySet());
        System.assertEquals(mapping, m.toMap());
        System.assertEquals(a, m.values());
                
        for (Integer i = 0; i < a.size(); i++) {
            System.assert(m.contains(a[i]));
            System.assert(m.containsKey(a[i].Id));
            System.assertEquals(a[i], m.get(i));
            System.assertEquals(a[i], m.get(a[i].Id));
        }
        
        System.assert(m.equals(m.values()));
        System.assert(m.equals(m.toMap()));

        //Assert
        Test.stopTest();
    }

    @isTest static void test_hasSObjectField_string_false(){
        //Arrange

        //Act
        test.startTest();
        Boolean result = SObjectHelper.hasSObjectField('test__c', 'Account');
        test.stopTest();

        //Assert
        System.assertEquals(false, result);

    }

    @isTest static void test_hasSObjectField_string_true(){
        //Arrange

        //Act
        test.startTest();
        Boolean result = SObjectHelper.hasSObjectField('Name', 'Account');
        test.stopTest();

        //Assert
        System.assertEquals(true, result);

    }

    @isTest static void test_hasSObjectField_sobject_false(){
        //Arrange

        //Act
        test.startTest();
        Boolean result = SObjectHelper.hasSObjectField('test__c', new Account());
        test.stopTest();

        //Assert
        System.assertEquals(false, result);

    }

    @isTest static void test_hasSObjectField_sobject_true(){
        //Arrange

        //Act
        test.startTest();
        Boolean result = SObjectHelper.hasSObjectField('Name', new Account());
        test.stopTest();

        //Assert
        System.assertEquals(true, result);

    }

    @isTest static void test_setValue_fieldMap(){
        //Arrange
        Account a = new Account();
        Map<String, String> fieldValueMap = new Map<String, String>();
        fieldValueMap.put('Phone', '1234567890');
        fieldValueMap.put('Website','www.salesforce.com');
        fieldValueMap.put('Name', 'test account');
        fieldValueMap.put('Rating', 'Hot');
        fieldValueMap.put('AnnualRevenue', '1');
        fieldValueMap.put('Description', 'long text');
        fieldValueMap.put('OwnerId', UserInfo.getUserId());

        //Act
        test.startTest();
        Account result = (Account)SObjectHelper.setValue(a, fieldValueMap);
        test.stopTest();

        //Assert
        //System.assertNotEquals();
    }


}