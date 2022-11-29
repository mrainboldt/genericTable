import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent, registerListener, unregisterAllListeners } from 'c/pubsub';

//Custom Labels
import labelNoData from '@salesforce/label/c.No_Data_Available';

const DEFAULT_RECORDS_PER_PAGE = 10;
const ICON_ARROW_DOWN = 'utility:arrowdown';
const ICON_ARROW_UP = 'utility:arrowup';
const DATA_TYPE_DOUBLE = 'DOUBLE';
const DATA_TYPE_DATE = 'DATE';
const DATA_TYPE_REF = 'REFERENCE';
const SORT_ASC = 'asc';
const SORT_DESC = 'desc';
const REFRESH_EVENT = 'reloadTable';

export default class FieldSetDataTable extends LightningElement {

    //local
    labels = {
        noDataAvailable: labelNoData
    };

    @api 
    get recordData(){
        return this.recordDataVal;
    }
    set recordData(value){
        //console.log('setting recordData');
        this.recordDataVal = value;
        this.initTableData();        
    }

    @api objectName;
    @api fields;
    @api fieldsForCreate;
    @api defaultFieldValues;
    @api canEdit = false;
    @api canCreate = false;
    @api tableHeader;
    @api newRecordButtonLabel = 'New';
    @api recordsPerPage = DEFAULT_RECORDS_PER_PAGE;
    @api disablePagination = false;
    @api enableDragDrop = false;
    @api rowNumber = 0;
    @api rankField;
    @api defaultSortField;
    @api defaultSortDir;
    @api defaultSortDataType;
    @api dropEventName;
    @api threshold = 999999999;
    @api thresholdField = '';
    @api numberAccuracy = 2;
    @api disableSort = false;
    
    @track records = [];
    @track recordsToShow = [];
    @track hasData = false;
    @track selectedRecordId;
    @track currentPage = 1;
    @track totalPages = 1;
    @track fieldObjects;
    
    recordsByPage = {};
    recordDataVal;
    readyToInit = false;
    filterCol;
    filterDir;
    scriptsLoaded = false;
    selectedRecordId;
    dragIndex = -1;
    runningThresholdSum = 0;

    get displayFooter()
    {
        return !this.disablePagination;
    }

    get tableRowClasses()
    {
        return !this.enableDragDrop ? '' : 'draggable';
    }

    get isDataReady()
    {
        return this.recordData && this.recordData.length > 0;
    }

    /**
     * This used by pubsub to know what page we are on.
     */
    @wire(CurrentPageReference) pageRef;
    
    connectedCallback()
    {
            console.log('FieldSetDataTable canCreate', JSON.stringify(this.canCreate));
            if(!this.isDataReady)
            {
                console.log('no record data...');
                return;
            }
            else
            {
                this.readyToInit = true;
                this.initTableData();
            }
        
    }
    
    renderedCallback()
    {
        console.log('FieldSetDataTable canCreate', JSON.stringify(this.canCreate));
            if(!this.isDataReady)
            {
                console.log('no record data...');
                return;
            }
            else
            {
                this.readyToInit = true;
            }
    }

    initTableData(){
        if(!this.readyToInit || !this.isDataReady)
        {
            console.log('skipping initTableData, data not ready...');
            return;
        }
        this.records = JSON.parse(JSON.stringify(this.recordData));
        for(let rec of this.records)
        {
            this.generateTableData(rec);
        }
        this.setupPagination();
        if(this.defaultSortField)
        {
            this.sortColumn(this.defaultSortField, this.defaultSortDataType, null);
        }
        this.hasData = true;
        this.threshold = this.threshold ? Number(this.threshold) : this.threshold;
    }

    generateTableData(rec){
        rec.tableData = [];
        rec.index = rec[this.rankField];
        rec.initialIndex = rec[this.rankField];
        rec.isChanged = false;
        this.fieldObjects = JSON.parse(JSON.stringify(this.fields)); 
        rec.classList = this.tableRowClasses;
        for(let fld of this.fieldObjects){
            fld.fieldPath  = fld.fieldPath ? fld.fieldPath : fld.fieldName;
            fld.isSort = this.defaultSortField === fld.fieldPath;
            fld.isThreshold = this.thresholdField === fld.fieldPath;
            fld.sortIcon = fld.isSort && this.defaultSortDir === SORT_ASC ? ICON_ARROW_UP : ICON_ARROW_DOWN;
            if(fld.isSort)
            {
                this.defaultSortDataType = fld.typeApex;
            }
            //console.log('fld.typeApex:', JSON.stringify(fld.fieldPath), JSON.stringify(fld.typeApex));
            let isName = fld.fieldPath == 'Name';
            let isReference = fld.typeApex == DATA_TYPE_REF;
            let isNumber = fld.typeApex == DATA_TYPE_DOUBLE;
            let fieldVal = rec[fld.fieldPath];
            let fieldValReference;
            if(isReference){
                let parentRecordName = fld.fieldPath;
                if(parentRecordName.endsWith('__c')){
                    parentRecordName = parentRecordName.slice(0, -3)+'__r';
                }
                else if(parentRecordName.endsWith('Id')){
                    parentRecordName = parentRecordName.slice(0, -2);
                }
                if(rec[parentRecordName] && rec[parentRecordName].Name){
                    fieldValReference = rec[parentRecordName].Name;
                }
            }
            if(isNumber && fieldVal){
                fieldVal = Number(fieldVal).toFixed(this.numberAccuracy);
            }
            if(fld.isThreshold && fieldVal && isNumber)
            {
                rec.runningSum = Number((this.runningThresholdSum + Number(fieldVal)).toFixed(this.numberAccuracy));
                if(rec.runningSum > this.threshold 
                    && this.runningThresholdSum <= this.threshold)
                {
                    rec.classList += ' threshold';
                }
                this.runningThresholdSum = rec.runningSum;
            }
            let tableCell = {
                value: fieldValReference ? fieldValReference : fieldVal,
                fieldPath: fld.fieldPath,
                type: fld.typeApex,
                isUrl: (isReference || isName) && fld.fieldPath != 'RecordTypeId' ? true : false,
                isDate: fld.typeApex == DATA_TYPE_DATE ? true : false,
                url: isName ? ('/'+rec.Id) : (isReference ? ('/'+fieldVal) : null),
                isThreshold: fld.isThreshold
            }

            tableCell.isText = (!tableCell.isUrl && !tableCell.isDate) ? true : false;
            rec.tableData.push(tableCell);
        }
    }

    openUpsertRecordModal(event){
        if(event.currentTarget.dataset && event.currentTarget.dataset.recordid){
            this.selectedRecordId = event.currentTarget.dataset.recordid;
        }
        else{
            this.selectedRecordId = null;
        }
        this.template.querySelector('.upsert-record-modal').openModal();
    }

    handleNewRecordCreateSuccess(event){
        //console.log('handleNewRecordCreateSuccess:', JSON.stringify(event.detail));
        let recordObj = event.detail.record;
        let isUpdate = event.detail.isUpdate;
        //console.log('isUpdate:', isUpdate);
        var newRecord = new Object();
        newRecord.Id = recordObj.id;
        for(let fldName in recordObj.fields){
            var val = recordObj.fields[fldName].value;
            var displayVal = recordObj.fields[fldName].displayValue;
            var fieldVal;
            if(val && typeof val === 'object' && val.fields){
                fieldVal = {};
                try{
                    for(let fld in val.fields){
                        fieldVal[fld] = val.fields[fld].value;
                    }
                }
                catch(ex){
                    console.log('error parsing fields for:', fldName);
                }
            }
            else{
                fieldVal = val || displayVal;
            }
            newRecord[fldName] = fieldVal;
        }
        this.generateTableData(newRecord);
        //console.log('newRecord final:', JSON.stringify(newRecord));
        let newRecordList = [];
        if(isUpdate){
            for(let rec of this.records){
                if(rec.Id === newRecord.Id){
                    newRecordList.push(newRecord);
                }
                else{
                    newRecordList.push(rec);
                }
            }
            this.records = newRecordList;
        }
        else{ //isInsert
            this.records.push(newRecord);
        }
        //console.log('this.records:', JSON.stringify(this.records));
        this.setupPagination();
    }

    setupPagination(){

        let counter = 0;
        let pageNum = 1;
        this.currentPage = 1;
        this.recordsByPage = {};
        
        this.recordsPerPage = (!this.recordsPerPage || this.recordsPerPage < 1) 
            ? DEFAULT_RECORDS_PER_PAGE 
            : this.recordsPerPage;

        console.log('setupPagination for ', this.recordsPerPage, ' records per page');
        for(let rec of this.records){
            //console.log('equal? ', counter, this.recordsPerPage, counter == this.recordsPerPage);
            if(counter == this.recordsPerPage){
                pageNum++;
                counter = 0;
            }
            if(!this.recordsByPage[pageNum]){
                this.recordsByPage[pageNum] = [rec];
            }
            else{
                this.recordsByPage[pageNum].push(rec);
            }
            counter++;
        }
        //console.log('this.recordsByPage', JSON.stringify(this.recordsByPage));
        this.recordsToShow = this.recordsByPage[this.currentPage];
        let pageCount = 0;
        for(let num in this.recordsByPage){
            pageCount++;
        }
        this.totalPages = pageCount;
    }

    handlePageForward(event){
        if(this.currentPage === this.totalPages){
            return;
        }
        else{
            this.currentPage++;
            this.recordsToShow = this.recordsByPage[this.currentPage]; 
        }
    }

    handlePageBack(event){
        if(this.currentPage === 1){
            return;
        }
        else{
            this.currentPage--;
            this.recordsToShow = this.recordsByPage[this.currentPage]; 
        }
    }

    handleRecordsPerPageChanged(event){
        let recordsPerPage = event.currentTarget.value;
        //console.log('new recordsPerPage:', recordsPerPage);
        this.recordsPerPage = recordsPerPage;
        this.setupPagination();
    }

    handleColumnSort(event){
        //console.log('handleColumnSort...');
        if(this.disableSort) return
        let fieldName = event.currentTarget.dataset.fieldname;
        var fieldType = event.currentTarget.dataset.datatype;
        this.sortColumn(fieldName, fieldType, null);
    }

    sortColumn(fieldName, fieldType, sortDir)
    {
        for(let fld of this.fieldObjects){
           // console.log('field match?:', fld.fieldPath, fieldName);
            if(fld.fieldPath === fieldName){
                //console.log('has field match:', fieldName, fieldType);
                if(fld.isSort == false){
                    fld.isSort = true;
                    fld.sortIcon = ICON_ARROW_DOWN;
                }
                else{
                    fld.sortIcon = fld.sortIcon === ICON_ARROW_DOWN 
                        ? ICON_ARROW_UP 
                        : ICON_ARROW_DOWN;
                }
                sortDir = (sortDir && sortDir === SORT_DESC) || fld.sortIcon === ICON_ARROW_DOWN ? SORT_DESC : SORT_ASC;
            }
            else{
                //console.log('setting isSort false:', fld.fieldPath);
                fld.isSort = false;
            }
        }
        this.sortRecords(fieldName, fieldType, sortDir);
        this.setupPagination();
    }

    sortRecords(fieldName, dataType, sortDirection) {
        var sortVal = sortDirection === SORT_ASC ? -1 : 1;
        var convertDataType = function(val, dataType){
            switch(dataType){
                case DATA_TYPE_DATE:
                    return Date.parse(val);
                case DATA_TYPE_DOUBLE:
                    return Number(val);
            }
            return val;
        }
        this.records.sort(function(a,b){
            let aVal = a[fieldName] ? convertDataType(a[fieldName], dataType) : '';
            let bVal = b[fieldName] ? convertDataType(b[fieldName], dataType) : '';
            if(dataType === DATA_TYPE_DATE || dataType === DATA_TYPE_DOUBLE){
                if(aVal > bVal)
                    return sortVal;
                else if(aVal < bVal)
                    return (sortVal * -1);
                else
                    return 0;
            }
            else{
                return (aVal.localeCompare(bVal) * sortVal);
            }
        });
    }

    allowDrop(ev) {
		ev.preventDefault();
		ev.stopPropagation();
		ev.dataTransfer.dropEffect = "move";
		//ev.target.parentElement.classList.add('dragover');
	}

	dropItem(event) {
		event.preventDefault();
		event.stopPropagation();
        let moveIndex = (event.dataTransfer.getData('index') - 1);
        let targetIndex = (event.currentTarget.dataset.index - 1);
        let record = this.records.splice(moveIndex, 1)[0];
        this.records.splice(targetIndex, 0, record);
        let index = this.rowNumber;
        this.runningThresholdSum = 0;
        this.records.forEach(item => {
            item.index = index;
            item.isChanged = item.isChanged || item.index !== item.initialIndex ? true : false;
            item[this.rankField] = index;
            item.classList = this.tableRowClasses;
            item.tableData.forEach(field =>{
                if(field.fieldPath === this.rankField)
                {
                    field.value = index;
                }
                console.log('is threshold...' + item.isThreshold);
                if(field.isThreshold)
                {
                    console.log('running threshold sum...' + this.runningThresholdSum);
                    console.log('value...' + field.value);
                    item.runningSum = Number((this.runningThresholdSum + Number(field.value)).toFixed(this.numberAccuracy));
                    console.log('running sum...' + item.runningSum);
                    if(item.runningSum > this.threshold 
                        && this.runningThresholdSum <= this.threshold)
                    {
                        item.classList += ' threshold';
                    }
                    this.runningThresholdSum = item.runningSum;
                }
            });
            index++;
        });
        fireEvent(this.pageRef, this.dropEventName, this.records);
        this.sortColumn(this.rankField, DATA_TYPE_DOUBLE, SORT_DESC);
        this.toggleDraggableClass();
	}

	startDrag(event) {
		event.dataTransfer.dropEffect = "move";
        let index = event.currentTarget.dataset.index;
        event.dataTransfer.setData('index', index);
	}

	dragLeave(ev) {
		var el = ev.target.parentElement;
		if (el) {
			el.classList.remove('dragover');
		}
	}

	dragEnd(ev) {
		this.dragIndex = -1;
		this.toggleDraggableClass();
    }
    
    toggleDraggableClass() {
		// var elms = this.template.querySelectorAll('.draggable');
		// elms.forEach(el => {
		// 	if (el.index === this.dragIndex) {
		// 		el.parentElement.classList.add('dragover');
		// 	} else {
		// 		el.parentElement.classList.remove('dragover');
		// 	}
		// });
	}

}