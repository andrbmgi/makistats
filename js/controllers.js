'use strict';

/* Controllers */
app.controller('mainCtrl', ['$scope', '$rootScope', '$http', '$timeout', '$q',
  function tutorialCtrl($scope, $rootScope, $http, $timeout, $q) {



  function addSuccessMessage(HTTPstatus, message) {
    if (!$scope.successList) {
      $scope.successList = [];
    };
    var successObject = { 'status': HTTPstatus, 'message': message };
    $scope.successList.push(successObject);
    $timeout(function() {
      $scope.successList.splice(successObject, 1);
    }, 5000);
  }

  function addErrorMessage(HTTPstatus, message) {
    if (!$scope.errorList) {
      $scope.errorList = [];
    };
    var errorObject = { 'status': HTTPstatus, 'message': message };
    $scope.errorList.push(errorObject);
    $timeout(function() {
      $scope.errorList.splice(errorObject, 1);
    }, 20000);
  }

	$scope.update = function() {
    
    $scope.timetag = new Date().getTime();
    //$http.get('http://boredrich.de/makiscrape/fetchMakistats.pl').
    $http.get('http://boredrich.de/makiscrape/makiscrape.json?'+$scope.timetag).
      success(function(data, status, headers, config) {
        addSuccessMessage(status, "JSON successfully loaded.");
        $scope.status = status;
        data.messages.splice(0, 1);
        $scope.data = data;
      }).
      error(function(data, status, headers, config) {
        addErrorMessage(status, "An error occured.");
        $scope.status = status;
        $scope.data = data;
        console.log(data);
      });
  };
    
  $scope.update();

  $scope.getCount = function(scope) {
    var count = 0;
    if ($scope.data) {
      angular.forEach($scope.data.messages, function(message, key) {
          if (message.data === undefined) {  } else {
            message.orderDate = 99990000;
            message.noticeDate = 99990000;
            message.trackingDate = 99990000;
            message.receivedDate = 99990000;
            if (message.data.orderDate.year != 'n/a') {
              message.orderDate = parseInt(message.data.orderDate.year)*10000 + parseInt(message.data.orderDate.month)*100 + parseInt(message.data.orderDate.day);  
            };
            if (message.data.notice.year != 'n/a') {
              message.noticeDate = parseInt(message.data.notice.year)*10000 + parseInt(message.data.notice.month)*100 + parseInt(message.data.notice.day);  
            };
            if (message.data.tracking.year != 'n/a') {
              message.trackingDate = parseInt(message.data.tracking.year)*10000 + parseInt(message.data.tracking.month)*100 + parseInt(message.data.tracking.day);
            };
            if (message.data.received.year != 'n/a') {
              message.receivedDate = parseInt(message.data.received.year)*10000 + parseInt(message.data.received.month)*100 + parseInt(message.data.received.day);
            };
            if (message.data[scope].year != 'n/a') {
              //messages.splice(key, 1);
              //console.log(message.data.notice);
              count++;
            };
          };
      });
    };
    return count;
  };

  $scope.log = function(text) {
    console.log(text);
  };

  function ifDateAvail(message, key) {
    if (message.data[key].year != 'n/a') {
      return message.data[key].year+'-'+message.data[key].month+'-'+message.data[key].day;
    } else {
      return '';
    }
  };

  $scope.getCsvHeader = function() {
    return ['Name', 'Type', 'Ramen', 'Color', 'Country', 'Shipping', 'Order', 'Notice', 'Tracking', 'Received', 'LastEdited', 'Link', 'OriginalPost'];
  };
  $scope.getCsvArray = function() {
    var array = [];
    if ($scope.data) {
      angular.forEach($scope.data.messages, function(message, key) {
        var orderDate = ifDateAvail(message, 'orderDate');
        var notice = ifDateAvail(message, 'notice');
        var tracking = ifDateAvail(message, 'tracking');
        var received = ifDateAvail(message, 'received');
        array.push({  a: message.poster,
                      b: message.data.type,
                      c: message.data.ramen,
                      d: message.data.color,
                      e: message.data.country,
                      f: message.data.shipping,
                      g: orderDate,
                      h: notice,
                      i: tracking,
                      j: received,
                      k: message.data.lastEdited.year+'-'+message.data.lastEdited.month+'-'+message.data.lastEdited.day,
                      l: message.link,
                      m: message.content});
      });
    };
    return array;
  };

}]);