app = angular.module('gem-puzzle', ['ngAnimate'])


###
Represents a polygonal jewel
###
class Gem
  viewBox: 200

  constructor: (color, type) ->
    @color = color
    @type = type
    @exploded = false
    @points = @getPolygonPoints()

  getPolygonPoints: ->
    center = @viewBox / 2
    base = 2 * Math.PI / @type
    ([0...@type].map (index) ->
      angle = base * (index + 0.5)
      ([
        center + center * Math.cos(angle)
        center + center * Math.sin(angle)
      ].map (n) ->
        n.toFixed(0)
      ).join ' '
    ).join ','

###
The type of gem determines how many angles it has
###
Gem.Types = [
  5
  6
  8
  12
]

###
The color of the gem
###
Gem.Colors = [
  'red'
  'green'
  'blue'
  'yellow'
  'violet'
]


app.controller 'GemController', ($scope, $timeout) ->
  # How many gems must match
  matchNumber = 3
  # Animation diration
  animationDuration = 100
  # A temporary array of indexes of currently exploded gems
  exploded = []

  # The size of the board
  cols = 6
  rows = 11

  ###
  Scope variables
  ###
  $scope.gems = []

  # The size of a gem
  $scope.size = 50
  $scope.cols = cols

  # Whether game is over or not
  $scope.endGame = false

  # Statistics
  $scope.stats = {}

  ###
  Calculates columns and the size of gems and starts the game
  ###
  $scope.init = (width, height) ->
    maxCols = rows
    size = Math.floor(height / rows)
    cols = Math.min(maxCols, Math.floor(width / size))
    $scope.size = size
    $scope.cols = cols
    $scope.restart()

  $scope.restart = ->
    $scope.endGame = false

    $scope.stats = {
      gems: 0
      strings: 0
      maxString: 0
      totalScore: 0
    }

    ###
    Generate a board with at least one string of linked gems
    ###
    while isEndGame()
      $scope.gems = [0...(rows * cols)].map randomGem

  ###
  If the selected gem forms a string with adjusent gems of the
  same color, they get "exploded"
  ###
  $scope.explode = (gem) ->
    exploded = getLinked gem
    if exploded
      updateStats(exploded.length)
      exploded.forEach (index) -> $scope.gems[index].exploded = true
    $timeout(->
      exploded = null
      reorderGems()
      $scope.endGame = isEndGame()
    animationDuration)

  ###
  Checks if a gem is the one initially selected
  ###
  $scope.initiatedExplosion = (gem) ->
    gem.exploded and $scope.gems[exploded[0]] == gem

  $scope.getExplodedCount = ->
    exploded and exploded.length

  ###
  Update statistical counters
  ###
  updateStats = (len) ->
    $scope.stats.gems += len
    $scope.stats.strings += 1
    $scope.stats.maxString = Math.max(len, $scope.stats.maxString)
    ## longer strings give exponentially bigger score
    $scope.stats.totalScore += Math.pow(2, len) + len % 2

  ###
  Creates a gem with random type and color
  ###
  randomGem = ->
    new Gem(
      Gem.Colors[Math.floor Math.random() * Gem.Colors.length]
      Gem.Types[Math.floor Math.random() * Gem.Types.length]
    )

  ###
  Reorders the gems so that the exploded gems are replaced
  with the gems from the line above
  ###
  reorderGems = ->
    $scope.gems.forEach (gem, index) ->
      $scope.gems[index] = null if gem.exploded

    [(rows * cols - 1)..0].forEach (index) ->
      gem = $scope.gems[index]
      if not gem
        upperIndex = index
        while upperIndex >= cols and not gem
          upperIndex = upperIndex - cols
          gem = $scope.gems[upperIndex]
          $scope.gems[upperIndex] = null
        # If there's a gem above the removed one, it falls down.
        # Otherwise, a new random gem falls down.
        if gem
          $scope.gems[index] = new Gem gem.color, gem.type
        else
          $scope.gems[index] = randomGem()

  ###
  Gets a string of subsequent gems of the same color.
  The string can be a straight line or a polyline,
  but not a diagonal line
  ###
  getLinked = (firstGem) ->
    # This is a queue-based flood fill algorithm.
    # See http://en.wikipedia.org/wiki/Flood_fill
    linked = []
    queue = [ $scope.gems.indexOf firstGem ]
    while queue.length
      index = queue.pop()
      if linked.indexOf(index) is -1
        gem = $scope.gems[index]
        if gem and gem.color is firstGem.color
          linked.push(index)
          if index is 0 or (index + 1) % cols
            queue.push(index + 1)
          if index % cols
            queue.push(index - 1)
          queue.push(index + cols)
          queue.push(index - cols)
    linked if linked.length >= matchNumber

  ###
  Checks end game conditions
  ###
  isEndGame = ->
    # If none of the gems are linked to 2 or more gems,
    # it's the end of the game
    !$scope.gems.some (gem) -> getLinked gem


app.directive 'gemInit', ($window) ->
  restrict: 'A'
  link: ($scope) ->
    $scope.init($window.innerWidth - 50, $window.innerHeight - 100)
