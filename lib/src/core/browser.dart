part of dartkart.core;

/**
 * true, if we are currently running in Mozilla Firefox
 */
bool get isFirefox =>
    window.navigator.userAgent.toLowerCase().indexOf('firefox') > -1;

