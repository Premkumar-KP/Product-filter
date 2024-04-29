/*
 * @description : Lightning web component for displaying and updating pricebook information.
 *                This component allows users to select a pricebook and navigate to the product selection page.
 */
import { LightningElement, wire, api } from 'lwc';
import getAllPricebook from '@salesforce/apex/ProductController.getPricebookDetail';
import getPricebookId from '@salesforce/apex/ProductController.getPricebookId';
import deleteRelatedLineItems from '@salesforce/apex/ProductController.deleteRelatedLineitem';
import { NavigationMixin } from "lightning/navigation";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MyModal from 'c/myModal';

export default class ShowPricebook extends NavigationMixin(LightningElement) {

    @api recordId;
    selectedPricebookId;
    pricebookDefaultValue;
    existingPricebookId;
    PricebookPicklistValues;

    // Description :  Wire method to retrieve all pricebooks.
    @wire(getAllPricebook)
    getAllPricebook_Response(response) {
        let { data, error } = response;
        if (data) {
            this.PricebookPicklistValues = data.map(p => {
                return { label: p.Name, value: p.Id }
            })
        }
    }

    // Description : Wire method to retrieve the pricebook ID associated with the record.
    @wire(getPricebookId, { recordId: '$recordId' })
    getPricebookId_Response({ data, error }) {

        if (data) {
            this.existingPricebookId = data;
            this.pricebookDefaultValue = data;
            this.selectedPricebookId = data;
        }
    }

    // Description :  Handles input change events, particularly for the pricebook selection.
    handleChangeInputs(event) {
        if (event.target.name == 'Pricebook') {
            this.selectedPricebookId = event.detail.value;
        }
    }
    // Description : Handles the click event for saving the pricebook selection.
    async handleClickSavePricebook() {
        if (this.existingPricebookId && this.selectedPricebookId && this.existingPricebookId === this.selectedPricebookId) {
            this.navigateToProductSelectionPage();
        }
        else if (!this.existingPricebookId && this.selectedPricebookId) {
            this.updatePricebookId();
        }
        else if (this.existingPricebookId && this.selectedPricebookId && this.existingPricebookId !== this.selectedPricebookId) {
            try {
                const result = await MyModal.open({
                    size: 'small',
                    label: 'Confirm Price Book Change',
                });
                if (result === 'okay') {
                    await deleteRelatedLineItems({ recordId: this.recordId })
                        .then(() => {
                            this.updatePricebookId();
                        })
                        .error(error => {
                            console.log('Error in delete Lineitem ' + JSON.stringify(error));
                        })
                }
            }
            catch (error) {
                console.log('Modal error ' + JSON.stringify(error));
            }
        }
    }

    // Description : Updates the pricebook ID associated with the record.
    updatePricebookId() {
        const recordInputs = {
            Id: this.recordId,
            Pricebook2Id: this.selectedPricebookId
        }
        try {
            updateRecord({ fields: recordInputs })
                .then(() => {
                    this.showToast('Success', 'pricebook updated successfully', 'success');
                    this.navigateToProductSelectionPage();
                })
                .error(error => {
                    console.log('Error ' + error);
                    this.showToast('error', error.body.message, 'error');
                })
        }
        catch (error) {
            console.log('Catch error ' + JSON.stringify(error));
        }
    }

    // Description : Navigates to the product selection page.
    navigateToProductSelectionPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'rft_cc__Product_Filter'
            },
            state: {
                c__recordId: this.recordId,
                c__pricebookId: this.selectedPricebookId,
            }
        });
    }

    // Description : Displays a toast message.
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible',
        });
        this.dispatchEvent(event);
    }
}