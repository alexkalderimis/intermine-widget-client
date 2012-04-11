### View maintaining Chart Widget.###

class ChartView extends Backbone.View

    # Google Visualization chart options.
    chartOptions:
        fontName: "Sans-Serif"
        fontSize: 11
        width:    550
        height:   450
        legend:   "bottom"
        colors:   [ "#2F72FF", "#9FC0FF" ]
        chartArea:
            top: 30
        hAxis:
            titleTextStyle:
                fontName: "Sans-Serif"
        vAxis:
            titleTextStyle:
                fontName: "Sans-Serif"

    events:
        "change div.form select": "formAction"

    initialize: (o) ->
        @[k] = v for k, v of o
        @render()

    render: ->
        # Render the widget template.
        $(@el).html @template "chart.normal",
            "title":       if @options.title then @response.title else ""
            "description": if @options.description then @response.description else ""
            "notAnalysed": @response.notAnalysed

        # Extra attributes (DataSets etc.)?
        if @response.filterLabel?
            $(@el).find('div.form form').append @template "chart.extra",
                "label":    @response.filterLabel
                "possible": @response.filters.split(',') # Is a String unfortunately.
                "selected": @response.filterSelectedValue

        # Are the results empty?
        if @response.results.length > 1
            # Create the chart.
            if @response.chartType of google.visualization # If the type exists...
                chart = new google.visualization[@response.chartType]($(@el).find("div.content")[0])
                chart.draw(google.visualization.arrayToDataTable(@response.results, false), @chartOptions)

                # Add event listener on click the chart bar.
                if @response.pathQuery?
                    google.visualization.events.addListener chart, "select", =>

                        # Translate view series into PathQuery series (Expressed/Not Expressed into true/false).
                        translate = (response, series) ->
                            response.seriesValues.split(',')[response.seriesLabels.split(',').indexOf(series)]

                        # PathQuery attr.
                        pq = @response.pathQuery
                        for item in chart.getSelection()
                            if item.row?
                                # Replace `%category` in PathQuery.
                                pq = pq.replace "%category", @response.results[item.row + 1][0]
                                # Replace `%series` in PathQuery.
                                if item.column?
                                    pq = pq.replace("%series", translate @response, @response.results[0][item.column])
                                # Turn into JSON object?
                                pq = JSON?.parse pq
                                # Make the callback.
                                @options.selectCb pq
            else
                # Undefined Google Visualization chart type.
                @error 'title': @response.chartType, 'text': "This chart type does not exist in Google Visualization API"

        else
            # Render no results.
            $(@el).find("div.content").html $ @template "noresults"

    # On form select option change, set the new options and re-render.
    formAction: (e) =>
        @widget.formOptions[$(e.target).attr("name")] = $(e.target[e.target.selectedIndex]).attr("value")
        @widget.render()