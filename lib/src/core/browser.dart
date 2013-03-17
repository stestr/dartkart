part of dartkart.core;

/**
 * true, if we are currently running in Mozilla Firefox
 */
bool get isFirefox =>
    window.navigator.userAgent.toLowerCase().indexOf('firefox') > -1;

/**
 * true, if we are currently running in chrome
 */
bool get isChrome =>
    window.navigator.userAgent.toLowerCase().indexOf('chrome') > -1;

