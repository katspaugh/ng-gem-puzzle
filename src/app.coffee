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


app = angular.module('shariki', []);

app.controller 'GemController', ($scope, $timeout) ->
    # How many gems must match
    @matchNumber = 3
    # Size of the board is 8x8
    @size = 8
    # This is the array of gems on the board
    @gems = []
    # A temporary array of currently highlighted gems
    @highlighted = []
    # Can't match gems when the game is in the dirty state
    @dirty = false

    ###
    Creates a gem with random type and color
    ###
    randomGem = ->
        new Gem {
            color: Gem.Colors[Math.floor Math.random() * Gem.Colors.length]
            type: Gem.Types[Math.floor Math.random() * Gem.Types.length]
        }

    ###
    If the selected gem forms a string with adjusent gems of the
    same color, they get "exploded"
    ###
    @explode = (gem) ->
        if @dirty
            return null

        adjacent = @getAdjacent gem
        if adjacent.length >= @matchNumber
            @dirty = true

            adjacent.forEach (index) =>
                @gems[index].exploded = true

            $timeout((=>
                @dirty = false
                @gems = @getSorted()), 300)

    ###
    Returns a new gems array with exploded gems replaced with the
    gems from the line above
    ###
    @getSorted = () ->
        sorted = @gems.map (gem) ->
            if gem.exploded
                gem = null
            gem
        [(@size * @size - 1)..0].map (index) =>
            gem = sorted[index]
            upperIndex = index
            while upperIndex >= @size and not gem
                upperIndex = upperIndex - @size
                gem = sorted[upperIndex]
                sorted[upperIndex] = null
            sorted[index] = gem or randomGem()
        sorted

    ###
    Highlights a string of adjacent gems
    ###
    @highlightOn = (gem) ->
        indeces = @getAdjacent(gem)
        if indeces.length >= @matchNumber
            @highlighted = indeces.map (index) =>
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
    @getAdjacent = (firstGem) ->
        # This is a queue-based flood fill algorythm.
        # See http://en.wikipedia.org/wiki/Flood_fill
        adjacent = []
        queue = [ @gems.indexOf firstGem ]
        while queue.length
            index = queue.pop()
            if adjacent.indexOf(index) is -1
                gem = @gems[index]
                if gem and gem.color is firstGem.color
                    adjacent.push(index)
                    if index is 0 or (index + 1) % @size
                        queue.push(index + 1)
                    if index % @size
                        queue.push(index - 1)
                    queue.push(index + @size)
                    queue.push(index - @size)
        adjacent


    @gems = [0...(@size * @size)].map randomGem
