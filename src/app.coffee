###
Represents a polygonal jewel
###
class Gem
    constructor: (options) ->
        {@color, @type} = options
        @exploded = false
        @highlight = false
        @angle = Math.round Math.random() * 360
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


app = angular.module('gem-puzzle', ['ngAnimate'])

app.controller 'GemController', ($scope, $timeout) ->
    # How many gems must match
    @matchNumber = 3
    # The size of one side of the board
    @size = 8
    # 8x8 tiles
    @tiles = [0...(@size * @size)]
    # This is the array of gems on the board
    @gems = []
    # A temporary array of currently highlighted gems
    @highlighted = []

    ###
    Creates a gem with random type and color
    ###
    @randomGem = ->
        new Gem {
            color: Gem.Colors[Math.floor Math.random() * Gem.Colors.length]
            type: Gem.Types[Math.floor Math.random() * Gem.Types.length]
        }

    ###
    If the selected gem forms a string with adjusent gems of the
    same color, they get "exploded"
    ###
    @explode = (gem) ->
        linked = @getLinked gem
        if linked
            linked.forEach (index) =>
                @gems[index].exploded = true

            $timeout(
                => @reorder()
                300)

    ###
    Reorders the gems so that the exploded gems are replaced
    with the gems from the line above
    ###
    @reorder = () ->
        @gems.forEach (gem, index) =>
            if gem.exploded
                @gems[index] = null
        [(@size * @size - 1)..0].forEach (index) =>
            gem = @gems[index]
            if not gem
                upperIndex = index
                while upperIndex >= @size and not gem
                    upperIndex = upperIndex - @size
                    gem = @gems[upperIndex]
                    @gems[upperIndex] = null
                # If there's a gem above the removed one, it falls down.
                # Otherwise, a new random gem falls down.
                if gem
                    @gems[index] = new Gem { type: gem.type, color: gem.color }
                else
                    @gems[index] = @randomGem()

    ###
    Highlights a string of linked gems
    ###
    @highlightOn = (gem) ->
        linked = @getLinked(gem)
        if linked
            @highlighted = linked.map (index) =>
                gem = @gems[index]
                gem.highlight = true
                gem

    ###
    Un-highlights previously highlighted gems
    ###
    @highlightOff = () ->
        @highlighted.forEach (gem) ->
            gem.highlight = false
        @highlighted = []

    ###
    Gets a string of subsequent gems of the same color.
    The string can be a straight line or a polyline,
    but not a diagonal line
    ###
    @getLinked = (firstGem) ->
        # This is a queue-based flood fill algorithm.
        # See http://en.wikipedia.org/wiki/Flood_fill
        linked = []
        queue = [ @gems.indexOf firstGem ]
        while queue.length
            index = queue.pop()
            if linked.indexOf(index) is -1
                gem = @gems[index]
                if gem and gem.color is firstGem.color
                    linked.push(index)
                    if index is 0 or (index + 1) % @size
                        queue.push(index + 1)
                    if index % @size
                        queue.push(index - 1)
                    queue.push(index + @size)
                    queue.push(index - @size)
        linked if linked.length >= @matchNumber

    ###
    Checks end game conditions
    ###
    @isEndGame = () ->
        # If none of the gems are linked to 2 or more gems,
        # it's the end of the game
        !@gems.some ((gem) -> !!@getLinked gem), this

    while @isEndGame()
        @gems = @tiles.map @randomGem, this
