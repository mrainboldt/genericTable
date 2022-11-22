/**
 * @description controller for LightningTable component
 * @author      M Rainboldt
 * @created     July 2019
 */
public with sharing class LightningTableController {
    
    /**
     * @description          initializes attributes needed to render component
     * @param  recordId      Id of record component is rendered on
     * @param  relatedField  field on related object that should equal recordId
     * @param  relatedObject object to SOQL
     * @param  fieldSetName  api name of field set to establish columns and soql
     * @param  whereClause   whereClause description
     * @param  recLimit      additional query parameters besides matching on relatedField
     * @param  sortBy        field to sort by
     * @param  sortDirection direction to sort records
     * @return               a table wrapper with all the information to render a table/form in the ui
     */
    @AuraEnabled(cacheable=true)
    public static TableWrapper initTable(String recordId, String relatedField, String relatedObject, String fieldSetName, String whereClause, Integer recLimit, String sortBy, String sortDirection)
    {
        TableWrapper table = new TableWrapper(recordId
                                            , relatedField
                                            , relatedObject
                                            , fieldSetName
                                            , whereClause
                                            , recLimit
                                            , sortBy
                                            , sortDirection);

        return table;
    }

    @AuraEnabled(cacheable=true)
    public static String initTableJSON(String recordId, String relatedField, String relatedObject, String fieldSetName, String whereClause, Integer recLimit, String sortBy, String sortDirection)
    {
        TableWrapper table = new TableWrapper(recordId
                                            , relatedField
                                            , relatedObject
                                            , fieldSetName
                                            , whereClause
                                            , recLimit
                                            , sortBy
                                            , sortDirection);

        return JSON.serialize(table);
    }

    /**
     * @description get table wrapper for a single record based on Id
     * @param  recordId      Id of record in to retrieve
     * @param  fieldSetName  api name of field set
     * @param  sObjectName SObject api name for record
     * @return               tableWrapper
     */
    @AuraEnabled(cacheable=true)
    public static TableWrapper initTableForRecord(String recordId, String fieldSetName, String sObjectName)
    {
        System.debug(LoggingLevel.INFO, recordId);
        System.debug(fieldSetName);
        System.debug(sObjectName);
        TableWrapper table = new TableWrapper(recordId
                                            , 'Id'
                                            , sObjectName
                                            , fieldSetName
                                            , null
                                            , 1
                                            , null
                                            , null);

        return table;
    }

    /**
     * @description  re query records
     * @param  table table to refresh
     * @return       most recent version of records
     */
    @AuraEnabled
    public static List<SObject> refreshRecords(TableWrapper table)
    {
        return table.refreshRecords();
    }

    /**
     * @description        loads all the records for the table
     * @param  fieldSOQL   concatenation of fields for soql
     * @param  sObjectType object to soql
     * @param  whereClause filter for soql
     * @return             all records that satisfy soql
     */
    @AuraEnabled
    public static List<SObject> loadAllRecords(String fieldSOQL, String sObjectType, String whereClause)
    {
        whereClause = whereClause.split('LIMIT')[0];
        return Database.query(TableWrapper.getQuery(fieldSOQL, sObjectType, whereClause));
    }

    /**
     * @description get fieldset members for the given field set on the given object
     * @param  objectApiName api name of SObject
     * @param  fieldSetName  api name of fieldset
     * @return               serialized list of field set members
     */
    @AuraEnabled(cacheable=true)
    public static String getFieldSetMembers(String objectApiName, String fieldSetName)
    {
        return JSON.serialize(SObjectHelper.getFieldSetMembersByFieldSetName(objectApiName, fieldSetName));
    }

    /**
     * @description save records from the UI
     * @param  workRecordsJson serialization of recoords
     * @return                 the saved records
     */
    @AuraEnabled
    public static void saveRecords(String recordsJson){
        try {
            System.debug(recordsJson);
            List<SObject> records = (List<SObject>)JSON.deserialize(recordsJson, List<SObject>.class);
            update records;

            //return records;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

}