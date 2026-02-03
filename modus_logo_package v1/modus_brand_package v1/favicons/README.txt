MODUS FAVICON PACKAGE
=====================

Files included:
- favicon.svg (32x32) - Modern browsers, scalable
- favicon-16.svg (16x16) - Small favicon for tabs
- apple-touch-icon.svg (180x180) - iOS home screen icon

Implementation:

Add this to your HTML <head>:

<link rel="icon" type="image/svg+xml" href="/favicon.svg">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png">

Notes:
- SVG favicons are supported in modern browsers and scale perfectly
- For broader compatibility, also export PNGs using a tool like realfavicongenerator.net
- The apple-touch-icon is used when users add your site to their iOS home screen
