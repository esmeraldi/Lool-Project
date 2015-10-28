var skipAllIntervals = false;

var visualTests = (function () {
    var __visualTests = {
        intervals: [],

        skipAllAnimations: function () {
            if (typeof $ != 'undefined') {
                $.fx.off = true;
            }

            skipAllIntervals = true;

            for (var i = 0; i < this.intervals.length; i++) {
                window.clearInterval(this.intervals[i]);
            }
        }
    }

    var originSetInterval = window.setInterval;
    window.setInterval = function (handler, timeout) {
        var intervalId = originSetInterval(handler, timeout);
        __visualTests.intervals.push(intervalId);
        return intervalId;
    };

    return {
        skipAllAnimations: function () {
            __visualTests.skipAllAnimations();
        }
    }
})();