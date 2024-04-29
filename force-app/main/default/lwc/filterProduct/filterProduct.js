/*
 * *********************************************************
 Class Name         : filterProduct
 Created Date       : Feb 14 , 2024
 @description       : Lightning web component for filtering products and configuring product details. This component 
                      fetches product data, applies filters, and allows users to configure product details.
 @author            : RedFerns Tech
 *********************************************************
 */

import { LightningElement, wire, track } from 'lwc';
import getProductWithUnitPrice from '@salesforce/apex/ProductController.getAllProductsWithUnitPrice';
import getProductToFilter from '@salesforce/apex/ProductController.getProductsTofilter';
import getFieldSetForFilter from '@salesforce/apex/ProductController.getFieldSetForFilter';
import getFieldSetForConfigurationTable from '@salesforce/apex/ProductController.getFieldSetForConfigurationTable';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { createRecord, deleteRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';

export default class filterProduct extends LightningElement {

    selectedPricebookId = '';
    recordId = '';
    selectedObjectName;
    pricebookEntryId;
    @track productWithPricebookResponse = [];
    @track columns = [];
    @track columnsForConfigurationTable = [];
    @track selectedproductValues = [];
    @track allSelectedRow = [];
    productToFilter;
    productWithUnitPrice;
    showFilter;
    initialProductResponse;
    fieldSetItemsForFilter = [];
    filterInputsValues = {};
    showProduct = false;
    disableApply = true;
    disableNext = true;
    showConfigurationPage = false;
    showFilterIcon = true;
    showCancelButton = true;
    showNextbutton = true;
    showBackbutton = false;
    disableCancel = true;
    showPillContainer = false;
    disableIcon = true;
    productTableColumnSize = 'slds-col slds-size_12-of-12';
    noteMessage;
    deleteCreatedRecords;
    createdRecordIds = [];
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;


    /* @description: Sorts an array of objects by a specified field in ascending or descending order.
                     Uses the primer function to preprocess values if provided.
    */
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    // @description: Event handler for sorting product data in a data table based on a specified field and direction.
    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.productWithPricebookResponse];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.productWithPricebookResponse = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    // @description: get recordId and pricebookId from current page reference.
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state?.c__recordId;
            this.selectedPricebookId = currentPageReference.state?.c__pricebookId
        }
    }

    // @description: Handles the click event to save the selected products.
    async handleClickSave(event) {
        this.deleteCreatedRecords = false;
        this.createdRecordIds = [];
        let allowRecordCreation = true;
        let parsedDraftValues = JSON.parse(JSON.stringify(event.detail.draftValues));
        parsedDraftValues.forEach(edit => {
            const index = parseInt(edit.id.split('-')[1]);
            if (index < this.selectedproductValues.length) {
                for (const key in edit) {
                    if (key !== 'id' && edit.hasOwnProperty(key)) {
                        this.selectedproductValues[index][key] = edit[key];
                    }
                }
            }
        });

        this.selectedproductValues.forEach(item => {
            if (!item.Quantity || item.Quantity === '' || !item.UnitPrice || item.UnitPrice === '') {
                if (this.selectedObjectName == 'Opportunity' || this.selectedObjectName == 'Quote') {
                    this.showToast('Error', 'Required Field Missing. Please check Quantity and Sales Price ', 'error', 'sticky');
                } else if (this.selectedObjectName == 'Order') {
                    this.showToast('Error', 'Required Field Missing. Please check Quantity and Unit Price ', 'error', 'sticky')
                }
                allowRecordCreation = false;
                return;
            }
        });

        if (allowRecordCreation) {
            let apiName;
            let parentId;
            if (this.selectedObjectName == 'Opportunity') {
                apiName = 'OpportunityLineItem';
                parentId = { OpportunityId: this.recordId };
            }
            if (this.selectedObjectName == 'Quote') {
                apiName = 'QuoteLineItem';
                parentId = { QuoteId: this.recordId };
            }
            if (this.selectedObjectName == 'Order') {
                apiName = 'OrderItem';
                parentId = { OrderId: this.recordId };
            }

            let recordsToInsert = this.selectedproductValues.map(item => {
                let { ListPrice, Product2Id, label, iconName, type, ...newItem } = item;
                return {
                    ...newItem,
                    ...parentId,
                }
            });

            try {
                const promises = recordsToInsert.map(inputs => {
                    
                    return createRecord({ apiName: apiName, fields: inputs })
                        .then(result => {
                            if (result.id) {
                                this.createdRecordIds.push(result.id);
                                if (this.deleteCreatedRecords) {
                                    this.deleteExistingRecords();
                                }
                            }
                        })
                });
                await Promise.all(promises)
                    .then(() => {
                        this.showToast('Success', 'Record Created Successfully', 'success', 'dismissible');
                        window.location.href = `/lightning/r/${this.selectedObjectName}/${this.recordId}/view`;
                    })
                    .catch(error => {
                        this.deleteCreatedRecords = true;
                        this.deleteExistingRecords();
                        let errorMessage;
                        const outputErrors = Array.isArray(error.body?.output?.errors) && error.body.output.errors.length > 0;
                        if (outputErrors) {
                            errorMessage = error.body.output.errors[0].message;
                        } else if (error.body?.output?.fieldErrors && Object.keys(error.body.output.fieldErrors).length > 0) {
                            const fieldErrorKeys = Object.keys(error.body.output.fieldErrors);
                            const fieldErrors = error.body.output.fieldErrors[fieldErrorKeys[0]];
                            errorMessage = fieldErrors[0].message;
                        } else {
                            errorMessage = error.body?.message || 'An unexpected error occurred';
                        }

                        this.showToast('Error', errorMessage, 'error', 'sticky');
                    });

            } catch (error) {
                this.showToast('Error', error.body.message, 'error', 'sticky');
            }
        }
    }

    // @description: Deletes existing records from the database and updates record IDs.
    deleteExistingRecords() {
        const recordIdsToDelete = [...this.createdRecordIds];

        for (const recordId of recordIdsToDelete) {
            deleteRecord(recordId)
                .then(() => {
                    this.createdRecordIds = this.createdRecordIds.filter(id => id !== recordId);
                })
                .catch(error => {
                    if (error.body.output.errors[0].errorCode === 'ENTITY_IS_DELETED') {
                        this.createdRecordIds = this.createdRecordIds.filter(id => id !== recordId);
                    }
                });
        }
    }

    /* @description: Wired method to retrieve product data with unit price and fetch the object name based on 
                  passed record ID. fetches data table column from product object.
     */
    @wire(getProductWithUnitPrice, { pricebookId: '$selectedPricebookId', recordId: '$recordId' })
    getProductWithUnitPrice_Response({ data, error }) {
        if (data) {
            this.showProduct = true;
            this.disableCancel = false;
            this.disableIcon = false;
            let columnsForProductTable;
            let productList;
            let pricebookEntryList;
            data.forEach(value => {
                if (value.columnForProductTable) {
                    columnsForProductTable = value.columnForProductTable;
                }
                if (value.objectName) {
                    this.selectedObjectName = value.objectName;
                }
                if (value.productList) {
                    productList = value.productList;
                }
                if (value.pricebookEntryList) {
                    pricebookEntryList = value.pricebookEntryList;
                }
            });

            this.columns = columnsForProductTable.map(f => {
                if (f.apiName == 'Name') {
                    return { label: f.label, fieldName: f.apiName, sortable: true }
                } else {
                    return { label: f.label, fieldName: f.apiName }
                }
            });
            this.columns.push({ label: "List Price", fieldName: "ListPrice", sortable: true });

            let productListWithPrice = productList.map(product => {
                let matchingProduct = pricebookEntryList.find(pricebookEntry => pricebookEntry.Product2Id === product.Id);
                if (matchingProduct) {
                    return {
                        ...product,
                        UnitPrice: matchingProduct.UnitPrice,
                        ListPrice: matchingProduct.UnitPrice,
                        PricebookEntryId: matchingProduct.Id
                    };
                } else {
                    return product;
                }
            });
            this.initialProductResponse = JSON.parse(JSON.stringify(productListWithPrice));
            const cloneData = [...productListWithPrice];
            cloneData.sort(this.sortBy('Name', 1));
            this.productWithPricebookResponse = cloneData;
        }
        if (error) {
            console.log('Error In Wire ' + JSON.stringify(error));
        }
    }

    // @description: Wired method to retrieve field set for configuration table.
    @wire(getFieldSetForConfigurationTable, { recordId: '$recordId' })
    getFieldSetForConfigurationTable_Response({ error, data }) {
        if (data) {
            this.columnsForConfigurationTable = JSON.parse(data).map(f => {
                if (f.apiName == 'Product2Id' || f.apiName == 'ListPrice') {
                    return { label: f.label, fieldName: f.apiName, displayReadOnlyIcon: true }
                } else if (f.type == 'DATE') {
                    return { label: f.label, fieldName: f.apiName, editable: true, type: 'date-local' }
                } else if (f.type == 'DOUBLE' || f.type == 'PERCENT') {
                    return { label: f.label, fieldName: f.apiName, editable: true, type: 'number' }
                } else {
                    return { label: f.label, fieldName: f.apiName, editable: true }
                }
            })
        } else if (error) {
            console.log(error);
        }
    }

    // Description: Wired method to retrieve product data for filtering.
    @wire(getProductToFilter, { pricebookId: '$selectedPricebookId' })
    getProductToFilter_Response({ data, error }) {
        if (data) {
            this.productToFilter = data;
        }
    }

    // Description: Wired method to retrieve field set for filter from product object.
    @wire(getFieldSetForFilter)
    getFieldSetForFilter_Response({ error, data }) {
        if (data) {
            this.fieldSetItemsForFilter = JSON.parse(data).map(f => {
                return { label: f.label, apiName: f.apiName, type: f.type }
            })
        } else if (error) {
            console.log(error);
        }
    }

    // Description: Handles the change event of filter inputs and stores it in a array.
    handleChangeInputs(event) {
        this.disableApply = false;
        const { name, value } = event.target;
        if (value !== '') {
            this.filterInputsValues = {
                ...this.filterInputsValues,
                [name]: value.toLowerCase(),
            };
        } else {
            const { [name]: valueToRemove, ...remainingValues } = this.filterInputsValues;
            this.filterInputsValues = remainingValues;
        }
    }

    // Description: Filters products based on filter inputs.
    doProductFilter() {
        let filteredProducts = {};
        filteredProducts = this.productToFilter.filter(product => {
            let isMatching = true;
            for (const key in this.filterInputsValues) {
                if (this.filterInputsValues.hasOwnProperty(key)) {
                    const filterValue = this.filterInputsValues[key].trim().toLowerCase();
                    const productValue = (product[key] && product[key].trim().toLowerCase()) || '';
                    if (!productValue || !productValue.includes(filterValue)) {
                        isMatching = false;
                        break;
                    }
                }
            }
            if (isMatching) {
                return product;
            }
        });
        let foundProduct = [];
        this.initialProductResponse.forEach(product => {
            let filteredProduct = filteredProducts.find(filteredProduct => filteredProduct.Id === product.Id);
            if (filteredProduct) {
                foundProduct.push(product);
            }
        });
        this.productWithPricebookResponse = foundProduct;
    }

    // Description: Handles the click event to apply the filter.
    handleClickApplyFilter() {
        this.doProductFilter();
    }

    // Description: Handles the click event to clear all filters.
    handleClickClearAllFilter() {
        this.template.querySelectorAll('lightning-input').forEach(each => { each.value = ''; });
        this.filterInputsValues = {};
    }

    // Description: Retrieves the selected products from the datatable.
    getSelectedProduct(event) {
        this.disableNext = false;
        this.showPillContainer = true;
        const selectedRows = event.detail.selectedRows;

        this.allSelectedRow = this.allSelectedRow || [];
        this.allSelectedRow.push(...selectedRows.filter(selectedRow => !this.allSelectedRow.some(row => row.Id === selectedRow.Id)));

        this.selectedproductValues = this.allSelectedRow.map(item => {
            const newItem = {};
            this.columnsForConfigurationTable.forEach(field => {
                if (field.fieldName === 'Product2Id') {
                    newItem[field.fieldName] = item.Name;
                } else if (field.fieldName in item) {
                    newItem[field.fieldName] = item[field.fieldName];
                } else {
                    newItem[field.fieldName] = '';
                }
            });
            newItem.PricebookEntryId = item.PricebookEntryId;
            newItem.label = item.Name;
            newItem.type = 'icon';
            newItem.iconName = 'utility:checkout';
            return newItem;
        });
        if (this.selectedproductValues.length === 0) {
            this.disableNext = true;
        }
    }

    // Description: Handles the click event to delete the selected product.
    handleRemovePillContainer(event) {
        const index = event.detail.index;
        this.selectedproductValues.splice(index, 1);
        const id = event.detail.item.PricebookEntryId;
        const indexToRemove = this.allSelectedRow.findIndex(item => item.PricebookEntryId === id);
        if (indexToRemove !== -1) {
            this.allSelectedRow.splice(indexToRemove, 1);
        }
        if (this.selectedproductValues.length === 0) {
            this.disableNext = true;
        }
    }

    // Description: Handles the click event to navigate to the next step in the process.
    handleClickNext() {
        if (this.selectedObjectName == 'Opportunity' || this.selectedObjectName == 'Quote') {
            this.noteMessage = 'Note: Quantity and Sales Price are required fields.'
        } else if (this.selectedObjectName == 'Order') {
            this.noteMessage = 'Note: Quantity and Unit Price are required fields.'
        }
        this.showConfigurationPage = true;
        this.showProduct = false;
        this.showFilter = false;
        this.showFilterIcon = false;
        this.showCancelButton = false;
        this.showNextbutton = false;
        this.showBackbutton = true;
        this.productTableColumnSize = 'slds-col slds-size_12-of-12';
        this.showPillContainer = false;
        this.productWithPricebookResponse = this.initialProductResponse;
    }

    // Description: Handles the click event to navigate back to the previous step in the process.
    handleClickBack() {
        this.showConfigurationPage = false;
        this.showProduct = true;
        this.showFilterIcon = true;
        this.showCancelButton = true;
        this.showNextbutton = true;
        this.showBackbutton = false;
        this.showPillContainer = true;
    }

    // Description: Handles the click event to display the filter options.
    handleClickFilter() {
        this.showFilter = true;
        this.productTableColumnSize = 'slds-col slds-size_9-of-12';
    }

    // Description: Handles the click event to cancel the filter operation.
    handleClickCancelFilter() {
        this.showFilter = false;
        this.productTableColumnSize = 'slds-col slds-size_12-of-12';
    }

    // Description: Displays a toast message with the specified title, message, variant, and mode.
    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(event);
    }

    // Description: Handles the click event to cancel the operation and redirects to the record view.
    handleClickCancel() {
        window.location.href = `/lightning/r/${this.selectedObjectName}/${this.recordId}/view`;
    }

    // Description: Handles the click event to cancel the operation from the table and redirects to the record view.
    handleClickTableCancel() {
        window.location.href = `/lightning/r/${this.selectedObjectName}/${this.recordId}/view`;
    }
}