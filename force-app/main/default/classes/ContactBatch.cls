global class ContactBatch implements Database.Batchable<SObject>, Database.Stateful{
    
    global Integer total_size = 0;
    global Integer fail_size = 0;
    global Integer success_size = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String Query = 'SELECT Id, Name, Fax, Email, MobilePhone, Description, ' +
            'Account.Name, Account.Rating, Account.Phone, Account.Fax, Account.Industry FROM Contact';
        
        AsyncApexJob[] apexJobs = [SELECT Id, ApexClassId, ApexClass.Name,
                                   NumberOfErrors, JobItemsProcessed,
                                   TotalJobItems, Status, JobType
                                   FROM AsyncApexJob
                                   WHERE Id =: bc.getJobId()
                                  ];
        System.debug('@@@ Batch Status Start Method @@@ ' + apexJobs);
        
    
        return Database.getQueryLocator(Query);
    }

    global void execute(Database.BatchableContext bc, List<Contact> contactList){
        
        AsyncApexJob[] apexJobs = [SELECT Id, ApexClassId, ApexClass.Name,
                                  		NumberOfErrors, JobItemsProcessed,
                                  		TotalJobItems, Status, JobType
                                  	FROM AsyncApexJob
                                  	WHERE Id =: bc.getJobId()
                                  ];
        System.debug('@@@ Batch Status Execute Parent @@@ ' + apexJobs);
        
                
        AsyncApexJob[] apexJobs_child = [SELECT Id, ApexClassId, ApexClass.Name,
                                  		NumberOfErrors, JobItemsProcessed,
                                  		TotalJobItems, Status, JobType
                                  	FROM AsyncApexJob
                                  	WHERE Id =: bc.getChildJobId()
                                  ];
        System.debug('@@@ Batch Status Execute Child @@@ ' + apexJobs_child);
        
        
        Integer size = contactList.size();
        total_size = total_size + size;

        for(Integer i = 0; i < size; i++){
            Contact contact = contactList.get(i);
            if(contact.Fax == null || contact.Fax == ''){
                contact.Fax = contact.Account.Fax;
                //contact.Fax = '';
            }
            if(contact.MobilePhone == null || contact.MobilePhone == ''){
                contact.MobilePhone = contact.Account.Phone;
                //contact.MobilePhone = '';
            }

            contact.email = 'ddphillyfan@gmail.com';
            contact.Description = contact.Account.Name + ' ' 
            + contact.Account.Rating + ' ' 
            + contact.Account.Industry + ' '
            + contact.Email;
        }

        //update contactList;
        Database.SaveResult[] result = Database.update(contactList, false);
        Integer size_result = result.size();
        for(Integer i = 0; i < size; i++){
            Database.SaveResult sr = result.get(i);
            if(sr.isSuccess()){
                success_size += 1;
            }else{
                fail_size += 1;
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        
        AsyncApexJob[] apexJobs = [SELECT Id, ApexClassId, ApexClass.Name,
                                     NumberOfErrors, JobItemsProcessed,
                                     TotalJobItems, Status, JobType
                                     FROM AsyncApexJob
                                     WHERE Id =: bc.getJobId()
                                    ];
        System.debug('@@@ Batch Status Finish Method @@@ ' + apexJobs);
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('Status of Batch Class: Contact Batch');
        email.setSenderDisplayName('Diego Delgado');
        email.setHtmlBody('Dear User, <br/>  Batch processed' + 
                         '<br/> Total Records: ' + total_size + 
                         '<br/> Success Count: ' + success_size +
                         '<br/> Fail Count: ' + fail_size);
        List<String> emailTo = new List<String>();
        emailTo.add('ddphillyfan@gmail.com');
        email.setToAddresses(emailTo);
        
        Messaging.SingleEmailMessage[] emailList = new List<Messaging.SingleEmailMessage>();
        emailList.add(email);
        
        Messaging.sendEmail(emailList, false);

    }
}