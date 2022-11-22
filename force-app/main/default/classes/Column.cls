/**
 * @description wrapper class for field in a form or table
 * @author      M Rainboldt
 * @created     July 2019
 */
public class Column {
    /**
     * @description ui label for field
     */
    @AuraEnabled
    public String label;

    /**
     * @description field name
     */
    @AuraEnabled
    public String name;

    /**
     * @description api name of the field
     */
    @AuraEnabled
    public String fieldName;

    /**
     * @description api name of controlling field
     */
    @AuraEnabled
    public String controllingField;

    /**
     * @description data type of the field
     */
    @AuraEnabled
    public String type;

    /**
     * @description true if field can be sorted
     */
    @AuraEnabled
    public boolean sortable;

    /**
     * @description true if field can be edited
     */
    @AuraEnabled
    public boolean editable;

    /**
     * @description true if field is required
     */
    @AuraEnabled
    public boolean required;

    /**
     * @description true if field is a lookup
     */
    public boolean isReferenceField;

    /**
     * @description detail attributes for date, currency fields
     */
    @AuraEnabled
    public TypeAttribute  typeAttributes;

    /**
     * @description picklist field options
     */
    @AuraEnabled
    public List<Option>  options;

    /**
     * @description default value for the field
     */
    @AuraEnabled
    public String defaultValue;    

    /**
     * @description value for the field
     */
    @AuraEnabled
    public String value;

    /**
     * @description max length for the field input
     */
    @AuraEnabled
    public Integer maxLength;

    /**
     * @description true if the field input is valid
     */
    @AuraEnabled
    public boolean isValid;

    @AuraEnabled
    public Map<String, List<String>> picklistMappings;

    public Column(){}

    public Column(Schema.FieldSetMember f) 
    {
        this.required = f.DBRequired;
        this.fieldName = f.fieldPath;
        this.label = f.label;
        this.required = f.required;
        this.type = ('' + f.getType()).toLowerCase();
        this.sortable = true;
        this.editable = false;
        this.isValid = true;
        this.setType();
        this.options = new List<Option>();
        Schema.DescribeFieldResult dfr = f.getSObjectField().getDescribe();
        this.maxLength = dfr.getLength();
        if(dfr.getController() != null)
        {
            this.controllingField = dfr.getController().getDescribe().getLocalName();
        }
    }

    public Column(Schema.FieldSetMember f, String sobjectApiName) 
    {
        this(f);
        if(this.controllingField != null)
        {
            this.picklistMappings = SObjectHelper.getPicklistFieldDependencies(sobjectApiName, this.controllingField, this.fieldName);
            this.options = new List<Option>();
        }
    }

    /**
     * @description sets the data type for output/input fields and data tables
     */
    private void setType()
    {
        System.debug(LoggingLevel.INFO, 'Field: ' + this.fieldName + '; Type: ' + this.type);
        if(this.type == 'date')
        {
            this.type = 'date-local';
        }else if(this.type == 'picklist')
        {
            this.type = 'combobox';
        }else if(this.type == 'boolean')
        {
            this.type = 'checkbox';
        }
        else if(this.type == 'double')
        {
            this.type = 'number';
        }
        // else if(this.type == 'reference')
        // {
        //     this.isReferenceField = true;
        //     // String relatedField = this.fieldName.replace('__c', '__r') + '.Name';
        //     // relatedField = relatedField.replace('Id.', '.');
        //     // this.fieldName = relatedField;
        //     this.type = 'url';
        //     this.typeAttributes = new TypeAttribute().getUrl(this.fieldName);
        // }
    }

    /*@TestVisible
    private Column(SObjectField field)
    {
        Schema.DescribeFieldResult describe = field.getDescribe();
        this.required = false;
        this.fieldName = describe.getName();
        this.label = describe.getLabel();
        this.required = false;
        this.type = String.valueOf(describe.getType());        
        this.sortable = true;
        this.editable = false;
    }
    */

    /**
     * @description         if the field should be required
     * @param  DBRequired   true if the field should be required
     */
    public void setRequired(Boolean DBRequired) {
        this.required = DBRequired;
    }

    /**
     * @description set type attributes to assist in rendering
     */
    public class TypeAttribute{
        /**
         * @description month format
         */
        @AuraEnabled
        public String month;

        /**
         * @description year format
         */
        @AuraEnabled
        public String year;
        
        /**
         * @description day format
         */
        @AuraEnabled
        public String day;
        
        /**
         * @description currency iso code
         */
        @AuraEnabled
        public String currencyCode;

        /**
         * @description for hyperlinks
         */
        @AuraEnabled
        public String label;
        
        @AuraEnabled
        public String target;
        
        /**
         * @description tooltip to be displayed
         */
        @AuraEnabled
        public String tooltip;

        public TypeAttribute(){}

        /**
         * @description      formats url attributes
         * @param  fieldName name of field for the url label
         * @return           a type attribute for a url
         */
        public TypeAttribute getUrl(String fieldName)
        {
            TypeAttribute attr = new TypeAttribute();
            attr.label = fieldName;
            attr.target = '_blank';
            attr.tooltip = fieldName;
            return attr;
        }
    }

}