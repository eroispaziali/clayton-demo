trigger LineItemTrigger on Line_Item__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	
	// on new records
	if (Trigger.isAfter && Trigger.isInsert) {
    	LineItemTriggerHandler.handle(Trigger.new);
	}
	
	// on updated records
	if (Trigger.isAfter && Trigger.isUpdate) {
    	LineItemTriggerHandler.handle(Trigger.new);
	}
	
	// on deleted records
	if (Trigger.isAfter && Trigger.isDelete) {
    	LineItemTriggerHandler.handle(Trigger.old);
	}
	
	// on restored records
	if (Trigger.isAfter && Trigger.isUnDelete) {
    	LineItemTriggerHandler.handle(Trigger.new);
	}	

}