/**************************************************************************************
Apex Class Name     : PRHeader_TriggerHandler 
Test Class          : BS_PRHeader_Trigger_Test 
Auther              : Harikrishna P 
Function            : Handles events from the PRHeader_Trigger trigger 
Updates :
*************************************************************************************/

public class PRHeader_TriggerHandler{
    public static void handleBeforeInsert(list<PR_Header__c> Trigger_new) {
        System.debug('PRHeader_TriggerHandler...handleBeforeInsert...');
        for(PR_Header__c prh:Trigger_new){
            prh.CurrencyIsoCode=prh.PR_Currency__c;
        }
    }
    public static void handleBeforeUpdate(Map<Id, PR_Header__c> Trigger_newMap, Map<Id, PR_Header__c> Trigger_oldMap) {
        System.debug('PRHeader_TriggerHandler...handleBeforeUpdate...');
        for(PR_Header__c prh:Trigger_newMap.values()){
            if(prh.CurrencyIsoCode!=prh.PR_Currency__c) prh.CurrencyIsoCode=prh.PR_Currency__c;
        }
    }
    
    public static void handleAfterUpdate(Map<Id, PR_Header__c> Trigger_newMap, Map<Id, PR_Header__c> Trigger_oldMap) {
        System.debug('PRHeader_TriggerHandler...handleAfterUpdate...');
        set<id> prHeaderIDSet=new set<id>();
        set<id> vendorIDSet=new set<id>();
        set<id> campaign_PR_HeaderIDSet=new set<id>();
        set<id> CanceledPR_HeaderIdSet=new set<id>();
        set<id> prHeaderIDSet_CurrencyChange=new set<id>();
        Map<Id, PR_Header__c> approvalValidation_Map=new Map<Id, PR_Header__c>();
        for(PR_Header__c prh:Trigger_newMap.values()){
            if(prh.Status__c=='Submitted' && Trigger_oldMap.get(prh.id).status__c=='New' && prh.OwnerId==Userinfo.getUserId()){
                System.debug('submitted for approval....'+prh);                
                campaign_PR_HeaderIDSet.add(Prh.id);
            }            
            if(prh.PR_Currency__c!= Trigger_oldMap.get(prh.id).PR_Currency__c){                                
                prHeaderIDSet_CurrencyChange.add(Prh.id);
            }
            if(prh.Status__c=='Approved By Finance'){
            	approvalValidation_Map.put(prh.id,prh);                
            }
            if(prh.Status__c=='Completed' && Trigger_oldMap.get(prh.id).status__c!='Completed'){                                
                vendorIDSet.add(prh.Vendor_Name__c);
            }
            if((prh.Status__c=='Canceled' && Trigger_oldMap.get(prh.id).status__c!='Canceled') ||
               (prh.Status__c=='New' && Trigger_oldMap.get(prh.id).status__c!='New')){                
                   CanceledPR_HeaderIdSet.add(Prh.id);
               }
        }
        if(vendorIDSet.size()>0) rollup_PRAmount_ToVendor(vendorIDSet);
        if(prHeaderIDSet_CurrencyChange.size()>0) updatePRDetails(prHeaderIDSet_CurrencyChange);
        if(campaign_PR_HeaderIDSet.size()>0) create_Campaign_PRRecords(campaign_PR_HeaderIDSet);
        if(CanceledPR_HeaderIdSet.size()>0) deleteCampaignSpendRecords(CanceledPR_HeaderIdSet);
        if(!approvalValidation_Map.isEmpty()) validateBeforeApproval(approvalValidation_Map);
    }    
    public static void validateBeforeApproval(Map<Id, PR_Header__c> Trigger_newMap) {
        Map<Id, PR_Detail__c> PRDetail_Map=new Map<Id, PR_Detail__c>();
        Map<Id, PR_Detail__c> PRDetail_CCode_Map=new Map<Id, PR_Detail__c>();
        for(PR_Detail__c prd:[select id,PR_Header__c,OverAll_Status__c,SAP_Company_Code_Matching__c from PR_Detail__c Where 
                              PR_Header__c IN:Trigger_newMap.keyset() AND (OverAll_Status__c=false OR SAP_Company_Code_Matching__c=false)]){
            if(prd.OverAll_Status__c==false) PRDetail_Map.put(prd.PR_Header__c, prd);
            if(prd.SAP_Company_Code_Matching__c==false) PRDetail_CCode_Map.put(prd.PR_Header__c, prd);
        }
        for(PR_Header__c prh:Trigger_newMap.values()){            
            if(prh.Status__c=='Approved By Finance' && (prh.PR_Details_Approved_By_Finance__c >0 || PRDetail_Map.containsKey(prh.id))){            	
                prh.Status__c.adderror('You can not approve the PR if rejected Details exist. Click on reject to submit back to requester.');
            }
            if(prh.Status__c=='Approved By Finance' && PRDetail_CCode_Map.containsKey(prh.id)){            	
                prh.Status__c.adderror('You can not approve this PR. IOs with unmatched Company Codes exist. ');
            }
        }
    }
    
    @future
    public static void updatePRDetails(set<id> prHeaderIDSet_CurrencyChange){
        list<PR_Detail__c> PR_Detail_list=new list<PR_Detail__c>();
        list<PR_Phasing__c> Phasing_list=new list<PR_Phasing__c>();
        for(PR_Detail__c prd: [select id,PR_Header__r.PR_Currency__c from PR_Detail__c where PR_Header__c IN:prHeaderIDSet_CurrencyChange]){            
            prd.CurrencyIsoCode=prd.PR_Header__r.PR_Currency__c;
            PR_Detail_list.add(prd);
        }
        for(PR_Phasing__c ph: [select id,PR_Header__r.PR_Currency__c from PR_Phasing__c where PR_Header__c IN:prHeaderIDSet_CurrencyChange]){            
            ph.CurrencyIsoCode=ph.PR_Header__r.PR_Currency__c;
            Phasing_list.add(ph);
        }
        if(PR_Detail_list.size()>0) database.update(PR_Detail_list,false);
        if(Phasing_list.size()>0) database.update(Phasing_list,false);        
    }
    
    @future
    public static void rollup_PRAmount_ToVendor(set<id> vendorIDSet){
        string PRYear=string.valueOf(system.today().year());
        list<Account> vendorAccoutListToUpdate=new list<Account>();
        for(AggregateResult agr: [SELECT Vendor_Name__c,Sum(Total_PR_Amount__c) pramt FROM PR_Header__c
                                  WHERE Vendor_Name__c IN:vendorIDSet AND PR_Year__c=:PRYear  AND Total_PR_Amount__c > 0 AND Status__c='Completed'
                                  GROUP BY Vendor_Name__c]){
                                      account acc=new account(Id=(id)agr.get('Vendor_Name__c'),
                                                              Total_PR_amount_Current_year__c=(decimal)agr.get('pramt'));
                                      vendorAccoutListToUpdate.add(acc);
                                  }
        if(vendorAccoutListToUpdate.size()>0){
            database.update(vendorAccoutListToUpdate,false);
        }
    }
    
    @future
    public static void create_Campaign_PRRecords(set<id> prHeaderIDSet){
        map<string,Campaign_PR__c> Campaign_PRMap=new map<string,Campaign_PR__c>();
        for(PR_Detail__c prd: [select id,Campaign_ID__c,PR_Header__c,IOCode__c,GL_Code2__c from PR_Detail__c where PR_Header__c IN:prHeaderIDSet]){            
            Campaign_PR__c cpr=new Campaign_PR__c(
                Campaign__c=prd.Campaign_ID__c
                ,PR_Header__c=prd.PR_Header__c                
                ,Unique_Key__c=prd.Campaign_ID__c+prd.PR_Header__c+prd.IOCode__c+prd.GL_Code2__c
            );
            Campaign_PRMap.put(cpr.Unique_Key__c,cpr);
        }
        if(!Campaign_PRMap.isEmpty()){
            Schema.SObjectField f = Campaign_PR__c.Fields.Unique_Key__c;            
            Database.upsertResult [] upsertResultList = database.upsert(Campaign_PRMap.values(),f,false);
            for (Database.upsertResult sr : upsertResultList) {
                if (sr.isSuccess()) {
                    // Operation was successful
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('error has occurred.' + err.getStatusCode() + ': ' + err.getMessage());                    
                        System.debug('fields that affected this error: ' + err.getFields());                        
                    }
                }
            }
        } 
    }
    @future
    public static void deleteCampaignSpendRecords(set<id> HeaderIdSet){
        try{            
            Delete [SELECT id FROM Campaign_Spend__c WHERE RecordType.Name='Pending' AND PR_Header__c IN: HeaderIdSet];    
        }catch(system.DmlException ex){
            system.debug('deleteCampaignSpendRecords:::exception in deletion...'+ex);
        } 
    }
    
}