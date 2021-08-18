public without sharing class CP_ProductUtility {
    public static List<CP_Product__c> getErrorRecProductsName(Set<Id> errorRecIds){
        return [Select Id, Name FROM CP_Product__c WHERE Id IN :errorRecIds];
    }

    public static String getRecordTypeId(Schema.SObjectType objectName,String recordTypeName){
        
        Schema.DescribeSObjectResult describeResult = objectName.getDescribe();
        Map<String,Schema.RecordTypeInfo> rtMapByName = describeResult.getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtByName =  rtMapByName.get(recordTypeName);
        
        if(rtByName == null) 
          return null;
        
        return rtByName.getRecordTypeId();
    }

    public static String getRegionValue(String territoryName,Map<String,WBCP_TerritoryData__c> territoryMapping){
        String region = '';
        if(territoryName != Null && territoryMapping != Null && territoryMapping.get(territoryName) != Null){
            region = territoryMapping.get(territoryName).Destination_Region__c;
        }
        return region;
    }

    public static final String WBCP_LICENSEE_CONTACT = Label.WBCP_Licensee_Contact;
    public static final String WBCP_LICENSEE = Label.WBCP_Licensee;
    public static final String WBCP_RETAILER = Label.WBCP_Retailer;
    public static final String WBCP_LOCAL = Label.WBCP_Local;
    public static final String WBCP_REGIONAL = Label.WBCP_Regional;
    public static final String WBCP_GLOBAL = Label.WBCP_Global;
    public static final String WBCP_TERRITORY_ERROR = Label.WBCP_Territory_Error;
    public static final String WBCP_TERRITORY_ALL_ERROR = Label.WBCP_Territory_ALL_Error;
    public static final String WBCP_ALL_REGION = Label.WBCP_ALL_Region;
    public static final String WBCP_ADMIN_LICENSEE_PROFILE = Label.WBCP_NAM_Licensee_App_Admin;
    public static final String WBCP_PLAT_LICENSEE_PROFILE = Label.WBCP_NAM_Licensee_Platform;
    public static final String WBCP_PLAT_USER_PROFILE = Label.WBCP_Platform;
    public static final String WBCP_SALESFORCE_PLATFORM = Label.WBCP_Salesforce_Platform;
    public static final String WBCP_BATCH = Label.WBCP_Batch;
    public static final String WBCP_TRIGGER = Label.WBCP_Trigger;
    //public static final String WBCP_PARENT_LICENSEE = Label.WBCP_Parent_Licensee;
    public static final String INSERT_OP = 'Insert';
    public static final String UPDATE_OP = 'Update';
}