/**
 * @description wrapper class for picklist values
 * @author M Rainboldt
 * @date July 2019
 */
public class Option {
	@AuraEnabled public String label {get; set;}
	@AuraEnabled public String value {get; set;}
	@AuraEnabled public Boolean isDefault {get; set;}
	@AuraEnabled public Boolean isActive {get; set;}

	/**
	 * constructor
	 * @param label - label to be displayed to user
	 * @param value - value to be saved
	 * @param isDefault - true if is default value
	 * @return new Option
	 */
	public Option(String label
				, String value
				, Boolean isDefault)
	{
		this.label = label;
		this.value = value;
		this.isDefault = isDefault;
	}

	/**
	 * constructor
	 * @param label - label to be displayed to user
	 * @param value - value to be saved
	 * @param isDefault - true if is default value
	 * @param isActive - displays has available
	 * @return new Option
	 */
	public Option(String label
				, String value
				, Boolean isDefault
				, Boolean isActive) 
	{
		this.label = label;
		this.value = value;
		this.isDefault = isDefault;
		this.isActive = isActive;
	}

	/**
	 * constructor
	 * @param label - label to be displayed to user
	 * @param value - value to be saved
	 * @return new Option
	 */
	public Option(String label, String value)
	{
		this.label = label;
		this.value = value;
	}
}