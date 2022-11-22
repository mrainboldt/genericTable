declare module "@salesforce/apex/LightningTableController.initTable" {
  export default function initTable(param: {recordId: any, relatedField: any, relatedObject: any, fieldSetName: any, whereClause: any, recLimit: any, sortBy: any, sortDirection: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.initTableJSON" {
  export default function initTableJSON(param: {recordId: any, relatedField: any, relatedObject: any, fieldSetName: any, whereClause: any, recLimit: any, sortBy: any, sortDirection: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.initTableForRecord" {
  export default function initTableForRecord(param: {recordId: any, fieldSetName: any, sObjectName: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.refreshRecords" {
  export default function refreshRecords(param: {table: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.loadAllRecords" {
  export default function loadAllRecords(param: {fieldSOQL: any, sObjectType: any, whereClause: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.getFieldSetMembers" {
  export default function getFieldSetMembers(param: {objectApiName: any, fieldSetName: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningTableController.saveRecords" {
  export default function saveRecords(param: {recordsJson: any}): Promise<any>;
}
