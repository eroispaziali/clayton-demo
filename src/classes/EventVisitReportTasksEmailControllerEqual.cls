public class EventVisitReportTasksEmailControllerEqual {

    private final Event_Visit_Report__c myEVR;
    public boolean hasErrors {get;set;}
    public boolean sendEmailAndTask{get;set;}    
    public boolean missingEmail{get;set;}        
                                                 
    public boolean sendTaskOnly{get;set;}       
                                                

    public boolean isDone{get;set;}            

     public EventVisitReportTasksEmailController() {

        hasErrors = false;
        sendEmailAndTask = false;
        sendTaskOnly=false;
        missingEmail = false;
        isDone = false; 

        String strEVRId = ApexPages.currentPage().getParameters().get('evrId');
        if (String.isEmpty(strEVRId))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.EventVisitReportTasksEmail_Error_No_Record_Id));
            hasErrors = true;
        }
        else
        {
            myEVR = EventVisitReportSelector.getEventVisitReportsById(new Set<Id>{strEVRId}).get(0);
            system.debug('myEVR:'+myEVR);
            if (myEVR.Email_Yes__c > 0)
            {
                if (myEVR.Email__c != null)
                {
                    sendEmailAndTask=true;
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.EventVisitReportTasksEmail_Missing_Email_Confirm_Task));
                    missingEmail = true;
                    sendTaskOnly = true;
                }
                
            }
            else
            {
                sendTaskOnly = true;
            }


            if ((myEVR.Mail_Yes__c >0) && myEVR.Print_Send_User__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Event_Visit_Report_Task_No_Printing_Distribution_User_Error_Message));
            }
        }
        system.debug('hasErrors:'+hasErrors);
        system.debug('sendEmailAndTask:'+sendEmailAndTask);
        system.debug('sendTaskOnly:'+sendTaskOnly);
        system.debug('missingEmail:'+missingEmail);
        system.debug('isDone:'+isDone);
    }

    public PageReference EmailEVRToCustomerAndGenerateTasks()
    {
        try
        {
            myEVR.Status__c = Label.EventVisitReportTasksEmail_Status_To_Trigger_Email;
            update myEVR;
            generateTasks();
        }
        catch (Exception e)
        {
            ApexPages.addMessages(e);
            hasErrors=true;
        }
        isdone = true;    
        
        return null;
    }

    public PageReference generateTasks()
    {
        try
        {
            EventVisitReportServices.createFollowUpTasks(myEVR.Id);
        }
        catch (Exception e)
        {
            ApexPages.addMessages(e);
            hasErrors=true;
        }
        isDone = true;

        return null;
    }
    /*********************************************************************************************************************************/

 
    public PageReference redirectToEVR()
    {
        return  new Pagereference('/'+ myEVR.Id);
    }
    /*********************************************************************************************************************************/


}
