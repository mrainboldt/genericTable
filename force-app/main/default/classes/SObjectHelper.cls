/**
*
* @group Helper
*
* @description general helper class for SObjects
*/
public with sharing class SObjectHelper {
    /**
     * @description error code when duplicates have been detected in the system
     */
    public static final String DUPLICATES_DETECTED
    {
        get{
            return 'DUPLICATES_DETECTED';
        }
    }
    /**
     * @description error code when system could not get exclusive rights
     */
    public static final String UNABLE_TO_LOCK_ROW
    {
        get{
            return 'UNABLE_TO_LOCK_ROW';
        }
    }
    
    /**
     * @description error code when system runsout of cpu time out
     */
    public static final String APEX_CPU_TIMEOUT
    {
        get{
            return 'Apex CPU time limit exceeded';
        }
    }

    public static final Map<String, String> ALTERNATE_RELATIONSHIP_NAME_MAP = new Map<String, String>{
        'Case' => 'Subject'
    };

    private static Map<String, Map<String, Id>> sobjectRecordTypeMap {get; set;}

    private static Map<String, Map<String, Schema.SObjectField>> sObjectFieldMap = new Map<String, Map<String, Schema.SObjectField>>();

	private static Map<String, List<Schema.FieldSetMember>> sObjectFieldSetMap = new Map<String, List<Schema.FieldSetMember>>();

	private static Map<String, Schema.SObjectType> sObjectTypeMap{
		get{
			if(sObjectTypeMap == null){
				sObjectTypeMap = Schema.getGlobalDescribe();
			}
			return sObjectTypeMap;
    	}
    	private set;
    }
    
    /**
     * @description get the object api name from the record id
     * @param  recordId 15 or 18 char record id
     * @return          api name of object
     */
    public static String getObjectName(Id recordId)
    {
        return recordId.getSobjectType().getDescribe().getName();
    }

    /**
    * @description retrieve the schema.SobjectType by object name string
    * @param objectAPIName: object API name string
    * @return schema.SobjectType      
    */
	public static schema.SobjectType getSObjectTypeByName(String objectAPIName){
    	return sObjectTypeMap.get(objectAPIName);
	}

    /**
    * @description generate a map field map of all accessible fields by object type
    * @param objectAPIName: the object to generate the field map from
    * @return String      
    */
    public static Map<String, Schema.SObjectField> getSObjectFieldMapByObjectName(String objectAPIName){
		Map<String, Schema.SObjectField> allAccessibleFieldsMap = new Map<String, Schema.SObjectField>();
		if(sObjectFieldMap.containsKey(objectAPIName)){
			allAccessibleFieldsMap = sObjectFieldMap.get(objectAPIName);
		}
		else{
			Map<String, Schema.SObjectField> sObjectFielMap = sObjectTypeMap.get(objectAPIName).getDescribe().fields.getMap();
			for(String sObjFieldName : sObjectFielMap.keySet()){
				Schema.SObjectField sObjectField = sObjectFielMap.get(sObjFieldName);
				if(sObjectField.getDescribe().isAccessible()){
					allAccessibleFieldsMap.put(sObjFieldName, sObjectField);
				}
			}
			sObjectFieldMap.put(objectAPIName, allAccessibleFieldsMap);
		}
    	return allAccessibleFieldsMap;
    }
    
    /**
    * @description get active picklist values of the provided picklist field
    * @param objectAPIName: the object to the piclist field belongs to 
    * @param fieldAPIName: the api name of the picklist field
    * @return List of Schema.PicklistEntry records of each picklist value associated with the field       
    */
    public static List<Schema.PicklistEntry> getPicklistValues(String objectAPIName, String fieldAPIName){
        Schema.DescribeFieldResult fieldResult = sObjectTypeMap.get(objectAPIName).getDescribe().fields.getMap().get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> picklistVals = new List<Schema.PicklistEntry>();
        for(Schema.PicklistEntry ple : fieldResult.getPicklistValues()){
            if(ple.isActive()){
                picklistVals.add(ple);
            }
        }
        return picklistVals;
    }
    
    /**
    * @description                      generate field list ot be used in dynamic query strings
    * @param objectName:                the object to query
    * @param includeRelationshipFields: if true, relationship fields are added to the query
    * @return String      
    */
    public static String generateQueryStringByObjectName(String objectName, Boolean includeRelationshipFields){
        return generateQueryStringByObjectNameFullSOQL(objectName, includeRelationshipFields, true);
    }

    /**
    * @description                      generate field list ot be used in dynamic query strings
    * @param objectName:                the object to query
    * @param includeRelationshipFields: if true, relationship fields are added to the query
    * @param includeSelectFrom:         if true, includes SELECT and FROM + objectName
    * @return String      
    */
    public static String generateQueryStringByObjectNameFullSOQL(String objectName, Boolean includeRelationshipFields, Boolean includeSelectFrom){
        Map<String, Schema.SObjectField> allFields = getSObjectFieldMapByObjectName(objectName);
        String queryString = includeSelectFrom ? 'SELECT ' : '';
        for(String fieldAPIName : allFields.keySet()){
            Schema.SObjectField thisField = allFields.get(fieldAPIName);
            queryString += fieldAPIName+',';
            if(includeRelationshipFields){
                if('REFERENCE'.equalsIgnoreCase(String.valueOf(thisField.getDescribe().getType())))
                {
                    queryString += SObjectHelper.getSOQLNameField(fieldAPIName, objectName);
                }
            }
        }
        if(queryString.right(1) == ','){
            queryString = queryString.subString(0, queryString.length() - 1); //remove trailing comma
        }
        if(includeSelectFrom)
        {
            queryString += ' FROM '+objectName;
        }
        system.debug('@@@generateQueryStringByObjectName queryString: '+queryString);
        return queryString;
    }

    public static String getSOQLNameField(String fieldAPIName, String objectName)
    {
        System.debug('getSOQLNameField objectName: '+objectName);
        System.debug('getSOQLNameField objectName: '+fieldAPIName);
        getSObjectFieldMapByObjectName(objectName);
        String nameField = '';
        if(fieldAPIName.endsWith('__c') 
            && (!objectName.endsWith('__mdt') 
                || String.isBlank(objectName))
            )
        {
            String relatedObjectType = 
                sObjectFieldMap.get(objectName).get(fieldAPIName.toLowerCase()).getDescribe().getReferenceTo()[0].getDescribe().getName(); //this could return a list of multiple objects (ex. Activity obj)
            
            String relationshipNameField = 
                ALTERNATE_RELATIONSHIP_NAME_MAP.containsKey(relatedObjectType) 
                    ? ALTERNATE_RELATIONSHIP_NAME_MAP.get(relatedObjectType)
                    : 'Name';

            nameField = fieldAPIName.removeEnd('__c') +  '__r.'+relationshipNameField+',';

        }
        else if(fieldAPIName.endsWith('__c') 
                && objectName.endsWith('__mdt')
                )
        {
            nameField = fieldAPIName.removeEnd('__c') +  '__r.MasterLabel,';
            nameField = fieldAPIName.removeEnd('__c') +  '__r.DeveloperName,';
        }
        else if('Id'.equalsIgnoreCase(fieldAPIName.right(2)))
        {
            String baseFieldName = fieldAPIName.subString(0, fieldAPIName.length() - 2);
            nameField = baseFieldName+'.Name,';
            if('RecordTypeId'.equalsIgnoreCase(fieldAPIName)){
                nameField += baseFieldName+'.DeveloperName,';
            }
        }

        return nameField;
    }

    /**
    * @description generate a simplified map of field api name to the correspoing Schema.FieldSetMember object
    * @param objectAPIName: name of the object related to the field set
    * @param fieldSetName: name of the field set
    * @return map of field api name => Schema.FieldSetMember object      
    */
    public static Map<String, Schema.FieldSetMember> getSimplifiedFieldSetMapByFieldSetName(String objectAPIName, String fieldSetName){
        Map<String, Schema.FieldSetMember> simpleMap = new Map<String, Schema.FieldSetMember>();
        for(Schema.FieldSetMember fsm : getFieldSetMembersByFieldSetName(objectAPIName, fieldSetName) ){
            simpleMap.put(fsm.getFieldPath(), fsm);
        }
        return simpleMap;
    }

    /**
    * @description query all fields associated with a given field set
    * @param objectAPIName: name of the object related to the field set
    * @param fieldSetName: name of the field set
    * @return List of Schema.FieldSetMember objects     
    */
    public static List<Schema.FieldSetMember> getFieldSetMembersByFieldSetName(String objectAPIName, String fieldSetName){

		List<Schema.FieldSetMember> fields;

		List<String> fieldNames = new List<String>();

        String mapKey = objectAPIName+fieldSetName;

		if(sObjectFieldSetMap.containsKey(mapKey)){
			fields = sObjectFieldSetMap.get(mapKey);
		}
		else{
            try{
                Schema.SObjectType sObjectType = getSObjectTypeByName(objectAPIName);
                Schema.DescribeSObjectResult description = sObjectType.getDescribe();
                Schema.FieldSet fieldSet = description.FieldSets.getMap().get(fieldSetName);
                fields = fieldSet.getFields();
                sObjectFieldSetMap.put(mapKey, fields);
            }
            catch(Exception ex){
                throw new SObjectException(
                    'Unable to locate fieldset with name: '
                    +fieldSetName
                    +' for object: '
                    +objectAPIName
                    +'. Error: '
                    +ex.getMessage()
                );
            }
		}

		return fields;
    }
    
    /**
    * @description get the default record type assigned to an object
    * @param objectAPIName: name of the object related to the field set
    * @return Schema.RecordTypeInfo record of the default record type     
    */
    public static Schema.RecordTypeInfo getDefaultRecordType(String objectAPIName){
        Schema.RecordTypeInfo defaultRT;
        for(Schema.RecordTypeInfo rti : getActiveRecordTypes(objectAPIName)){
            if(rti.isDefaultRecordTypeMapping()) {
                defaultRT = rti;
                break;
            }
        }
        return defaultRT;
    }

    /**
    * @description get all active record types assigned to an object
    * @param objectAPIName: name of the object related to the field set
    * @return List Schema.RecordTypeInfo records   
    */
    public static List<Schema.RecordTypeInfo> getActiveRecordTypes(String objectAPIName){
        List<Schema.RecordTypeInfo> rtList = sObjectTypeMap.get(objectAPIName).getDescribe().getRecordTypeInfos();
        List<Schema.RecordTypeInfo> activeRTs = new List<Schema.RecordTypeInfo>();
        if(!rtList.isEmpty()){
            for(Schema.RecordTypeInfo rti : rtList){
                if(rti.isActive()){
                    activeRTs.add(rti);
                }
            }
        }
        return activeRTs;
    }
    
    /**
    * @description return true if a field value is different between two objects, false otherwise
    * @param rec1: first object to compare field value against
    * @param rec2: second object to compare field value against
    * @param fieldName: name of field to compare values
    * @return Boolean     
    */
    public static Boolean fieldValueChanged(SObject rec1, SObject rec2, String fieldName){
        Object val1 = rec1 != null
            ? (rec1.get(fieldName) != null
                ? rec1.get(fieldName)
                : '')
            : '';

        Object val2 = rec2 != null 
            ? (rec2.get(fieldName) != null
                ? rec2.get(fieldName)
                : '')
            : '';

        if(val1 != val2){
            return true;
        }
        return false;
    }
    
    /**
    * @description return true if a field value is different between two objects, false otherwise
    * @param objectAPIName: fname of the object to get the share object name from
    * @return String share object name     
    */
    public static String getShareObjectNameByObjectName(String objectAPIName){
        String shareObjectName;
        if(sObjectTypeMap.get(objectAPIName).getDescribe().isCustom()){
            if(objectAPIName == 'Program_Activity__c'){
                shareObjectName = 'Milestone__Share';
            }
            else if(objectAPIName == 'Operation_Team_Member__c'){
                shareObjectName = 'Operation__Share';
            }
            else{
            	shareObjectName = objectAPIName.removeEnd('__c') +  '__Share';    
            }
        }
        else{
            shareObjectName = objectAPIName+'Share';
        }
        return shareObjectName;
    }

    /**
    * @description: Uses a specified field id to create a one-to-many mapping of the objects.  The returned values is castable (ex Map<Id, List<Increment__c>>)
    */
    public static Map<Id, List<SObject>> groupByIdField(List<SObject> objects, String fieldName) {
        if (objects == NULL || fieldName == NULL) return new Map<Id, List<SObject>>();

        Map<Id, List<SObject>> objectMap = new Map<Id, List<SObject>>();

        for (SObject o : objects) {
            Id i = (Id) o.get(fieldName);
            if (!objectMap.containsKey(i)) {
                objectMap.put(i, new List<SObject>());
            }
        }

        for (SObject o : objects) {
            Id i = (Id) o.get(fieldName);
            objectMap.get(i).add(o);
        }

        return objectMap;
    }


    /**
    * @description: Description: Uses a specified field (as a string) to create a one-to-many mapping of the objects.  The returned values is castable (ex Map<String, List<Increment__c>>)
    */
    public static Map<String, List<SObject>> groupByField(List<SObject> objects, String fieldName) {
        if (objects == NULL || fieldName == NULL) return new Map<String, List<SObject>>();

        Map<String, List<SObject>> objectMap = new Map<String, List<SObject>>();

        for (SObject o : objects) {
            String i = String.valueOf(o.get(fieldName));
            if (!objectMap.containsKey(i)) {
                objectMap.put(i, new List<SObject>());
            }
        }

        for (SObject o : objects) {
            String i = String.valueOf(o.get(fieldName));
            objectMap.get(i).add(o);
        }

        return objectMap;
    }


    /**
    * @description:  Uses a specified field (as a string) to create a one-to-one mapping of the objects.  The returned values is NOT castable.  Only lists are castable
    */
    public static Map<String, SObject> mapByField(List<SObject> objects, String fieldName) {
        if (objects == NULL || fieldName == NULL) return new Map<String, SObject>();

        Map<String, SObject> objectMap = new Map<String, SObject>();

        for (SObject o : objects) {
            String i = String.valueOf(o.get(fieldName));
            if (i != null) {
                objectMap.put(i, o);
            }
        }

        return objectMap;
    }


    /**
    * @description:  Uses a specified field id to create a one-to-one mapping of the objects.  The returned values is NOT castable.  Only lists are castable
    */
    public static Map<Id, SObject> mapByIdField(List<SObject> objects, String fieldName) {
        if (objects == NULL || fieldName == NULL) return new Map<Id, SObject>();

        Map<Id, SObject> objectMap = new Map<Id, SObject>();

        for (SObject o : objects) {
            if (o.get(fieldName) != null) {
                Id i = Id.valueOf((String) o.get(fieldName));
                objectMap.put(i, o);
            }
        }

        return objectMap;
    }


    /**
    * @description:  Creates a set of id's from the specified field.  The field must contain valid ids, even if they are stored as strings.
    */
    public static Set<Id> collectIdsByField(List<SObject> objects, String fieldName) {
        if (objects == NULL) return new Set<Id>();

        Set<Id> ids = new Set<Id>();

        for (SObject o : objects) {
            if (o.get(fieldName) != null) {
                Id i = Id.valueOf(String.valueOf(o.get(fieldName)));
                if (i != NULL) {
                  ids.add(i);
                }
            }
        }

        return ids;
    }


    /**
    * @description:  Collects the inner-objects (one-to-many) stored on each object's field.  The return value is castable (ex List<Increment__c>)
    */     
    public static List<SObject> collectSObjectsByField(List<SObject> objects, String fieldName) {
        if (objects == NULL) return new List<SObject>();

        Set<SObject> collection = new Set<SObject>();

        for (SObject o : objects) {
            SObject subcollection = o.getSObject(fieldName);
            if (subcollection != NULL) {
              collection.add (subcollection);
            }
        }

        return new List<SObject>(collection);
    }

    /**
    * @description:  Collects the list of lookup-objects (one-to-one) stored on each object's field.  The return value is castable (ex List<Increment__c>)
    */ 
    public static List<SObject> collectAllSObjectsByField(List<SObject> objects, String fieldName) {
        if (objects == NULL) return new List<SObject>();

        Set<SObject> collection = new Set<SObject>();

        for (SObject o : objects) {
            SObject[] subcollection = o.getSObjects(fieldName);
            if (subcollection != NULL) {
              collection.addAll (subcollection);
            }
        }

        return new List<SObject>(collection);
    }

    public static String getRecordTypeID(String obj, String rtName){
        if(String.isBlank(obj)) throw new SObjectException('An object name is required to get a record type Id.');
        if(String.isBlank(rtName)) throw new SObjectException('A record type name is required to get a record type Id.');
        String rtId;
        
        if(sobjectRecordTypeMap == null)
        {
            sobjectRecordTypeMap = new Map<String, Map<String, Id>>();
        }

        if(sobjectRecordTypeMap.containsKey(obj))
        {
            rtId = sobjectRecordTypeMap.get(obj).get(rtName);
        }else
        {            
            sobjectRecordTypeMap.put(obj, new Map<String, Id>());

        }

        if(rtId == null)
        {
            rtId = Schema.getGlobalDescribe().get(obj).getDescribe().getRecordTypeInfosByDeveloperName().get(rtName).getRecordTypeId();
            sobjectRecordTypeMap.get(obj).put(rtName, rtId);
        }

        return rtId;
    }

    /**
    * @description updates the field on the provided object to the given value
    * @param any sObject, field on object, value
    * @return an updated object
    */ 
    public static SObject setValue(SObject obj, String field, String value){
        return setValue(obj, new Map<String, String>{field => value});
    }

    /**
    * @description updates the fields provided as keys in the map on the object to the values in the map
    * @param any sObject, field => value map to update the object
    * @return an updated object
    */ 
    public static SObject setValue(SObject obj, Map<String, String> fieldValueMap){
        Schema.SObjectType objType = obj.getSObjectType();
        Map<String, Schema.SObjectField> fieldsMap = Helper.getFieldsMap(objType.getDescribe());

        for(String field: fieldValueMap.keySet()){
            String value = fieldValueMap.get(field);
            //if(String.isBlank(value))continue;

            Schema.DescribeFieldResult fd = fieldsMap.get(field).getDescribe();
            Schema.DisplayType sdt = fd.getType();               
            if(String.isBlank(value)){
                if(sdt === Schema.DisplayType.Boolean){
                    obj.put(field,false);
                }else{
                    obj.put(field,null);
                }
                continue;
            }
            if(sdt == Schema.DisplayType.Currency ||
                sdt == Schema.DisplayType.Double ||
                sdt == Schema.DisplayType.Percent) {
                obj.put(field, Decimal.valueOf(value) );
            } else if(sdt == Schema.DisplayType.Phone ||
                        sdt == Schema.DisplayType.Combobox ||
                        sdt == Schema.DisplayType.EncryptedString ||
                        sdt == Schema.DisplayType.Email ||
                        sdt == Schema.DisplayType.ID ||
                        sdt == Schema.DisplayType.MultiPicklist ||
                        sdt == Schema.DisplayType.Reference ||
                        sdt == Schema.DisplayType.Picklist ||
                        sdt == Schema.DisplayType.String ||
                        sdt == Schema.DisplayType.TextArea ||
                        sdt == Schema.DisplayType.URL) {
                obj.put(field,String.valueOf(value));
            }else if(sdt == Schema.DisplayType.Boolean){
                Boolean val = !String.isBlank(value) && value.equalsIgnoreCase('true') ? true : false;
                obj.put(field,val);
            }else if(sdt == Schema.DisplayType.Date){
                obj.put(field,Date.valueOf(value));                    
            }else if(sdt == Schema.DisplayType.DateTime){
                obj.put(field, (DateTime)json.deserialize('"' + value + '"', datetime.class));
            }       

        }
        
        return obj;
    }

    /**
    * @description check if an Sobject has a field
    * @param fieldName - the name of the field you want to see exists
    * @param objName - the api name of the object you are checking for the field
    */
    public static boolean hasSObjectField(String fieldName, String objName){
        SObject so = Schema.getGlobalDescribe().get(objName).newSObject();
        return hasSObjectField(fieldName, so);
    }

    /**
    * @description check if an Sobject has a field
    * @param fieldName - the name of the field you want to see exists
    * @param objName - the object you are checking for the field
    */
    public static boolean hasSObjectField(String fieldName, SObject so){
        fieldName = fieldName.toLowerCase();
        return so.getSobjectType().getDescribe().fields.getMap().keySet().contains(fieldName);
    }



    public class OrderedMap {
        private SObject[] internalList = new List<SObject>();
        private Map<Id, SObject> internalMap = new Map<Id, SObject>();

        public OrderedMap() {
        }

        public OrderedMap(SObject[] objects) {
            addAll(objects);
        }

        public OrderedMap(Map<Id, SObject> objectMap) {
            putAll(objectMap);
        }

        public void addAll(SObject[] objects) {
            for (SObject o : objects) {
                if (!internalMap.containsKey(o.id)) {
                    internalMap.put(o.id, o);
                    internalList.add(o);
                }
            }
        }

        public void putAll(Map<Id, SObject> objectMap) {
            for (SObject o : objectmap.values()) {
                if (!internalMap.containsKey(o.id)) {
                    internalMap.put(o.id, o);
                    internalList.add(o);
                }
            }
        }

        public SObject get(Integer i) {
            return internalList.get(i);
        }

        public SObject get(Id id) {
            return internalMap.get(id);
        }

        public Map<Id, SObject> toMap() {
          return internalMap.clone();
        }

        public Set<Id> keySet() {
            return internalMap.keySet();
        }

        public List<SObject> values() {
            return internalList.clone();
        }

        public void sort() {
            internalList.sort();
        }

        public Boolean containsKey(Id id) {
            return internalMap.containsKey(id);
        }

        public Boolean contains(SObject o) {
            return containsKey(o.Id);
        }

        public Boolean equals(Map<Id, SObject> other) {
            return internalMap.equals(other);
        }

        public Boolean equals (List<SObject> other) {
            return internalList.equals(other);
        }
    }

    public static final List<String> systemFields = new List<String> {
        'IsDeleted',
        'CreatedById',
        'CreatedDate',
        'LastModifiedById',
        'LastModifiedDate',
        'SystemModstamp',
        'LastViewedDate',
        'LastReferencedDate'
    };

    public static Map<String, List<String>> getPicklistFieldDependencies(String objectName, String controllingField, String dependentField)
    {
        Map<String, List<String>> controllingInfo = new Map<String, List<String>>();

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);

        Schema.DescribeSObjectResult describeResult = objType.getDescribe();
        Schema.DescribeFieldResult controllingFieldInfo = describeResult.fields.getMap().get(controllingField).getDescribe();
        Schema.DescribeFieldResult dependentFieldInfo = describeResult.fields.getMap().get(dependentField).getDescribe();

        List<Schema.PicklistEntry> controllingValues = controllingFieldInfo.getPicklistValues();
        List<Schema.PicklistEntry> dependentValues = dependentFieldInfo.getPicklistValues();

        for(Schema.PicklistEntry currControllingValue : controllingValues)
        {
            //System.debug('ControllingField: Label:' + currControllingValue.getLabel());
            controllingInfo.put(currControllingValue.getLabel(), new List<String>());
        }

        for(Schema.PicklistEntry currDependentValue : dependentValues)
        {
            String jsonString = JSON.serialize(currDependentValue);

            Map<String, Object> info = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

            String hexString = EncodingUtil.convertToHex(EncodingUtil.base64Decode(String.valueOf(info.get('validFor')))).toUpperCase();

            //System.debug('DependentField: Label:' + currDependentValue.getLabel() + ' ValidForInHex:' + hexString + ' JsonString:' + jsonString);

            Integer baseCount = 0;

            for(Integer curr : hexString.getChars())
            {
                Integer val = 0;

                if(curr >= 65)
                {
                    val = curr - 65 + 10;
                }
                else
                {
                    val = curr - 48;
                }

                if((val & 8) == 8)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 0].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 0].getLabel()).add(currDependentValue.getLabel());
                }
                if((val & 4) == 4)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 1].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 1].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 2) == 2)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 2].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 2].getLabel()).add(currDependentValue.getLabel());                    
                }
                if((val & 1) == 1)
                {
                    //System.debug('Dependent Field: ' + currDependentValue.getLabel() + ' Partof ControllingField:' + controllingValues[baseCount + 3].getLabel());
                    controllingInfo.get(controllingValues[baseCount + 3].getLabel()).add(currDependentValue.getLabel());                    
                }

                baseCount += 4;
            }            
        } 

        System.debug('ControllingInfo: ' + controllingInfo);

        return controllingInfo;
    }

    public class SObjectException extends Exception{}

}