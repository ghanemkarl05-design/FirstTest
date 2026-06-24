import { LightningElement } from 'lwc';

export default class ParentComponent10 extends LightningElement {
    parentValue = '';

    handleEvent(event) {

        this.parentValue = event.detail;
    }
}
