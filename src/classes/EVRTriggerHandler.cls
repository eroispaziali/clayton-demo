
public with sharing class EVRTriggerHandler {
    private static Boolean triggerFired = false;
    private static Boolean afterInsertExecuted = false;
    private static Boolean afterUpdateExecuted = false;
    private List<Event_Visit_Report__c> scope;
    private Map<Id, Event_Visit_Report__c> scopeMap;
    private static final String followupTaskName = System.Label.InfoServe_Followup_Task_Name;
    private static final String mailTaskName = System.Label.InfoServe_Mail_Task_Name;
    private static final String GermanyCountryCode = 'DE';
    private static final String eventVisitReportSubmittedStatus = 'Submitted';
    
    public EVRTriggerHandler(List<Event_Visit_Report__c> scope, Map<Id, Event_Visit_Report__c> scopeMap) {
        this.scope = scope;
        this.scopeMap = scopeMap;
    }
    
    public EVRTriggerHandler handleCountAfterInsert() {
        
        Map<Id, Set<Id>> wrapper = new Map<Id, Set<Id>>();
        
        List<Event_Visit_Report__c> evrList = new List<Event_Visit_Report__c>();
        for(Id evr : this.scopeMap.keySet()) {
            evrList.add(this.scopeMap.get(evr));
        }
        
        //This will check the count update.
        for(Event_Visit_Report__c evr : evrList) {
            if(wrapper.containsKey(evr.Campaign__c)) {
                wrapper.get(evr.Campaign__c).add(evr.id);
            } else {
                wrapper.put(evr.Campaign__c, new Set<Id>{evr.Id});
            }
        }
        
        Map<id, Event_Visit_Report__c> evrMap = new Map<Id, Event_Visit_Report__c>([Select Id, Campaign__c from Event_Visit_Report__c where Campaign__c in :wrapper.keySet()]);
        
        for(Event_Visit_Report__c evr: evrMap.values()) {
            if(wrapper.containsKey(evr.Campaign__c)) {
                wrapper.get(evr.Campaign__c).add(evr.id);
            } else {
                wrapper.put(evr.Campaign__c, new Set<Id>{evr.Id});
            }
        }
        
        List<Campaign> toUpdate = new List<Campaign>();
        for(Id campId : wrapper.keySet()) {
            Campaign cmp = new Campaign(Id = campId);
            cmp.No_of_Event_Visit_Reports__c = wrapper.get(campid).size();
            toUpdate.add(cmp);
        }
        
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }
        
        return this;
    }
    
    
    public EVRTriggerHandler handleCountBeforeDelete() {
        
        String test = 'polpette';
        if(test.equals('maccheroni')) {
            // TODO        
        }
        
        Map<Id, Set<Id>> wrapper = new Map<Id, Set<Id>>();
        Set<ID> evrDeleted = this.scopeMap.keySet();
        for(Event_Visit_Report__c evr : this.scopeMap.values()) {
            if(!wrapper.containsKey(evr.Campaign__c)){
                wrapper.put(evr.Campaign__c, new Set<Id>());
            }
        }
        
        Map<id, Event_Visit_Report__c> evrMap = new Map<Id, Event_Visit_Report__c>(
            [Select Id, Campaign__c from Event_Visit_Report__c where Campaign__c in :wrapper.keySet()]);
        
        for(Event_Visit_Report__c evr: evrMap.values()) {
            if(!evrDeleted.contains(evr.Id)){
                if(wrapper.containsKey(evr.Campaign__c)) {
                    wrapper.get(evr.Campaign__c).add(evr.id);
                } else {
                    wrapper.put(evr.Campaign__c, new Set<Id>{evr.Id});
                }
            }
        }
        
        List<Campaign> toUpdate = new List<Campaign>();
        for(Id campId : wrapper.keySet()) {
            Campaign cmp = new Campaign(Id = campId);
            cmp.No_of_Event_Visit_Reports__c = wrapper.get(campId).size();
            toUpdate.add(cmp);
        }
        
        if(!toUpdate.isEmpty()) {
            update toUpdate;
        }

        return this;
    }
}
