import { LightningElement } from 'lwc';
export default class LifecycleDemo extends LightningElement {
    counter = 0;
    isMessageVisible = false;
    constructor() {
        super(); 
        console.log(' Lifecycle Hook: constructor() executed ');
    }
    connectedCallback() {
        console.log(' Lifecycle Hook: connectedCallback() executed ');
    }
    renderedCallback() {
        console.log(' Lifecycle Hook: renderedCallback() executed ');
    }
    handleIncrement() {
        this.counter += 1;
    }
    handleToggleMessage() {
        this.isMessageVisible = !this.isMessageVisible;
    }
}