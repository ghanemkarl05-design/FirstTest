import { LightningElement, wire } from 'lwc';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import RATING_FIELD from '@salesforce/schema/Account.Rating';

export default class AccountFilterList extends LightningElement {
    allAccounts = [];      
    filteredAccounts = []; 
    selectedRating = 'All';
    ratingOptions = []; 

    
    @wire(getPicklistValues, { 
        recordTypeId: '012000000000000AAA', 
        fieldApiName: RATING_FIELD 
    })
    wiredPicklist({ error, data }) {
        if (data) {
            
            let options = data.values.map(pickVal => ({
                label: pickVal.label + ' Accounts', 
                value: pickVal.value
            }));

            this.ratingOptions = [{ label: 'All Accounts', value: 'All' }, ...options];
        }
    }


    @wire(getAccounts)
    wiredData({ error, data }) {
        if (data) {
            this.rawAccounts = data; 
        }
    }

    set rawAccounts(value) {
        this.allAccounts = value.map(acc => ({
            Id: acc.Id,
            Name: acc.Name || 'Not Specified',
            Industry: acc.Industry || 'Not Specified',
            Phone: acc.Phone || 'Not Specified',
            Rating: acc.Rating || 'Not Specified'
        }));
        this.filteredAccounts = this.allAccounts;
    }

    get rawAccounts() {
        return this.allAccounts;
    }

  
    handleFilterChange(event) {
        this.selectedRating = event.detail.value;

        if (this.selectedRating === 'All') {
            this.filteredAccounts = this.allAccounts;
        } else {
            this.filteredAccounts = this.allAccounts.filter(
                acc => acc.Rating === this.selectedRating
            );
        }
    }
}
