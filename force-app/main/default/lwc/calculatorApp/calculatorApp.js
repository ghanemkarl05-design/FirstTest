import { LightningElement } from 'lwc';

export default class CalculatorApp extends LightningElement {
    expression = '';
    displayValue = '0';
    firstOperand = null;
    operator = null;
    waitingForSecondOperand = false;

    handleNumber(event) {
        const digit = event.target.dataset.value;

        if (this.waitingForSecondOperand) {
            this.displayValue = digit;
            this.waitingForSecondOperand = false;
        } else {
            this.displayValue = this.displayValue === '0' ? digit : this.displayValue + digit;
        }
    }

    handleDecimal() {
        if (this.waitingForSecondOperand) {
            this.displayValue = '0.';
            this.waitingForSecondOperand = false;
            return;
        }
        if (!this.displayValue.includes('.')) {
            this.displayValue += '.';
        }
    }

    handleOperator(event) {
        const nextOperator = event.target.dataset.value;
        const inputValue = parseFloat(this.displayValue);

        if (this.operator && this.waitingForSecondOperand) {
            this.operator = nextOperator;
            this.expression = `${this.firstOperand} ${this.symbolFor(nextOperator)}`;
            return;
        }

        if (this.firstOperand === null) {
            this.firstOperand = inputValue;
        } else if (this.operator) {
            const result = this.calculate(this.firstOperand, inputValue, this.operator);
            this.firstOperand = result;
            this.displayValue = String(result);
        }

        this.waitingForSecondOperand = true;
        this.operator = nextOperator;
        this.expression = `${this.firstOperand} ${this.symbolFor(nextOperator)}`;
    }

    handleEquals() {
        const inputValue = parseFloat(this.displayValue);

        if (this.operator === null || this.firstOperand === null) {
            return;
        }

        const result = this.calculate(this.firstOperand, inputValue, this.operator);
        this.expression = `${this.firstOperand} ${this.symbolFor(this.operator)} ${inputValue} =`;
        this.displayValue = String(result);

        this.firstOperand = null;
        this.operator = null;
        this.waitingForSecondOperand = false;
    }

    handleClear() {
        this.displayValue = '0';
        this.expression = '';
        this.firstOperand = null;
        this.operator = null;
        this.waitingForSecondOperand = false;
    }

    handleBackspace() {
        if (this.waitingForSecondOperand) {
            return;
        }
        if (this.displayValue.length > 1) {
            this.displayValue = this.displayValue.slice(0, -1);
        } else {
            this.displayValue = '0';
        }
    }

    calculate(first, second, operator) {
        switch (operator) {
            case '+':
                return first + second;
            case '-':
                return first - second;
            case '*':
                return first * second;
            case '/':
                return second === 0 ? 0 : first / second;
            default:
                return second;
        }
    }

    symbolFor(operator) {
        const map = { '+': '+', '-': '−', '*': '×', '/': '/' };
        return map[operator] || operator;
    }
}