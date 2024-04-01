## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see <https://www.gnu.org/licenses/>.

#' Run the interactive analysis tool (Shiny app) in a web browser
#' 
#' Launch an interactive tool to analyse the data.
#' @export
launch <- function() {
  shiny::runApp(system.file("shiny", package = "UovoEnergy"),
                display.mode = "normal",
                launch.browser = FALSE)
}
