### Table Widget table row.###

class TableRowView extends Backbone.View

    tagName: "tr"

    events:
        "click td.check input":     "selectAction"
        "click td.matches a.count": "toggleMatchesAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        @model.bind('change', @render)

        @render()

    render: =>
        $(@el).html @template "table.row", "row": @model.toJSON()
        @

    # Toggle the `selected` attr of this row object.
    selectAction: =>        
        @model.toggleSelected()

        # Have we got popover view to inject?
        if @popoverView? then $(@el).find('td.matches a.count').after @popoverView.el

    # Show matches.
    toggleMatchesAction: =>
        if not @popoverView?
            $(@el).find('td.matches a.count').after (@popoverView = new TablePopoverView(
                "identifiers":    [ @model.get "identifier" ]
                "description":    @model.get("descriptions").join(', ')
                "template":       @template
                "matchCb":        @matchCb
                "resultsCb":      @resultsCb
                "listCb":         @listCb
                "pathQuery":      @response.pathQuery
                "pathConstraint": @response.pathConstraint
                "imService":      @imService
                "type":           @response.type
            )).el
        else @popoverView.toggle()