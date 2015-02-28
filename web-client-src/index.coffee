IndexController = ($scope, $http) ->
		$scope.lists = []
		$scope.people = []

		$scope.newList = ()->
			newList =
				name: "New List"
				people: []
			$scope.lists.push newList
			$scope.selectList newList

			$http.post "/newList",
				list: newList
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.saveList = ()->
			$http.post "/saveList",
				list: $scope.selectedList
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.deleteList = () ->
			$scope.lists = _.filter $scope.lists, (l)-> l.name isnt $scope.selectedList.name
			$http.post "/deleteList",
				list: $scope.selectedList
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.newPerson = ()->
			newPerson =
				name: 'New Person'
			$scope.people.push newPerson
			$scope.selectPerson newPerson
			$http.post "/newPerson", {person: newPerson}
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.deletePerson = ()->
			$scope.people = _filter $scope.people, (p)->
				p.name isnt $scope.selectedPerson.name
			$http.post "/deletePerson",
				person: $scope.selectedPerson
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.savePerson = ()->
			$http.post "/savePerson",
				person: $scope.selectedPerson
			.success (data,status,headers,config)-> delete $scope.error
			.error (data,status,headers,config)-> $scope.error = data

		$scope.togglePerson = (person)->
			list = $scope.selectedList
			found = _.find list.people, (p)-> person.name is p.name
			if found
				$scope.removeFromList(person)
			else
				$scope.addToList(person)

		$scope.addToList = (person)->
			list = $scope.selectedList
			if person and list
				list.people.push person
				$http.post "/addToList",
					list: list
					person: person
				.success (data,status,headers,config)-> delete $scope.error
				.error (data,status,headers,config)-> $scope.error = data

		$scope.removeFromList = (person)->
			list = $scope.selectedList
			if person and list
				list.people = _.filter list.people, (p)-> p.name isnt person.name
				$http.post "/removeFromList",
					list: list
					person: person
				.success (data,status,headers,config)-> delete $scope.error
				.error (data,status,headers,config)-> $scope.error = data

		$scope.selectList = (list)->
			$scope.selectedList = list
			for person in $scope.people
				found = _.find list.people, (p)-> person.name is p.name
				person.checked = found isnt undefined

		$scope.selectPerson = (person)->
			$scope.selectedPerson = person

		$scope.closeErrors = () -> delete $scope.error

IndexController.$inject = [ '$scope', '$http']


app = angular.module 'CallFanout', [ 'ngRoute' ]
.config ['$routeProvider', ($routeProvider)->

	$routeProvider.when '/',
		controller : 'IndexController'
		templateUrl : 'index.html'

		# .when '/Path',
		# controller : 'PathController'
		# templateUrl : 'html/Path.html'
	.otherwise
		redirectTo : '/'
]

app.controller 'IndexController', IndexController
