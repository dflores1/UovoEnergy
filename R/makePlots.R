## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see <https://www.gnu.org/licenses/>.

#' Transforms a function into a conditional function
#'
#' Receives a function with one paramter, and transforms it
#' into a function with two paramters (adds one paramter).
#' The new paramter is a boolean. If its value is TRUE
#' executes the function, otherwise returns the original
#' data.
#' @param .f A function with one parameter .f(.d)
#' @return A new function with two paramters .f(.d, .b)
makeFunConditional <- function(.f) function(.d, .b) { if(.b) .f(.d) else .d }
    
## maybe monads
safe_identity <- maybe::maybe(identity, ensure = maybe::not_na)
safe_filterByUtility <- maybe::maybe(filterByUtility, ensure = maybe::not_empty)
safe_filterByYears <- maybe::maybe(filterByYears, ensure = maybe::not_empty)
safe_rollingMean <- maybe::maybe(rollingMean, ensure = maybe::not_empty)

# maybe monads plus make them conditional
safe_anonymise <- maybe::maybe(makeFunConditional(anonymise))
safe_addSeasonalRegression <- maybe::maybe(makeFunConditional(addSeasonalRegression))
safe_addSeasonBars <- maybe::maybe(makeFunConditional(addSeasonBars))

# maybe monads for plots
safe_plotConsumption <- maybe::maybe(plotConsumption)
safe_plotCost <- maybe::maybe(plotCost)

#' Make a Consumption Plot
#'
#' @param .d tibble data frome from getData
#' @param .u string with the utility name
#' @param .y vector of years
#' @param .h boolean for hidding information or not
#' @param .rmw numeric with a rolling mean window in days
#' @param .r boolean for adding a regression line or not
#' @param .s boolean for adding a season bar or not
#' @return a ggplot2 object
#' @export
makeConsumptionPlot <- function(.d, .u, .y, .h, .rmw, .r, .s) {
    safe_identity(.d) |>
        maybe::and_then(safe_filterByUtility, .u) |>
        maybe::and_then(safe_filterByYears, .y) |>
        maybe::and_then(safe_anonymise, .h) |>
        maybe::and_then(safe_rollingMean, "Consumption", .rmw) |>
        maybe::and_then(safe_plotConsumption) |>
        maybe::and_then(safe_addSeasonalRegression, .r) |>
        maybe::and_then(safe_addSeasonBars, .s) |>
        maybe::with_default(emptyPlot())
}

#' Make a Cost Plot
#'
#' @param .d tibble data frome from getData
#' @param .u string with the utility name
#' @param .y vector of years
#' @param .h boolean for hidding information or not
#' @param .rmw numeric with a rolling mean window in days
#' @return a ggplot2 object
#' @export
makeCostPlot <- function(.d, .u, .y, .h, .rmw) {
    safe_identity(.d) |>
        maybe::and_then(safe_filterByUtility, .u) |>
        maybe::and_then(safe_filterByYears, .y) |>
        maybe::and_then(safe_anonymise, .h) |>
        maybe::and_then(safe_rollingMean, "Cost", .rmw) |>
        maybe::and_then(safe_plotCost) |>
        maybe::with_default(emptyPlot())
}
