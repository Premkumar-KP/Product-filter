/*
 * *********************************************************
 Class Name         : MyModal
 Created Date       : Feb 14 , 2024
 @description       : Represents a custom modal component based on the Lightning Modal base component.This component
                      provides methods for handling save and cancel actions.
 @author            : RedFerns Tech
 *********************************************************
 */
import LightningModal from 'lightning/modal';
import { api } from 'lwc';
export default class MyModal extends LightningModal {

@api label;
    /* @description    : Handles the save action in the modal and closes it with the 'okay' result.
       @param          : No parameters.
       @return String  : returns string
    */
    handleSave() {
        this.close('okay');
    }

    /*  @description   : Handles the cancel action in the modal and closes it with the 'cancel' result.
        @param         : No parameters.
        @return String : returns string
    */
    handleCancel() {
        this.close('cancel');
    }
}