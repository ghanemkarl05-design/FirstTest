import { LightningElement } from 'lwc';

export default class EmployeeDetail extends LightningElement {
    name = '';
    age = '';
    email = '';
    employees = [];
    nextId = 1;

    handleNameChange(event) {
        this.name = event.target.value;
    }

    handleAgeChange(event) {
        this.age = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    handleAddEmployee() {
        if (!this.name || !this.age || !this.email) {
            return;
        }

        const newEmployee = {
            id: this.nextId,
            name: this.name,
            age: this.age,
            email: this.email
        };

        this.employees = [...this.employees, newEmployee];
        this.nextId++;

        this.name = '';
        this.age = '';
        this.email = '';
    }

    handleDeleteEmployee(event) {
        const idToRemove = parseInt(event.target.dataset.id, 10);
        this.employees = this.employees.filter((emp) => emp.id !== idToRemove);
    }

    get hasEmployees() {
        return this.employees.length > 0;
    }
}