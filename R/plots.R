## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see <https://www.gnu.org/licenses/>.

#' Plot and empty plot that says NO PLOT
#'
#' @return A ggplot object
#' @export
emptyPlot <- function() {
    text = paste("NO PLOT")
    
    ggplot2::ggplot() + 
        ggplot2::annotate("text", x = 4, y = 25, size=8, label = text) + 
        ggplot2::theme_void()
}

#' Plot the Consumption
#'
#' You need to filter by utility,
#' select the years and perhaps
#' calculate a rolling mean before using this function.
#'
#' @param .data A data tibble previously treated
#' @return A ggplot object with the consumption
#' @export
plotConsumption <- function(.data) {

    juld.tbl <- julDates()    

    .data |>
        ggplot2::ggplot(ggplot2::aes(x = JDay, y = Consumption)) +
        ggplot2::geom_line(ggplot2::aes(group = Year, colour = Year)) +
        ggplot2::scale_x_continuous(breaks = juld.tbl$jul,
                           labels = juld.tbl$mon,
                           ## Remove the x-axis padding
                           expand = c(0, 0)) +
        ## Remove the filling guide (seasons)
        ggplot2::guides(fill="none") +
        ## No names on the axis. The units are clear
        ggplot2::xlab(NULL) +
        ggplot2::ylab("kWh") +
        ## One plot per AccountId
        ggplot2::facet_wrap(~AccountId, strip.position = "right") +
        ggplot2::theme_bw() +
        ggplot2::theme(legend.title = ggplot2::element_blank(),
              legend.position = c(.065, .95),
              legend.spacing.y = grid::unit(.001, "npc"),
              legend.key.width = grid::unit(.025, "npc"),
              legend.key.height = grid::unit(.01, "npc"),
              legend.spacing = grid::unit(.2, "npc"),
              legend.text = ggplot2::element_text(size=8),
              legend.background = ggplot2::element_rect(fill = ggplot2::alpha("lightblue", 0.5),
                                                        linewidth = .25, linetype="solid",
                                                        colour = "black") )
}

#' Add a cosine model regression to plot.
#'
#' This is aimed to show wether there is seasonality on the energy consumption.
#' @param .plot A ggplot plot from plotConsumption
#' @return A ggplot object with the linear regression added
#' @export
addSeasonalRegression <- function(.plot) {
    .plot +
        ggplot2::geom_smooth(method = "lm",
                             ## Cosine model
                             formula = y ~ 1 + cos(2*pi*x/365.4) + sin(2*pi*x/365.4),
                             colour = "purple")
}

#' Add season boxes to the bottom to a plot
#'
#' @param .plot A ggplot2 object from consumptionPlot
#' @return A ggplot object with season boxes
#' @export
addSeasonBars <- function(.plot) {
    
    seasons.tbl <- seasonDates(.plot$data)

    .plot +
        ggplot2::geom_rect(data = seasons.tbl,
                           ggplot2::aes(NULL, NULL, 
                               xmin = Start, xmax = End, 
                               ymin = ymin, ymax = ymax, 
                               fill = Season),
                           alpha = .75) +
        ## Season colours
        ggplot2::scale_fill_manual(breaks = c('Winter','Spring','Summer','Autumn'),
                                   values = c('deepskyblue1', 'limegreen', 'gold1',
                                              'brown3') )
}

#' Plot the Costs
#'
#' You need to filter by utility,
#' select the years and perhaps
#' calculate a rolling mean before using this function.
#'
#' The actual consumption is plotted in red
#' and the standing charge in blue.
#'
#' @param .data A data tibble previously treated
#' @return A ggplot object with the cost
#' @export
plotCost <- function(.data) {    
    .data |>
        ## Calculate the Unit Rate and the Standing Rate of the Cost
        ## Cost = Standing Rate + Consumption * Unit Rate
        dplyr::mutate(Cost = Cost - RateStanding) |>
        tidyr::pivot_longer(cols = c("Cost", "RateStanding"), names_to = "Rates", values_to = "Price") |>
        dplyr::mutate(Rates = factor(gsub("RateStanding", "Standing", gsub("Cost", "Unit", Rates)),
                                       levels = c("Unit", "Standing"))) |>
        ## And now, we are ready to plot the data.
        ggplot2::ggplot(ggplot2::aes(x = Date, y = Price)) +
        ggplot2::geom_col(ggplot2::aes(fill = Rates)) +
        ggplot2::facet_wrap(~ AccountId, strip.position = "right") +
        ggplot2::ylab("GBP") +
        ggplot2::theme_bw() +
        ggplot2::theme(legend.position = c(.065, .95),
                       legend.spacing.y = grid::unit(.001, "npc"),
                       legend.key.width = grid::unit(.025, "npc"),
                       legend.key.height = grid::unit(.01, "npc"),
                       legend.spacing = grid::unit(.2, "npc"),
                       legend.text = ggplot2::element_text(size = 8),
                       legend.background = ggplot2::element_rect(fill = ggplot2::alpha("lightblue", 0.5),
                                                                 linewidth = .25, linetype="solid",
                                                                 colour = "black") )
}

                                        #
                                        # PRIVATE FUNCTIONS START HERE
                                        #

#' Create a table that maps current year's julian dates
#' to human readable month names.
#' This is used for relabeling the x axis ticks
julDates <- function() {
    
    dateStart <- lubridate::today() # We use the current date 
    lubridate::month(dateStart) <- 1 # Travel back to the first
    lubridate::day(dateStart) <- 1   # of January
    dateEnd <- dateStart
    lubridate::month(dateEnd) <- 12 # 1st of December
    tikDates <- seq(from = dateStart, to = dateEnd, by = 'months')

    ## Create the mapping table
    juld.tbl <- tibble::tibble(mon = stringr::str_to_title(lubridate::month(tikDates, label = T)),
                               jul = lubridate::yday(tikDates))
    return(juld.tbl)
}

#' Get the start and end of the 4 seasons.
#'
#' Also calculate a ymax and ymin limits.
#' With this information one can draw a box at the
#' bottom of a plot representing the seasons.
#' @param .data A data tibble
#' @return A data tibble with the season information
seasonDates <- function(.data) {
    cmax <- max(.data$Consumption)

    tibble::tibble(Start = c(0, 80, 173, 266, 356),
                   End = c(79, 172, 265, 355, 365),
                   Season = factor(c('Winter', 'Spring', 'Summer', 'Autumn',
                                     'Winter')),
                   ## Let's add a nice narrow box around y=0 for the plot
                   ymax = 0,
                   ymin = cmax*-0.05)
}
