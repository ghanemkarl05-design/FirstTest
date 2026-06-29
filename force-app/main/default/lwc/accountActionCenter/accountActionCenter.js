import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecentAccounts from '@salesforce/apex/AccountActionCenterController.getRecentAccounts';
import getHotAccounts from '@salesforce/apex/AccountActionCenterController.getHotAccounts';
import getAccountsWithoutPhone from '@salesforce/apex/AccountActionCenterController.getAccountsWithoutPhone';
import updateAccountDescription from '@salesforce/apex/AccountActionCenterController.updateAccountDescription';


export default class AccountActionCenter extends NavigationMixin(LightningElement) {
    @track accounts = [];
    @track selectedAccount = null;
    isLoading = false;
    updatedDescription = '';

    get accountsCount() {
        return this.accounts ? this.accounts.length : 0;
    }

    async handleLoadRecent() {
        await this.fetchAccounts(getRecentAccounts);
    }

    async handleLoadHot() {
        await this.fetchAccounts(getHotAccounts);
    }

    async handleLoadNoPhone() {
        await this.fetchAccounts(getAccountsWithoutPhone);
    }

    async fetchAccounts(apexMethod) {
        this.isLoading = true;
        this.selectedAccount = null; 

        try {
            const result = await apexMethod();
            this.accounts = result.map(acc => ({
                ...acc,
                cardClass: 'slds-card slds-p-around_small slds-m-bottom_small custom-card'
            }));
        } catch (error) {
            this.showToast('Error Loading Accounts', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    
    handleNavigateToRecord(event) {
        
        event.stopPropagation(); 
        
        const accountId = event.target.dataset.id;
        
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: accountId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handleAccountSelect(event) {
        const accId = event.currentTarget.dataset.id;
        
        this.accounts = this.accounts.map(acc => {
            const isSelected = acc.Id === accId;
            return {
                ...acc,
                cardClass: isSelected 
                    ? 'slds-card slds-p-around_small slds-m-bottom_small custom-card card-selected' 
                    : 'slds-card slds-p-around_small slds-m-bottom_small custom-card'
            };
        });

        const rawAccount = this.accounts.find(acc => acc.Id === accId);
        this.selectedAccount = { ...rawAccount };
        this.updatedDescription = this.selectedAccount.Description || '';
    }

    handleDescriptionChange(event) {
        this.updatedDescription = event.target.value;
    }

    async handleUpdateDescription() {
        this.isLoading = true;

        try {
            await updateAccountDescription({ 
                accountId: this.selectedAccount.Id, 
                description: this.updatedDescription 
            });

            this.showToast('Success', 'Account description updated successfully', 'success');
            
            this.selectedAccount.Description = this.updatedDescription;
            this.accounts = this.accounts.map(acc => {
                if (acc.Id === this.selectedAccount.Id) {
                    return { ...acc, Description: this.updatedDescription };
                }
                return acc;
            });
        } catch (error) {
            this.showToast('Error Updating Account', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
