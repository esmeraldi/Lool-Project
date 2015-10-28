declare module lemur {
    export class Template {
        templateString: string;
        constructor(templateString?: string);
        evaluate(templateObject: {}): string;
        isObjectEmpty(templateObj: {}): boolean;
        replacePlaceholder(evaluatedString: string, key: string, value: string): string;
    }
}