/**
*
* @group Helper
*
* @description General helper class
*/
public class Helper {
    public enum SearchStyle {
        BEFORE,    //If there is no exact result, return the closest one before the needle
        AFTER,     //If there is no exact result, return the closest one after the needle
        EXACT //If there is no exact result, return null
    }
    
    public static final Integer STATUS_OK {
		get {
			return 200;
		}
	}
    public static final Integer STATUS_ERROR {
		get {
			return 500;
		}
	}
    public static final Integer STATUS_TIMEOUT {
		get {
			return 408;
		}
	}
    public static final Integer STATUS_NOTFOUND {
		get {
			return 404;
		}
	}

    public static final String YES {
		get {
			return 'Yes';
		}
	}
    public static final String NO {
		get {
			return 'No';
		}
	}

    //used to test non async in testing
    public static Boolean disableAsync = false;
    
    public static Date today {
        get{
            today = !Test.isRunningTest() ||
                        (Test.isRunningTest() && today == null) ? 
                        System.today() : 
                        today;

            return today;
        }
     set;
    }
    /**
    * @description - determines if futur/async methods can be called
    * @return true if async methods can be called
    */
    public static Boolean canExecuteAsync()
    {
        Boolean sysLimitation = !System.isBatch() && !System.isFuture() && !disableAsync;

        Integer numFutureCalls = Limits.getFutureCalls();
        Integer futureLimit = Limits.getLimitFutureCalls();
        Boolean limitAsync = false;

        limitAsync = futureLimit > 0 ? numFutureCalls / futureLimit > .95 : limitAsync;

        return sysLimitation && !limitAsync;
    }

    /**
     * @description Percentage of CPU Time Limit that a transaction can take
     */
    public static Decimal CPULimitThreshold
    {
        get
        {
            if(CPULimitThreshold == null)
            {
                CPULimitThreshold = Decimal.valueOf(KeySettingHelper.getKeySetting('CPU_Limit_Threshold').Value__c);
            }
            return CPULimitThreshold;
        }
        private set;
    }

    public static final String EMAILSUFFIX = '.invalid';

    /**
     * @description appends .invalid to an email
     * @param  email email to append .invalid
     * @return       updated email or null if the email is null
     */
    public static String dirtyEmail(String email)
    {
        if(!String.isBlank(email))
        {
            email = email + EMAILSUFFIX;
        }

        return email;
    }

    /**
     * @description             determine if the transaction time is within our acceptable range
     * @param  transactionTime amount of time the transaction took
     * @return                 true if percentage of time for transaction <= our threshold
     */
    public static Boolean determineCPUPerformance(Integer transactionTime)
    {
        return  Helper.getCPUPerformance(transactionTime) <= Helper.CPULimitThreshold;
    }

    /**
     * @description             calculate CPU Performance
     * @param  transactionTime amount of time the transaction took
     * @return                 percentage of CPU Limit transaction took
     */
    public static Decimal getCPUPerformance(Integer transactionTime)
    {
        return (transactionTime/Limits.getLimitCpuTime());
    }

    /**
    * @description checks if running user in a profile set
    * @param profiles - set of profile names that have permission
    * @param profileId - profile id that needs to be validated
    * @param contains - checking if profile exists in profiles or does not exist in profiles
    * @return true if running user is in profile set
    */
    public static Boolean validateProfilePermission(Set<String> profiles, String profileId, Boolean contains)
    {
        Profile profile = [SELECT Name
                            FROM Profile
                            WHERE Id = :profileId
                            LIMIT 1];

        return contains ? 
                profiles.contains(profile.Name) 
                : !profiles.contains(profile.Name);
    }

    /**
    * @description checks if running user in permission set
    * @param permissionSets - set of permission sets to check
    * @param userId - user id to check if has permission set
    * @return true if user assigned permission set
    */
    public static Boolean validatePermissionSetAssignment(Set<String> permissionSets, String userId)
    {
        List<PermissionSetAssignment> psas = [SELECT Id 
                                                FROM PermissionSetAssignment 
                                                WHERE PermissionSetId IN (SELECT Id 
                                                                            FROM PermissionSet 
                                                                            WHERE Name in :permissionSets) 
                                                    AND AssigneeId IN (SELECT Id 
                                                                        FROM User 
                                                                        WHERE Id = :UserInfo.getUserId()) 
                                            ];
        return psas.size() > 0;
    }

    /**
    * @description Retrieve a List of fieldnames for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A list of fieldnames
    */ 
    private static Map<String, List<String>> fieldsByObjectMap = new Map<String, List<String>>();
    public static List<String> getFields(Schema.DescribeSObjectResult objectType) {
        if (fieldsByObjectMap.get(String.valueOf(objectType)) == null) {
            Map<String, Schema.SObjectField> fieldMap = objectType.fields.getMap();
            List<String> fieldList = new List<String>();
            for(String k : fieldMap.keyset()) fieldList.add(String.valueOf(fieldMap.get(k)));
            fieldsByObjectMap.put(String.valueOf(objectType), fieldList);
        }
        return fieldsByObjectMap.get(String.valueOf(objectType));
    }

    /**
    * @description Retrieve a List of fieldnames with the object name as a prefix "Account.Name", etc for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A list of fieldnames
    */ 
    private static Map<String, List<String>> fieldsByObjectWithPrefixMap = new Map<String, List<String>>();
    public static List<String> getFieldsWithPrefix(Schema.DescribeSObjectResult objectType) {
        return getFieldsWithPrefix(objectType, false);
    }
    
    /**
    * @description Retrieve a List of fieldnames with the object name as a prefix "Account.Name", etc for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @param parentRelationshipFormat Boolean if set to true, will replace the prefix with the ParentRelationship format (e.g for Custom Objects __c -> __r)
    * @return A list of fieldnames
    */ 
    public static List<String> getFieldsWithPrefix(Schema.DescribeSObjectResult objectType, Boolean parentRelationshipFormat) {
        String prefix = objectType.getName();
        System.Debug('prefix : ' + prefix);
        System.Debug('parentRelationshipFormat : ' + parentRelationshipFormat);
        if(parentRelationshipFormat) {
            prefix = prefix.replaceAll('__c', '__r');
        }
        System.Debug('prefix : ' + prefix);
        if (fieldsByObjectWithPrefixMap.get(String.valueOf(prefix)) == null) {
            Map<String, Schema.SObjectField> fieldMap = objectType.fields.getMap();
            List<String> fieldList = new List<String>();
            for(String k : fieldMap.keyset()) fieldList.add(prefix + '.' + String.valueOf(fieldMap.get(k)));
            fieldsByObjectWithPrefixMap.put(String.valueOf(prefix), fieldList);
        }

        return fieldsByObjectWithPrefixMap.get(String.valueOf(prefix));
    }
    
    /**
    * @description Update User Map with User Details
    * @param NONE
    * @return Cached Map
    */ 
    private static Map<Id, User> userMap = new Map<Id, User>();
    public static Map<Id, User> getUserDetails(List<Id> userIds) {
        Set<Id> userSetInternal = new Set<Id>();
        for(Id userId : userIds) {
            if(!userSetInternal.contains(userId)) {
               userSetInternal.add(userId);
            }
        }
        if(!userSetInternal.isEmpty()) {
            Set<String> f = new Set<String>(Helper.getFields(Schema.SObjectType.User));
            f.remove('Address');
            f.remove('ProfilePhotoId');
            String userSelection = String.join(new List<String>(f), ',');
            String query = 'SELECT ' + userSelection + 
                ' FROM User ' +
                ' WHERE Id in :userSetInternal';
            userMap.putAll((List<User>) Database.query(query));
        }
        return userMap; 
    }
    
    /**
    * @description Get details for a User
    * @param userId
    * @return User
    */ 
    public static User getUserDetail(Id userId) {
        return Helper.getUserDetails(new List<Id>{userId}).get(userId);
    }
    
    /**
     * @description adds 2 decimals and handles if either or both of them are null
     * @param  value1 first value
     * @param  value2 second value
     * @return        0 if both values are null, either value is null returns other value
     */
    public static Decimal add(Decimal value1, Decimal value2)
    {
        if(value1 == null && value2 == null)
        {
            return 0;
        }
        else if(value1 == null)
        {
            return value2;
        }
        else if( value2 == null)
        {
            return value1;
        }

        return value1 + value2;        
    }
    
    
    /**
    * @description Retrieve a Map of fields for a given SObjectType
    * @param objectType SObjectType to retrieve fieldnames for
    * @return A Map of fieldnames to SObjectField
    */ 
    private static Map<String, Map<String, Schema.SObjectField>> fieldNameMapByObjectMap = new Map<String, Map<String, Schema.SObjectField>>();
    public static Map<String, Schema.SObjectField> getFieldsMap(Schema.DescribeSObjectResult objectType) {
        if (fieldNameMapByObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            fieldNameMapByObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.fields.getMap());
        }
        
        return fieldNameMapByObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }

    public static Map<String, Schema.SObjectField> getFieldsMap(Schema.SObjectType objectType) {
        if (fieldNameMapByObjectMap.get(String.valueOf(objectType)) == null) {
            fieldNameMapByObjectMap.put(String.valueOf(objectType), objectType.getDescribe().fields.getMap());
        }
        
        return fieldNameMapByObjectMap.get(String.valueOf(objectType));
    }
    
    /**
    * @description Retrieve a Map of fields for a given sObject
    * @param sObject the object
    * @return A Map of fieldnames to SObjectField
    */ 
    public static Map<String, Schema.SObjectField> getFieldsMapBySObject(sObject sObj) {
        //return getFieldsMap(sObj.getSObjectType().getDescribe());
        return getFieldsMap(sObj.getSObjectType());
    }
    
    /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType labels to RecordTypeInfo
    */ 
    private static Map<String, Map<String, Schema.RecordTypeInfo>> recordTypeInfosByObjectMap = new Map<String, Map<String, Schema.RecordTypeInfo>>();
    public static Map<String, Schema.RecordTypeInfo> getRecordTypeInfosByName(Schema.DescribeSObjectResult objectType) {
        if (recordTypeInfosByObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            recordTypeInfosByObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.getRecordTypeInfosByName());        
        }
        return recordTypeInfosByObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType developer names to RecordType
    */ 
    private static Map<String, Map<String, RecordType>> recordTypesByDeveloperNameMap = new Map<String, Map<String, RecordType>>();
    public static Map<String, RecordType> getRecordTypesByDeveloperName(Schema.DescribeSObjectResult objectType) {
        
        if (recordTypesByDeveloperNameMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            RecordType[] rts = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SObjectType = :objectType.getName() AND IsActive = TRUE];
            Map<String, RecordType> rtMap = new Map<String, RecordType>();
            for(RecordType rt : rts) {
                rtMap.put(rt.DeveloperName, rt);
            }
            recordTypesByDeveloperNameMap.put(String.valueOf(objectType.getKeyPrefix()), rtMap);        
        }
        return recordTypesByDeveloperNameMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    //For testing purposes, you can set the Production override by setting this static variable
    public static boolean isProductionOverride = false;
    public static boolean IsProduction() {
        if(isProductionOverride) {
            return true;
        }
        else {
            return ( UserInfo.getOrganizationId() == '00DE0000000IBOaMAO' );
        }
    }
    
     /**
    * @description Retrieve a Map of RecordType Names for a given SObjectType
    * @param objectType SObjectType to retrieve record types for
    * @return A Map of RecordType ids to RecordTypeInfo
    */ 
    private static Map<String, Map<Id, Schema.RecordTypeInfo>> recordTypeInfosByIdObjectMap = new Map<String, Map<Id, Schema.RecordTypeInfo>>();
    public static Map<Id, Schema.RecordTypeInfo> getRecordTypeInfosById(Schema.DescribeSObjectResult objectType) {
        if (recordTypeInfosByIdObjectMap.get(String.valueOf(objectType.getKeyPrefix())) == null) {
            recordTypeInfosByIdObjectMap.put(String.valueOf(objectType.getKeyPrefix()), objectType.getRecordTypeInfosById());        
        }
        return recordTypeInfosByIdObjectMap.get(String.valueOf(objectType.getKeyPrefix()));
    }
    
    /**
    * @description Meant to populate any sObject within a Map Id->Name
    * @param map String->String (String) Map
    * @param idToNameMap List of sObject
    * @param keyToMap String, value to use as the key
    * @param valueToMap String, value to use as the value for id
    * @return void
    */ 
    public static void addToMap(Map<String, String> idToNameMap, List<SObject> listToMap, String keyToMap, String valueToMap) {
        for(sObject obj : listToMap) {
            idToNameMap.put(String.valueOf(obj.get(keyToMap)), String.valueOf(obj.get(valueToMap)));
        }
    }


    /**
    * @description used to remove a set of fields from a query string, so the fields are not queried
    * @param string to remove the fields from
    * @param fields to be removed
    */
    public static String omitFields(String fields, Set<String> omitFields){
        if(String.isBlank(fields) || fields == null) return '';

        if(omitFields == null || omitFields.isEmpty()) return fields;
        fields = fields.replace(' ','');

        for(String field: omitFields){
            if(fields.containsIgnoreCase(',' + field)){
                fields = fields.replace(',' + field,'');
            }else if(fields.containsIgnoreCase(field + ',')){
                fields = fields.replace(field + ',','');              
            }else if(fields.containsIgnoreCase(', ' + field)){
                fields = fields.replace(', ' + field,'');
            }else if(fields.containsIgnoreCase(field + ', ')){
                fields = fields.replace(field + ', ','');
            }
        }
        return fields.trim();
    }


    /**
    * @description given a string it will produce a nice formatted number, if is decimal assumes 2 decimal places
    * @param string value of a number, either integer or decimal
    * @return nicely formatted number with ","
    */ 
    public static String formatNumber(String num){
        if(String.isBlank(num)) return '';

        String numFormatted = '';
        Integer len = num.length();
        Boolean containsDecimal = num.indexOf('.') > -1;
        if(len <= 6 && containsDecimal){//123.56
            numFormatted = num;
        }else if(len > 6 && containsDecimal){//1234.67
            numFormatted = formatNumber(num.substring(0, len-6)) + ',' + num.substring( len - 6,len);
        }else if(len > 3 && !containsDecimal){//1234567
            numFormatted = formatNumber(num.substring(0, len-3)) + ',' + num.substring( len - 3,len);
        }else{//123
            numFormatted = num;
        }
        return numFormatted;
    }

    /**
     * @description force insert and ignore unable to lock row exceptions
     * @param  o list of sobject records
     * @return   Database.SaveResult from the insert
     */
    public static Database.SaveResult[] forcedInsert(SObject[] o) {
        Database.SaveResult[] result;
        while (result == null) { 
            try { 
                result = Database.insert(o);
            } catch (DmlException e) {
                if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                    throw e;
                }
            }
        }
        return result;
    }

    /**
     * updateLogErrors executes Database.update and writes errors to the debug log
     * @param  records   records to be updated
     * @param  allOrNone specifies whether the operation allows partial success
     */
    public static void updateLogErrors(SObject[] records, Boolean allOrNone)
    {
        Helper.logErrors(Database.update(records, allOrNone));
    }

    /**
     * insertLogErrors executes Database.insert and writes errors to the debug log
     * @param  records   records to be inserted
     * @param  allOrNone specifies whether the operation allows partial success
     */
    public static void insertLogErrors(SObject[] records, Boolean allOrNone)
    {
        Helper.logErrors(Database.insert(records, allOrNone));
    }

    /**
     * logErrors logs the errors from Database.saveResult
     * @param  results save results from Update/Insert
     */
    public static void logErrors(List<Database.SaveResult> results)
    {
        for(Database.SaveResult sr: results)
        {
            if(!sr.isSuccess())
            {
                String msg = String.isBlank(sr.getId()) ? '' : sr.getId() + ': ';
                System.debug(LoggingLevel.ERROR, msg + String.join(sr.getErrors(),';'));
            }else
            {
                String msg = String.isBlank(sr.getId()) ? '' : sr.getId() + ': ';
                System.debug(LoggingLevel.INFO, sr.getId() + ' saved Successfully!');
            }
        }
    }

    /**
     * @description encode string for UTF-8
     * @param  stringValue string to encode
     * @return             UTF-8 encoded string
     */
    public static String urlEncode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.urlEncode(String.valueOf(stringValue),'UTF-8');
    }
    
    /**
     * @description decode string using UTF-8
     * @param  stringValue string to decode
     * @return             UTF-8 decoded string
     */
    public static String urlDecode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.urlDecode(String.valueOf(stringValue), 'UTF-8');
    }

    /**
     * @description encode string using base64
     * @param  stringValue string to encode
     * @return             base64 encode string
     */
    public static String base64Encode(String stringValue)
    {
        String returnString = '';
        if(String.isBlank(stringValue)) return returnString;
        return EncodingUtil.base64Encode(Blob.valueOf(stringValue));
    }

    /**
     * @description get date from a datetime value
     * @param  dt datetime value to get date from
     * @return    date instance
     */
    public static Date getDate(Datetime dt)
    {
        return Date.newInstance(dt.year(), dt.month(), dt.day());
    }

    /**
     * @description generates a cron expression
     * @param  min         minute job should run, Integer between 0 - 59, defaults to 0
     * @param  hour        hour job should run, Integer between 0-59, defaults to every hour  ('*')
     * @param  dayOfMonth  day of month job should run, Integer between 1-31, defaults to everyday ('*')
     * @param  month       month job should run, Integer between 1-12, defaults to every month ('*')
     * @param  dayOfWeek   day of the week job should run, 1-7 where 1 = Sunday, SUN-SAT, 7#2 = 2nd Saturday of the month, 6L = Last Friday of the month
	 * 						if you do anything other then 1-7, you must set dayOfMonth defaults to ?
     * @return             a string of the cron expression
     */
    public static String getCronExpression(Integer min, Integer hour, String dayOfMonth, Integer month, String dayOfWeek)
    {
        //default seconds to zero
        String cronExp = '0 '; 
        //default to run on the hour
        cronExp = min == null ? cronExp + '0 ' : cronExp + min + ' ';
        //default to run every hour
        cronExp = hour == null ? cronExp + '* ' : cronExp + hour + ' '; 
        //default to run everyday
        cronExp = String.isBlank(dayOfMonth) ? cronExp + '* ' : cronExp + dayOfMonth + ' ';
        //default to run every month
        cronExp = month == null ? cronExp + '* ' : cronExp + month + ' ';
        //default to unset
        cronExp = String.isBlank(dayOfWeek) ? cronExp + '?' : cronExp + dayOfWeek;

        return cronExp;
    }

    public static Map<String, String> createObjectMap(String obj)
    {
        Map<String, String> attributeMap = new Map<String, String>();
        for(String str: obj.split(','))
        {
            List<String> keyValue = str.contains('=') ? str.split('=') : str.split(':');
            String key = keyValue[0].replace('=', '').replace('{', '').replace('}','').replace('"','').trim();
            String value = keyValue.size() > 1 ? keyValue[1].replace('=', '').replace('{', '').replace('}','').replace('"','').trim() : '';
            attributeMap.put(key, value);
        }

        return attributeMap;
    }

    /**
    * @description consumes objects that are not identified in parsing
    * @param parser - the parser to consume the object from
    */
    public static void consumeObject(System.JSONParser parser) {
        Integer depth = 0;
        do {
            System.JSONToken curr = parser.getCurrentToken();
            if (curr == System.JSONToken.START_OBJECT || 
                curr == System.JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == System.JSONToken.END_OBJECT ||
                curr == System.JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }

    /**
    * @description ensures day of month does not exceed days in month
    * @param month - month to be validating
    * @param day - day of month
    * @param year - year that month resides in (leap year)
    * @return either day or last day of the given month
    */
    public static Integer checkEndOfMonth(Integer year, Integer month, Integer day)
    {
        System.debug(year +'-' + month + '-' + day);
        Date dt = Date.newInstance(year, month, day);
        if(dt.month() != month)
        {
            return Date.daysInMonth(year, month);
        }

        return day;
    }

    /**
    * @description      returns milliseconds based on date and time attributes provided
*                       if all parameters are null returns System.now().getTime()
    * @param dt         Date - if null uses today
    * @param hour       hour part of time if null uses 0
    * @param minute     minute part of time if null uses 0
    * @param seconds    seconds part of time if null uses 0
    * @return           Long value of the milliseconds
    */
    public static Long getTimeByDate(Date dt, Integer hour, Integer minute, Integer seconds)
    {
        if(dt == null
            && hour == null
            && minute == null
            && seconds == null)
        {
            return System.now().getTime();
        }

        //if dt is null use today
        dt = dt == null ? System.today() : dt;

        //if hour is null set to 0
        hour = hour == null ? 0 : hour;

        //if minute is null set to 0
        minute = minute == null ? 0 : minute;

        //if seconds is null set to 0
        seconds = seconds == null ? 0 : seconds;

        return Datetime.newInstance(dt.year(), dt.month(), dt.day(), hour, minute, seconds).getTime();
    }


    /**
    * @description determine if user is a partner user
    * @return true if they are a partner user
    */
    public static Boolean isPartnerUser()
    {
        return UserInfo.getUserType().containsIgnoreCase('Partner');
    }

    /**
     * @description     cast String to data type value
     * @param dataType  the data type the value should be cast to
     * @param strValue  value as a string
     * @return          value as its appropriate datatype
     */
    public static Object setValue(String datatype, String strValue)
    {
        Object value;
        if(String.isBlank(datatype)
            || datatype.equalsIgnoreCase('String')
            || String.isBlank(strValue))
        {
            value = strValue;
        }
        else if(datatype.equalsIgnoreCase('Integer'))
        {
            value = Integer.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Decimal'))
        {
            value = Decimal.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Date'))
        {
            value = Date.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('DateTime'))
        {
            value = DateTime.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Boolean'))
        {
            value = Boolean.valueOf(strValue);
        }
        else if(datatype.equalsIgnoreCase('Time'))
        {
            value = DateTime.valueOf(strValue).time();
        }

        return value;
    }

    /**
     * @description applies formatting for DateTime field for soql
     * @param  dt   DateTime to be formatted
     * @return      a string in format needed for soql
     * @created December 2019
     */
    public static String formatDateTimeSOQL(DateTime dt)
    {
        return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    /**
     * @description  encrypts using 256 and writes to debug logs to be put in Custom Metadatatypes 
     * @param  value string value to be encrypted
     */
    public static void encrypt(String value)
    {
        Blob encryptionKey = Crypto.generateAesKey(256);
        Blob keyChain = Crypto.generateAesKey(128);

        Blob data = Blob.valueOf(value);

        Blob encrypted = Crypto.encrypt('AES256', encryptionKey, keychain, data);

        System.debug(LoggingLevel.INFO, 'Keychain: ' +  EncodingUtil.base64encode(keyChain));
        System.debug(LoggingLevel.INFO, 'Encryption Key: ' + EncodingUtil.base64encode(encryptionKey));
        System.debug(LoggingLevel.INFO, 'Encrypted Data: ' + EncodingUtil.base64encode(encrypted));
    }

    public static String decrypt(String value, String key, String keychain)
    {
        return EncodingUtil.base64encode(Crypto.decrypt('AES256', EncodingUtil.base64decode(key), EncodingUtil.base64decode(keyChain), EncodingUtil.base64decode(value)));
    }

}