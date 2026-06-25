import { LightningElement, wire } from 'lwc';
import getAccountsByEmployeeCount from '@salesforce/apex/AccountController.getAccountsByEmployeeCount';

export default class AccountSearch extends LightningElement {
    minEmployees = 0;

    @wire(getAccountsByEmployeeCount, { employeeCount: '$minEmployees' })
    accounts;

    handleNumberChange(event) {
        const inputValue = parseInt(event.target.value, 10);
        this.minEmployees = isNaN(inputValue) ? 0 : inputValue;
    }
}
