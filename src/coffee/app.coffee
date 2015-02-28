app = angular.module('gem-puzzle', ['ngAnimate', 'ngMaterial'])


###
Represents a polygonal jewel
###
class Gem
    constructor: (options) ->
        {@color, @type} = options
        @exploded = false
        @highlight = false
        @explodedCount = 0
        @points = @getPolygonPoints()

    getPolygonPoints: ->
        size = 200
        center = size / 2
        base = 2 * Math.PI / @type
        ([0...@type].map (index) ->
            angle = base * (index + 0.5)
            ([
                center + center * Math.cos(angle),
                center + center * Math.sin(angle)
            ].map (n) ->
                n.toFixed(0)
            ).join ' '
        ).join ','

###
The type of gem determines how many angles it has
###
Gem.Types = [
    5,
    6,
    8,
    12
]

###
The color of the gem
###
Gem.Colors = [
    'red'
    'green'
    'blue'
    'yellow',
    'violet'
]


app.controller 'GemController', ($scope, $timeout, $mdDialog) ->
    # How many gems must match
    matchNumber = 3
    # The size of one side of the board
    size = 8
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

    # Statistics
    $scope.stats = {}

    $scope.getSize = ->
        size

    $scope.restart = ->
        endGame = false

        $scope.stats =
            gems: 0
            strings: 0
            maxString: 0
            totalScore: 0

        ###
        Generate a board with at least one string of linked gems
        ###
        while isEndGame()
            gems = [0...(size * size)].map randomGem

    ###
    Returns the list of gems for iteration
    ###
    $scope.getGems = ->
        return gems

    $scope.isGameOver = ->
        return endGame;

    ###
    If the selected gem forms a string with adjusent gems of the
    same color, they get "exploded"
    ###
    $scope.explode = (gem) ->
        exploded = getLinked gem
        if exploded
            saveStats(exploded)
            exploded.forEach (index) -> gems[index].exploded = true
            $timeout(->
                exploded = null
                reorderGems()
                setEngGame isEndGame()
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

    $scope.isFirstExploded = (gem) ->
        gem.exploded && gems[exploded[0]] == gem

    $scope.getExplodedCount = ->
        exploded && exploded.length

    ###
    Update statistical counters
    ###
    saveStats = (linked) ->
        len = linked.length
        $scope.stats.currentString = len
        $scope.stats.gems += len
        $scope.stats.strings += 1
        $scope.stats.maxString = Math.max(len, $scope.stats.maxString)
        ## longer strings give exponentially bigger score
        $scope.stats.totalScore += Math.pow(2, len) + len % 2

    ###
    Creates a gem with random type and color
    ###
    randomGem = ->
        new Gem {
            color: Gem.Colors[Math.floor Math.random() * Gem.Colors.length]
            type: Gem.Types[Math.floor Math.random() * Gem.Types.length]
        }

    ###
    Reorders the gems so that the exploded gems are replaced
    with the gems from the line above
    ###
    reorderGems = ->
        gems.forEach (gem, index) ->
            if gem.exploded
                gems[index] = null

        [(size * size - 1)..0].forEach (index) ->
            gem = gems[index]
            if not gem
                upperIndex = index
                while upperIndex >= size and not gem
                    upperIndex = upperIndex - size
                    gem = gems[upperIndex]
                    gems[upperIndex] = null
                # If there's a gem above the removed one, it falls down.
                # Otherwise, a new random gem falls down.
                if gem
                    gems[index] = new Gem { type: gem.type, color: gem.color }
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
                    if index is 0 or (index + 1) % size
                        queue.push(index + 1)
                    if index % size
                        queue.push(index - 1)
                    queue.push(index + size)
                    queue.push(index - size)
        linked if linked.length >= matchNumber

    ###
    Checks end game conditions
    ###
    isEndGame = ->
        # If none of the gems are linked to 2 or more gems,
        # it's the end of the game
        !gems.some (gem) -> getLinked gem

    setEngGame = (val) ->
        endGame = val
        showGameOver() if endGame

    showGameOver = () ->
        upperScope = $scope
        $mdDialog.show
            controller: ($scope) ->
                $scope.restart = ->
                    upperScope.restart()
                    $mdDialog.hide()
                $scope.stats = upperScope.stats
            templateUrl: 'dialog.html'
