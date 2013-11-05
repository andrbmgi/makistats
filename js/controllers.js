'use strict';

/* Controllers */
app.controller('mainCtrl', ['$scope', '$rootScope', '$http', '$timeout', '$q',
  function mainCtrl($scope, $rootScope, $http, $timeout, $q) {

  $scope.searchMode = 'orderDate';

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

  function quickSort(l, r, scope) {
    if (l<r) {
      var pivot = getPivot(l, r, scope);
      quickSort(l, pivot-1, scope);
      quickSort(pivot+1, r, scope);
    };
  };

  function getPivot(l, r, scope) {
    var i = l;
    var j = r-1;
    var pivot = $scope.data.messages[r][scope];
    do {
      while ( ($scope.data.messages[i][scope] <= pivot) && (i < r) ) {
        i++;
      };
      while ( ($scope.data.messages[j][scope] >= pivot) && (j > l) ) { 
        j--;
      };
      if (i<j) {
        var temp = $scope.data.messages[i];
        $scope.data.messages[i] = $scope.data.messages[j];
        $scope.data.messages[j] = temp;
      };
    } while(i<j);
    if ($scope.data.messages[i][scope] > pivot) {
      var temp = $scope.data.messages[i];
      $scope.data.messages[i] = $scope.data.messages[r];
      $scope.data.messages[r] = temp;
    };
    return i;
  };

  function strcmp(a, b) {
      a = a.toString(), b = b.toString();
      for (var i=0,n=Math.max(a.length, b.length); i<n && a.charAt(i) === b.charAt(i); ++i);
      if (i === n) return 0;
      return a.charAt(i) > b.charAt(i) ? -1 : 1;
  }

  function FUUUUUUUUUUUUU(ferk) {
    // rage level over 9000!!!!!11!!111!1
    // this method propagates the sorted position because the sorting function somehow couldnt
    // also its put same day messages in the same spot
    var pos = 0;
    var prev = 0;
    angular.forEach($scope.data.messages, function(message, key) {
      if (key==0) { 
        message[ferk+'Position'] = key; 
        prev = message[ferk];
      } else {
        if ( strcmp(message[ferk], prev) == 0 ) {
          message[ferk+'Position'] = pos; 
        } else {
          pos++;
          message[ferk+'Position'] = pos; 
        };
        prev = message[ferk];
      };
    });
  };

  function sortAll() {
      var i = 0;
      angular.forEach($scope.data.messages, function(message, key) {
          if (message.data === undefined) {  } else {
            message.orderDate = 99990000;
            message.noticeDate = 99990000;
            message.trackingDate = 99990000;
            message.receivedDate = 99990000;
            message.orderDatePosition = i;
            message.noticeDatePosition = i;
            message.trackingDatePosition = i;
            message.receivedDatePosition = i;
            message.postDate = i;
            i++;
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
          };
      });
      quickSort(0, i-1, 'orderDate');
      FUUUUUUUUUUUUU('orderDate');
      quickSort(0, i-1, 'noticeDate');
      FUUUUUUUUUUUUU('noticeDate');
      quickSort(0, i-1, 'trackingDate');
      FUUUUUUUUUUUUU('trackingDate');
      quickSort(0, i-1, 'receivedDate');
      FUUUUUUUUUUUUU('receivedDate');

  };

	$scope.update = function() {
    
    $scope.timetag = new Date().getTime();
    //$http.get('http://boredrich.de/makiscrape/fetchMakistats.pl').
    $http.get('http://boredrich.de/makiscrape/makiscrape.json?'+$scope.timetag).
      success(function(data, status, headers, config) {
        addSuccessMessage(status, "JSON successfully loaded.");
        $scope.status = status;
        data.messages.splice(0, 1);
        $scope.data = data;
        sortAll();
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

  $scope.searchFn = function(message) {
    if ($scope.searchMode == 'orderDate') {
      return message.orderDatePosition;
    } else if ($scope.searchMode == 'noticeDate') {
      return (message.noticeDatePosition*1000 + message.orderDatePosition);
    } else if ($scope.searchMode == 'trackingDate') {
      return (message.trackingDatePosition*1000000 + message.noticeDatePosition*1000 + message.orderDatePosition);
    } else if ($scope.searchMode == 'receivedDate') {
      return message.receivedDatePosition*1000000000 + message.trackingDatePosition*1000000 + message.noticeDatePosition*1000 + message.orderDatePosition;
    } else if ($scope.searchMode == 'poster') {
      return message.poster;
    };
    return message.postDate;
  };

}]);