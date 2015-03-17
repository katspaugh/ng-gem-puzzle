app = angular.module('gem-puzzle', ['ngAnimate'])


###
Represents a polygonal jewel
###
class Gem
  constructor: (color, type) ->
    @color = color
    @type = type
    @exploded = false
    @highlight = false
    @points = @getPolygonPoints()

  getPolygonPoints: ->
    size = 200
    center = size / 2
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
  # The size of the board
  cols = 6
  rows = 11
  # This is the array of gems on the board
  gems = []
  # A temporary array of currently highlighted gems
  highlighted = []
  # A temporary array of indexes of currently exploded gems
  exploded = []
  # Animation diration
  animationDuration = 300
  # Whether game is over or not
  endGame = false

  # Gem size
  $scope.size = 50
  $scope.cols = cols

  # Statistics
  $scope.stats = {}

  $scope.restart = ->
    endGame = false

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
      gems = [0...(rows * cols)].map randomGem

  ###
  Returns the list of gems for iteration
  ###
  $scope.getGems = ->
    gems

  ###
  Checks if the game if over
  ###
  $scope.isGameOver = ->
    endGame

  ###
  If the selected gem forms a string with adjusent gems of the
  same color, they get "exploded"
  ###
  $scope.explode = (gem) ->
    exploded = getLinked gem
    if exploded
      updateStats(exploded.length)
      exploded.forEach (index) -> gems[index].exploded = true
    $timeout(->
      exploded = null
      reorderGems()
      endGame = isEndGame()
    animationDuration)

  ###
  Highlights a string of linked gems
  ###
  $scope.highlightOn = (gem) ->
    linked = getLinked(gem)
    if linked
      highlighted = linked.map (index) -> gems[index]
      highlighted.forEach (gem) -> gem.highlight = true

  ###
  Un-highlights previously highlighted gems
  ###
  $scope.highlightOff = ->
    highlighted.forEach (gem) -> gem.highlight = false
    highlighted.length = 0

  ###
  Checks if a gem is the one initially selected
  ###
  $scope.initiatedExplosion = (gem) ->
    gem.exploded and gems[exploded[0]] == gem

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
    gems.forEach (gem, index) ->
      gems[index] = null if gem.exploded

    [(rows * cols - 1)..0].forEach (index) ->
      gem = gems[index]
      if not gem
        upperIndex = index
        while upperIndex >= cols and not gem
          upperIndex = upperIndex - cols
          gem = gems[upperIndex]
          gems[upperIndex] = null
        # If there's a gem above the removed one, it falls down.
        # Otherwise, a new random gem falls down.
        if gem
          gems[index] = new Gem gem.color, gem.type
        else
          gems[index] = randomGem()

  ###
  Gets a string of subsequent gems of the same color.
  The string can be a straight line or a polyline,
  but not a diagonal line
  ###
  getLinked = (firstGem) ->
    # This is a queue-based flood fill algorithm.
    # See http://en.wikipedia.org/wiki/Flood_fill
    linked = []
    queue = [ gems.indexOf firstGem ]
    while queue.length
      index = queue.pop()
      if linked.indexOf(index) is -1
        gem = gems[index]
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
    !gems.some (gem) -> getLinked gem
