import { LightningElement } from 'lwc';

export default class GrandParent extends LightningElement {
    totalSelected = 0;

    handleSelectionChange(event) {
        const isSelected = event.detail.isSelected;
        if (isSelected) {
            this.totalSelected = this.totalSelected + 1;
        } else {
            this.totalSelected = this.totalSelected - 1;
        }
    }

    handleResetAll() {
        this.totalSelected = 0;
        const parent = this.template.querySelector('c-parent1');
        parent.resetChildren();
    }
}