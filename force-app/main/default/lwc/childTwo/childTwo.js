import { LightningElement, api } from 'lwc';

export default class ChildTwo extends LightningElement {
    @api name;
    isSelected = false;

    get buttonLabel() {
        return this.isSelected ? 'Deselect' : 'Select';
    }

    handleClick() {
        this.isSelected = !this.isSelected;

        this.dispatchEvent(new CustomEvent('selectionchange', {
            bubbles: true,
            composed: true,
            detail: {
                name: this.name,
                isSelected: this.isSelected
            }
        }));
    }

    @api
    reset() {
        this.isSelected = false;
    }
}