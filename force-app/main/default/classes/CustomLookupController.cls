public with sharing class CustomLookupController {
    @AuraEnabled
    public static List <sObject> fetchLookUpValues(String searchKeyWord, String objectName) {
        String searchKey = String.escapeSingleQuotes(searchKeyWord.trim()) + '%';
        
        List <sObject> returnList = new List < sObject > ();
        
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 15
        
        String sQuery =  'select id, Name from ' + objectName + ' where RecordType.DeveloperName =  \'Distributor\' And Name LIKE: searchKey order by createdDate DESC limit 15';
        system.debug(sQuery);
        List <sObject> lstOfRecords = Database.query(sQuery);
        
        for (sObject obj : lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static String getEnvironmentUrl() {
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    
    // returns all "Distributor" accounts based on the search keyword
    @AuraEnabled
    public static List <sObject> getDistributorRecordType(String searchKeyWord, String objectName, Integer queryLimit) {
        String searchKey = searchKeyWord.trim() + '%';
        if (queryLimit == null || queryLimit == 0) {
            queryLimit = 20;
        }
        
        List <sObject> returnList = new List < sObject > ();
        List <sObject> lstOfRecords = [select id, Name, Attention__c, State__c, TDL_Match_Code__c, PremiseType__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, Phone from Account where RecordType.DeveloperName = 'Distributor' AND (TDL_Match_Code__c = :searchKeyWord OR Name LIKE :searchKey) order by createdDate DESC limit :queryLimit];
        
        for (sObject obj : lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    // returns all "Retail" accounts based on the search keyword
    @AuraEnabled
    public static List <sObject> getPremiseRecordType(String searchKeyWord, String objectName, Integer queryLimit) {
        String searchKey = searchKeyWord.trim() + '%';
        if (queryLimit == null || queryLimit == 0) {
            queryLimit = 20;
        }
        List <sObject> returnList = new List < sObject > ();
        
        List <sObject> lstOfRecords = [select id, Name, PremiseType__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, RecordType.DeveloperName from Account where (RecordType.DeveloperName = 'OffPremise' OR RecordType.DeveloperName = 'OnPremise') AND (TDL_Match_Code__c = :searchKeyWord OR Name LIKE :searchKey) order by createdDate DESC limit :queryLimit];
        
        for (sObject obj : lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    // returns all contacts related to a specific account id
    @AuraEnabled
    public static List <sObject> getDistributorContactForAccount(String searchKeyWord, String objectName, String parentId) {
        String searchKey = searchKeyWord.trim() + '%';
        Set<Id> contactIds = new Set<Id>();
        
        for (AccountContactRelation con : [select id, Contact.Name, Contact.LastName, Contact.Email, ContactId from AccountContactRelation where (AccountId = :Id.valueOf(parentId) AND Contact.Name LIKE :searchKey)]) {
            contactIds.add(con.ContactId);
        }
        return [select Id, Name, LastName from Contact where Id IN :contactIds order by LastName ASC];
    }
    
    // returns all accounts related to a specfic contact Id
    @AuraEnabled
    public static List <sObject> getMyAccounts(String searchKeyWord, String objectName, String parentId) {
        String searchKey = searchKeyWord.trim() + '%';
        Set<Id> accountIds = new Set<Id>();
        
        for (AccountContactRelation acct : [select id, AccountId, Account.Name, ContactId from AccountContactRelation where (ContactId = :Id.valueOf(parentId) AND Account.Name LIKE :searchKey)]) {
            accountIds.add(acct.AccountId);
        }
        return [select Id, Name from Account where Id IN :accountIds order by Name ASC limit 50];
    }
    
    // returns all SAP Company records related to a specific account vendor id
    @AuraEnabled
    public static List <sObject> getSAPCompanyForVendorAccount(String parentId) {
        Set<Id> sapCompanyCodeRecordIds = new Set<Id>();
        for (Account acc : [Select id, Name, (Select Id, Name From SAP_Company_Codes__r) from Account where Id = :Id.valueOf(parentId)]) {
            for(SAP_Company_Code__c sapCode: acc.SAP_Company_Codes__r){
                sapCompanyCodeRecordIds.add(sapCode.Id);
            }
            
        }
        return [select Id, Name, Status__c,SAP_Company_Code_Name_Mask__c from SAP_Company_Code__c where Id IN :sapCompanyCodeRecordIds];
    }
    
    // returns account and SAP Company Code details for the respective PR Header
    @AuraEnabled
    public static Map<String, Object> getAccountAndSAPCompanyCodeDetails(String PRHederId) {
        system.debug('PRHederId: '+ PRHederId);
        Map<String, Object> responseMap = new Map<String, Object>();
        PR_Header__c prHeader = [select id, Vendor_Name__c, SAP_Company_Code__c from PR_Header__c where id =: PRHederId];
        if(prHeader.Vendor_Name__c != null){
        	Account objAccount = [Select Id, Name from Account Where Id =: prHeader.Vendor_Name__c];
            responseMap.put('Account',objAccount);
        }           
        if(prHeader.SAP_Company_Code__c != null){
        	SAP_Company_Code__c objSAPCode = [Select Id, Name, Status__c from SAP_Company_Code__c Where Id =: prHeader.SAP_Company_Code__c];
            responseMap.put('SapCompanyCode',objSAPCode);
        }       
        System.debug('Return Map Size:::'+responseMap.size());        
        return responseMap;
    }
        
    // update Method of PRHeader Record
    @AuraEnabled
    public static String updatePRHeader(String jsonPRHeaders) {
        String return_message = 'PR Record Saved Successfully';
        System.debug(jsonPRHeaders);
        try {
            List<PR_Header__c> prHeaderList = (List<PR_Header__c>)System.JSON.deserialize(jsonPRHeaders, List<PR_Header__c>.Class);
            PR_Header__c prHeaderFromComponent = prHeaderList[0];
            update prHeaderFromComponent;
            if(Test.isRunningTest())
			{
				throw new System.DmlException('test exception');
            }            
        }        
        catch(Exception e){  
            return_message = 'Failed to Save PR Record';
            System.debug('---Exception Thrown while updating the PR Header---'+e.getMessage());
        }
        return return_message;
    }
    
    //fetch picklist values for PR Header Record
    @AuraEnabled
    public static List<String> getPRPicklistvalues(String objectName, String field_apiname,Boolean nullRequired){
        List<String> optionlist = new List<String>();       
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap();         
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_apiname).getDescribe().getPickListValues();        
        if(nullRequired == true){
            optionlist.add('--None--');
        }        
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(pv.getValue());
        }
        return optionlist;
    }
}