'use strict';

/* App Module */
var app = angular.module('app', ['ngCsv']);

app.config(function($httpProvider){
    delete $httpProvider.defaults.headers.common['X-Requested-With'];
});

app.filter('killNA', function() {
  return function(messages, scope) {
    angular.forEach(messages, function(message, key) {
        if (message.data === undefined) {  } else {
          if (message.data[scope].year == 'n/a') {
            messages.splice(key, 1);
            //console.log(message.data.notice);
          };
        };
    });
    return messages;
  }
});