// childComponent10.js
import { LightningElement, api } from 'lwc';

export default class ChildComponent10 extends LightningElement {
    @api childValue = '';

    handleInput(event) {
        this.childValue = event.target.value;

        // CRITICAL: This name MUST match your parent's HTML "ontextchange" handler
        const textEvent = new CustomEvent('textchange', {
            detail: event.target.value
        });
        this.dispatchEvent(textEvent);
    }
}
