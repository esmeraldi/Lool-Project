var lemur;
(function (lemur) {
    var Template = (function () {
        function Template(templateString) {
            this.templateString = templateString || '';
        }
        Template.prototype.evaluate = function (templateObject) {
            if (!this.templateString.length || this.isObjectEmpty(templateObject)) {
                return;
            }

            var evaluatedString = this.templateString;

            for (var key in templateObject) {
                if (templateObject[key]) {
                    evaluatedString = this.replacePlaceholder(evaluatedString, key, templateObject[key].toString());
                }
            }

            return evaluatedString;
        };

        Template.prototype.isObjectEmpty = function (templateObj) {
            return false;
        };

        Template.prototype.replacePlaceholder = function (evaluatedString, key, value) {
            var keyPattern = new RegExp('\\${' + key + '}', 'gi');
            return evaluatedString.replace(keyPattern, value);
        };
        return Template;
    })();
    lemur.Template = Template;
})(lemur || (lemur = {}));
