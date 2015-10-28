/// <reference path="flexSlider.d.ts"/>
/// <reference path="fancybox.d.ts"/>
/// <reference path="jquery.d.ts"/>

interface SelectBoxItOptions {
    showEffect?: string;
    showEffectOptions?: {};
    showEffectSpeed?: string;
    hideEffeft?: string;
    hideEffeftOptions?: {};
    hideEffeftSpeed?: string;
    showFirstOption?: boolean;
    defaultText?: string;
    defaultIcon?: string;
    downArrowIcon?: string;
    theme?: string;
    keydownOpen?: boolean;
    isMobile?: boolean;
    copyAttributes?: string[];
    copyClasses?: string;
    native?: boolean;
    aggressiveChange?: boolean;
    selectWhenHidden?: boolean;
    viewport?: JQuery;
    similarSearch?: boolean;
    nativeMousdown?: boolean;
    customShowHideEvent?: boolean;
    autoWidth?: boolean;
    html?: boolean;
    populate?: string;
    dynamicPositioning?: boolean;
    hideCurrent?: boolean;
}

interface TruncateOptions {
    lines?: number;
    lineHeight?: number;
    ellipsis?: string;
    showMore?: string;
    showLess?: string;
}

interface JQuery {
    selectBoxIt(options?: SelectBoxItOptions): JQuery;
    smartresize(func: () => any): JQuery;
    truncate(options?: TruncateOptions): JQuery;
}

declare module "flexslider" {
    export = flexslider;
}

declare var flexslider: (options?: FlexSliderOptions) => SliderObject;

declare module "Masonry" {
    export = Masonry;
}
declare var Masonry: (container: any, options?: any) => void;

declare module "fancybox" {
    export = fancybox;
}
declare var fancybox: (options?: FancyboxOptions) => FancyboxMethods;

declare module "Truncate" {
    export = Truncate;
}

declare var Truncate: (element: Element, options?: TruncateOptions) => void;

declare var skrollr: any;
declare var Sitecore: any;

interface Suggestion {
    groupTitle: string;
    suggestions: Suggestion[];
    title: string;
    url: string;
}
