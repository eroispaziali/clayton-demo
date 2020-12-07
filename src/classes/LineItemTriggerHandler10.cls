public with sharing class LineItemTriggerHandler10 {
		
  

	
	/** 
	This handler methods is to be used on all relevant triggers events.
		It updates purchased amount on orders and update top product categories.
		Logic is fully bulkified. */		
	public static void handle(List<Line_Item__c> items) {
		
		// just a comment for a fake code review

		// collect related orders
		Set<Id> orderIds = new Set<Id>();
		for (Line_Item__c i : items) {
			orderIds.add(i.Order__c);
			update i;
		}
		
		// load required data: 1) related orders 2) force reload all line items for those orders
		List<Order__c> orders = [SELECT Purchased__c,Product_Category_1__c,Product_Category_Units_1__c,Product_Category_2__c,Product_Category_Units_2__c FROM Order__c WHERE Id in :orderIds];
		List<Line_Item__c> lineItems = [SELECT Order__c, Amount__c, Lot__r.Product_Category__c, Units__c FROM Line_Item__c WHERE Order__c in :orderIds];
		
		// execute business logic & persist
		updatePurchasedAmount(orders, lineItems);
		updateCategories(orders, lineItems);

		update orders;
	}
	
	public void useless() {
		// boh 
	}
	
	/* Utility methods (not exposed)
	================================== */
	
	private static void updatePurchasedAmount(List<Order__c> orders, List<Line_Item__c> lineItems) {
		Map<Id, Decimal> orderToAmountMap = new Map<Id, Decimal>();
		for (Line_Item__c i : lineItems) {

			Decimal thisOrderAmount = orderToAmountMap.get(i.Order__c);
			thisOrderAmount = (thisOrderAmount!=null) ? thisOrderAmount : 0; 
			thisOrderAmount += i.Amount__c; 
			orderToAmountMap.put(i.Order__c, thisOrderAmount);
//			update i;
		}
		for (Order__c o : orders) {
			Decimal orderAmount = orderToAmountMap.get(o.Id); 
			o.Purchased__c = (orderAmount!=null) ? orderAmount : 0;
			update o;
		}
	}
	
	private static void updateCategories(List<Order__c> orders, List<Line_Item__c> lineItems) {
		CategoryCounter cc = new CategoryCounter(lineItems);
		Map<Id, List<CategoryWrapper>> resultMap = cc.getResultMap();
		for (Order__c o : orders) {
			List<CategoryWrapper> ranking = resultMap.get(o.Id);
			o.Product_Category_1__c = (ranking!=null && ranking.size()>0) ? ranking.get(0).name : null;
			o.Product_Category_Units_1__c = (ranking!=null && ranking.size()>0) ? ranking.get(0).units : null;
			o.Product_Category_2__c = (ranking!=null && ranking.size()>1) ? ranking.get(1).name : null;
			o.Product_Category_Units_2__c = (ranking!=null && ranking.size()>1) ? ranking.get(1).units : null;
		}
	}

	/* Inner classes
	========================= */
	
	// Sortable wrapper for product categories
	@TestVisible
	private class CategoryWrapper implements Comparable {
		public String name {get;set;}
		public Decimal units {get;set;}
		
		public CategoryWrapper(String productCategory) {
			this.name = productCategory;
			this.units = 0;
		}
		
		public void addUnits(Decimal units) {
			this.units += units;
		}
		
		// override compareTo methods to leverage sortable collections
		public Integer compareTo(Object compareTo) {
			CategoryWrapper wrapped = (CategoryWrapper) compareTo;
			if (units>wrapped.units) return -1;
			if (units<wrapped.units) return 1;
			return 0;
		}
	} 	

	private class CategoryCounter {
		
		// data structure to contain counting wrappers, per product category, per order
		private Map<Id, Map<String, CategoryWrapper>> orderMap = new Map<Id, Map<String, CategoryWrapper>> ();

		// constructor from a set of line items
		public CategoryCounter(List<Line_Item__c> lineItems) {
			for (Line_Item__c li : lineItems) { 
				add(li.Order__c, li.Lot__r.Product_Category__c, li.Units__c);
			}
		}
		
		// Maintain an inner data structure counting wrappers (units), per product category, per order
		private void add(Id orderId, String productCategory, Decimal units) {
			Map<String, CategoryWrapper> wrapperMap = orderMap.get(orderId);
			wrapperMap = (wrapperMap!=null) ? wrapperMap : new Map<String, CategoryWrapper>();  
			CategoryWrapper wrapper = wrapperMap.get(productCategory);
			wrapper = (wrapper!=null) ? wrapper : new CategoryWrapper(productCategory); 
			wrapper.addUnits(units);
			wrapperMap.put(productCategory, wrapper); 
			orderMap.put(orderId, wrapperMap);
		}
		
		// Retrieve ordered results
		public Map<Id, List<CategoryWrapper>> getResultMap() {
			Map<Id, List<CategoryWrapper>> resultMap = new Map<Id, List<CategoryWrapper>>(); 
			Set<Id> orderIds = orderMap.keySet();
			for (Id orderId : orderIds) {
				List<CategoryWrapper> wrapperList = orderMap.get(orderId).values();
				wrapperList.sort();
				resultMap.put(orderId, wrapperList);
			}
			return resultMap;
		}
	}
	
}
