public class PobControllerExt {

	// Summary, filter, etc.
	public String heading {get;set;}
	public String categoryFilter {get;set;}
	private static final String SOQL_WITHOUT_FILTER = 'SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c FROM Lot__c WHERE (Remaining__c>0 OR Id in :existingLotsInThisOrder) ORDER BY Product__c ASC';
	private static final String SOQL_WITH_FILTER = 'SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c FROM Lot__c WHERE (Remaining__c>0 OR Id in :existingLotsInThisOrder) AND Product_Category__c = :categoryFilter ORDER BY Product__c ASC';
	private static final Integer PAGE_SIZE = 5;
	
	// Records
	public Order__c po {get;set;}
	public List<Wrapper> wrappers {get;set;}

	@TestVisible 
	private Map<Id, Wrapper> wrappersMap = new Map<Id, Wrapper>();
	private ApexPages.StandardSetController setCtrl;
	private ApexPages.StandardController stdCtrl;
	private Set<Id> existingLotsInThisOrder = new Set<Id>();
	private boolean isExistingRecord = false;
	
	/** Extension constructor method */
	public PobControllerExt(ApexPages.StandardController stdController) {
		List<Line_Item__c> existingLineItems = null;
		stdCtrl = stdController;
		po = (Order__c) stdCtrl.getRecord();
		isExistingRecord = (po!=null && po.Id != null) ? true : false; 
		if (isExistingRecord) {
			heading = po.Name;
			existingLineItems = [SELECT Units__c, Lot__c, Amount__c FROM Line_Item__c WHERE Order__c = :po.Id];
		} else {
			heading = Label.POB_Heading_New;
		}
		init(existingLineItems);
		resetFilter();
	}

	
	/* Public methods
	========================= */

	/** Used on the Visualforce page to display editable/non editable name */	
	public boolean getNameIsEditable() {
		return (po.Id==null || po.Status__c != 'Closed') ? true : false;
	}
	
	/** Used on the Visualforce page to display editable/non editable budget */
	public boolean getBudgetIsEditable() {
		return (po.Id==null || po.Status__c == 'Draft') ? true : false;
	}
	
	/** Used on the Visualforce page to display editable/non editable status */
	public boolean getStatusIsEditable() {
		return (po.Id==null || po.Status__c != 'Closed') ? true : false;
	}
	
	/** Used on the Visualforce page to display editable/non editable units */	
	public boolean getUnitsAreEditable() {
		return (po.Id==null || po.Status__c != 'Closed') ? true : false;
	}
	
	/** Populates the possibile filter values by retrieving picklist values
		from the object
	 */
	public List<SelectOption> getFilterValues () {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('', Label.POB_NoFilter));
		Schema.DescribeFieldResult fd = Lot__c.Product_Category__c.getDescribe();
		for (Schema.PicklistEntry ple : fd.getPicklistValues()) {
			options.add(new SelectOption(ple.value, ple.label));
		}
		return options;
	}
	
	/** Lots pagination. Moves to the first page */
	public void firstPage() {
		setCtrl.first();
		refreshWrappers();
	}
	
	/** Lots pagination. Moves to the last page */
	public void lastPage() { 
		setCtrl.last();
		refreshWrappers();
	}
	
	/** Lots pagination. Is the [previous] button disabled? */
	public boolean getPrevDisabled() {
		return !setCtrl.getHasPrevious();
	}
	
	/** Lots pagination. Is the [next] button disabled? */
	public boolean getNextDisabled() {
		return !setCtrl.getHasNext();
	}
	
	/** Lots pagination. Returns the number of lot pages */
	public Integer getNumberOfPages() {
		Integer recordCount = setCtrl.getResultSize();
		Integer pageSize = setCtrl.getPageSize();
		return recordCount / pageSize + ( Math.mod(recordCount, pageSize) > 0 ? 1 : 0);
	}
	
	/** Lots pagination. Returns the current page */
	public Integer getCurrentPage() {
		return setCtrl.getPageNumber();
	}
	
	/** Lots pagination. Moves to the next page */
	public void nextPage() {
		if (setCtrl.getHasNext()) {
			setCtrl.next();
			refreshWrappers();
		}
	}
	
	/** Lots pagination. Moves to the previous page */
	public void prevPage() {
		if (setCtrl.getHasPrevious()) {
			setCtrl.previous();
			refreshWrappers();
		}
	}
	
	/** Forces the selection (number of units) to be re-evaluated */
	public void updateSelection() {
		refreshWrappers();
	}
	
	/** SUMMARY. Returns the number of units
	==========================================================================================================================================
	IMPORTANT NOTE: Requirement states "[..] as shown in Figure 1 Account Managers will be able to see summary stats for the purchase Order". 
	My assumption is that the status has to be maintained based in real time with what is being added/removed to the order
	using the purchase order builder, so that the summary reflects what the order will be once saved.
	========================================================================================================================================== */
	public Decimal getUnits() {
		Decimal totalUnits = 0;
		for (Wrapper w : wrappersMap.values()) {
			totalUnits+=w.units;
		}
		return totalUnits;
	}
	
	/** SUMMARY. Returns the price per unit
	==========================================================================================================================================
	IMPORTANT NOTE: Requirement states "[..] as shown in Figure 1 Account Managers will be able to see summary stats for the purchase Order". 
	My assumption is that the status has to be maintained based in real time with what is being added/removed to the order
	using the purchase order builder, so that the summary reflects what the order will be once saved.
	========================================================================================================================================== */
	public Decimal getPricePerUnit() {
		Decimal totalCost = 0;
		Decimal totalUnits = 0;
		for (Wrapper w : wrappersMap.values()) {
			totalCost += w.product.Unit_Price__c * w.units; 
			totalUnits+=w.units;
		}
		return (totalUnits!=0) ? totalCost/totalUnits : null;
	}
	
	/** FILTER. Resets the current filter so it's OFF */
	public void resetFilter() {
		categoryFilter = '';
		updateFilter();
	}
	
	/** FILTER. Updates and applies the filter on lots*/
	public void updateFilter() {
		String soql = (isFilterEnabled()) ? SOQL_WITH_FILTER : SOQL_WITHOUT_FILTER;
		setCtrl = new ApexPages.StandardSetController(Database.getQueryLocator(soql));
		setCtrl.setPageSize(PAGE_SIZE);
		refreshWrappers();
	}
	
	/** Saves and order */
	public PageReference save() {
		Savepoint sp = Database.setSavepoint();
		try {
			// create or update purchase order
			upsert po;
			
			// which line items to be deleted or upserted?
			List<Line_Item__c> toBeDeleted = new List<Line_Item__c>();
			List<Line_Item__c> toBeUpserted = new List<Line_Item__c>();
			for (Wrapper w : wrappersMap.values()) {
				if (w.units > 0) {
					w.lineItem.Order__c = po.Id;
					toBeUpserted.add(w.lineItem);
				} else if (w.units == 0 && w.lineItem.Id!=null) {
					toBeDeleted.add(w.lineItem);
				}
			} 
			
			// delete & upsert line items
			delete toBeDeleted;
			
			// UPSERT, check outcome on this...
			List<Database.UpsertResult> uResults = Database.upsert(toBeUpserted, false);
			for (Integer i=0; i<uResults.size(); i++) {
			    if (!uResults[i].isSuccess()) {
			        for (Database.Error e : uResults[i].getErrors()) {
			        	
			        	// Validation messages are friendly enough so will be displayed
			        	// Other errors are replaced by a friendly error message
			        	// to be placed both on fields and at page level
			        	String friendlyMessage = 
			        		(e.getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) 
			        		? e.getMessage() : Label.POB_Friendly_Error_LineItem;
			        		
						toBeUpserted[i].Units__c.addError(friendlyMessage);			        	
			        	ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, friendlyMessage));
			        }
			        throw new SaveException('Error while saving line items');
			    }
			}
			
			// All good, go to record view page
			return new ApexPages.StandardController(po).view();
			  
		} catch (SaveException e) {
			handleRollback(sp);
			return null;
			
		} catch (DmlException e) {
			handleRollback(sp);
			return null;
			
		} catch (Exception e) {
			// Generic, unexpected exception: rollback and add friendly message
			// then stay on the same page
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, Label.POB_Friendly_Error_Message));
			handleRollback(sp);
			return null;
		}
	}
	
	/** TRANSACTION ROLLBACK
		=======================================================================================================
		Important note. As described in the documentation "The ID on an sObject inserted after setting a
		savepoint is not cleared after a rollback.".
		See: https://www.salesforce.com/us/developer/docs/apexcode/Content/langCon_apex_transaction_control.htm
		
		This simple method rollbacks and clears order IDs to avoid INVALID_CROSS_REFERENCE_KEY in subsequent 
		save attempts.
		======================================================================================================= */
	private void handleRollback(Savepoint sp) {
		
		// Rollback savepoint
		Database.rollback(sp);
		
		// If this is NOT a new order I should get rid
		// of IDs in the po use clone method to get rid of IDs
		if (isExistingRecord == false) {
			po = po.clone(false);
		}
	} 
	
	/* Utility methods (not exposed)
	================================== */
	
	/** Prepopulates wrapperMap with existing line items (if any).
		The wrapperMap property is used to keep the state
		of the selection (number of units) */	
	private void init(List<Line_Item__c> existingLineItems) {
		wrappersMap = new Map<Id, Wrapper>();
		Map<Id, Line_Item__c> lot2Item = new Map<Id, Line_Item__c>();
		Set<Id> lotIds = new Set<Id>();
		if (existingLineItems!=null) {
			for (Line_Item__c l : existingLineItems) {
				lotIds.add(l.Lot__c);
				lot2Item.put(l.Lot__c, l);
				existingLotsInThisOrder.add(l.Lot__c);
			}
		}
		List<Lot__c> lots = [SELECT Id, Name, Product__c, Product_Category__c, Unit_Price__c, Remaining__c FROM Lot__c WHERE Id in :lotIds];
		for (Lot__c lot : lots) {
			Line_Item__c lineItem = lot2Item.get(lot.Id);
			Wrapper w = new Wrapper(lot, lineItem);
			wrappersMap.put(lot.Id, w);
		}
	}
	
	private void refreshWrappers() {
		wrappers = new List<Wrapper>();
		List<Lot__c> lots = setCtrl.getRecords();
		for (Lot__c l : lots) { 
			Wrapper w = getWrapper(l);
			wrappers.add(w);
		}
	}
	
	private boolean isFilterEnabled() {
		return (categoryFilter!=null && categoryFilter!='');
	}
	
	@TestVisible
	private Wrapper getWrapper(Lot__c l) {
		Wrapper w = wrappersMap.get(l.id);
		if (w==null) {
			w = new Wrapper(l, null);
			wrappersMap.put(l.Id, w);
		}
		return w;
	}
	
	/* Inner Wrapper class
	========================= */
	public class Wrapper {
		public Decimal units {
			get{ return lineItem.Units__c; }
			set{ lineItem.Units__c = value; }
		}
		public Lot__c product {set;get;}
		public Line_Item__c lineItem {set;get;}
		
		public Wrapper(Lot__c lot, Line_Item__c lineItem) {
			this.lineItem = (lineItem!=null) ? lineItem : new Line_Item__c(Lot__c = lot.Id, Units__c = 0);
			this.product = lot;
		}
	}
	
	// Just a custom exception
	private class SaveException extends Exception {}
	
}
