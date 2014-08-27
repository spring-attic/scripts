function Hello($scope, $http) {
    $http.get(window.location.protocol + '//' + window.location.host+'/proxy/').
        success(function(data) {
            $scope.greeting = data;
        });
}
