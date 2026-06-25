import { LightningElement, api } from 'lwc';

export default class Parent1 extends LightningElement {
    childOneSelected = false;
    childTwoSelected = false;

    get childOneStatus() {
        return this.childOneSelected ? 'Selected' : 'Deselected';
    }

    get childTwoStatus() {
        return this.childTwoSelected ? 'Selected' : 'Deselected';
    }

    handleSelectionChange(event) {
        const name = event.detail.name;
        const isSelected = event.detail.isSelected;
        if (name === 'Child One') {
            this.childOneSelected = isSelected;
        } else if (name === 'Child Two') {
            this.childTwoSelected = isSelected;
        }
    }

    @api
    resetChildren() {
        this.childOneSelected = false;
        this.childTwoSelected = false;

        const children = this.template.querySelectorAll('c-child-one');
        children.forEach(function (child) {
            child.reset();
        });
    }
}