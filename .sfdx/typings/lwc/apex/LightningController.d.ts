declare module "@salesforce/apex/LightningController.querySObject" {
  export default function querySObject(param: {query: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.querySObjects" {
  export default function querySObjects(param: {query: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getColumns" {
  export default function getColumns(param: {sObjectName: any, fieldSetString: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getColumnsAndDefaultValues" {
  export default function getColumnsAndDefaultValues(param: {sObjectName: any, fieldSetString: any, defaultValueSet: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getFieldSOQL" {
  export default function getFieldSOQL(param: {fields: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getFieldSOQLWithReference" {
  export default function getFieldSOQLWithReference(param: {fields: any, sObjectName: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getIcon" {
  export default function getIcon(param: {iconApiName: any}): Promise<any>;
}
declare module "@salesforce/apex/LightningController.getIcons" {
  export default function getIcons(param: {iconApiNames: any}): Promise<any>;
}
