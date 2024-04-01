## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see <https://www.gnu.org/licenses/>.

## URLS
myovo = "https://my.ovoenergy.com"
smartpaym = "https://smartpaym.ovoenergy.com"
smartpaymapi = "https://smartpaymapi.ovoenergy.com"

#' Connects to My Ovo Rest service.
#'
#' @param username OvO username
#' @param password OvO password
#' @return A file with the connection cookie.
#' @export
connect <- function(username, password) {
    ## Login to OVO. return a login cookie file path
    cookie.path <- tempfile()
    
    httr2::request(myovo) |>
    httr2::req_url_path("/api/v2/auth/login") |>
    httr2::req_body_json(list(username = username, # Should be the client's email
                              password = password,
                              rememberMe = TRUE)) |>
    httr2::req_cookie_preserve(path = cookie.path) |>
    httr2::req_perform()

    return(cookie.path)
}

#' Disconnect from the OvO account
#'
#' Removes the cookie file
#' TODO: Use the API to disconnect
#' @param cookie.path A file with the cookie previously stablished 
#' @export
disconnect <- function(cookie.path) {
    ## TODO: Peform the actual discconection from OvO
    file.remove(cookie.path)
}

#' Retrives the account data from OvO and composes a data tibble
#'
#' This functions uses the cookie file to connect to the REST
#' API. Navigates trough the complex json structure and composes
#' a data tbble with all the consumption and cost information available.
#'
#' @param cookie.path A file with the cookie previously stablished
#' @return A data tibble with all the information
#' @export
getData <- function(cookie.path) {
    cookie.path |>
        getAccountIds() |>
        ## Map account Ids into consumption tables
        purrr::map(function(accId) {
            ## From all utilities when did start the first one?
            startDate <- min(getPlans(accId, cookie.path) |> # Plans are either electricty or gas
                             purrr::map(function(p) lubridate::as_date(p$contractStartDate)) |>
                             purrr::list_flatten() |>
                             purrr::list_c())
            ## Map each month from the startDate to today into a conpsumption table (for that account ID)
            seq(from = startDate, to = lubridate::today(), by = 'months') |>
                purrr::map(function(date, acid = accId) {
                    getMonthlyData(acid, date = date, cookie.path = cookie.path)
                }) |>
                dplyr::bind_rows() |> # Reduce tables by month into one table
                dplyr::mutate(AccountId = accId)
        }) |>
        dplyr::bind_rows() |> # Reduce tables by account into one table
        dplyr::mutate(AccountId = as.factor(AccountId),
                      ## Adding a few usefull columns
                      Year = as.factor(lubridate::year(Date)), # Just the year
                      JDay = lubridate::yday(Date) ) # Julian date
}

#' Extracts the rows pertaining to the given utility
#'
#' @param .data The data tibble
#' @param .utility the utility name we are interested in
#' @return A new data tibble
#' @export
filterByUtility <- function(.data, .utility) {
    .data |>
        dplyr::filter(Utility == .utility) |>
        droplevels()
}

#' Extract the rows with only the given years
#'
#' @param .data The data tibble
#' @param .years A vector with years
#' @return A new data tibble
#' @export
filterByYears <- function(.data, .years) {
    .data |>
        dplyr::filter(lubridate::year(Date) %in% .years)
}

#' Calculates a rolling mean over a given numeric column
#'
#' Per day plot shapes are usually very jagged.
#' This functions smoothes them over a period of days
#'
#' @param .data The data tibble
#' @param .column What numeric column should be recalculated
#' @param .window Number of days for the rolling mean
#' @return A new data tibble
#' @export
rollingMean <- function(.data, .column, .window) {

    rolling_mean <- tibbletime::rollify(mean, window = .window)
    
    .data |>
        dplyr::group_by(AccountId) |>
        dplyr::arrange(Date) |>
        dplyr::mutate("{.column}" := rolling_mean(.data[[.column]])) |> # using name injection
        dplyr::filter(!is.na(Consumption)) |>
        dplyr::ungroup()
}

#' Anonymise data
#'
#' Substitutes Account Id information with random names
#' also adds some jitter noise to the data.
#' Useful if you are planning to publish a plot
#' somwehre on the internet
#' @param .data A tibble
#' @return A tibble without sensible information
#' @export
anonymise <- function(.data) {
    accounts <- levels(.data$AccountId)
    map_AccountId <- proceduralnames::make_docker_names(length(accounts))
    names(map_AccountId) <- accounts
    new_AccountId <- map_AccountId[.data$AccountId]
    names(new_AccountId) <- c()
    .data |>
        dplyr::mutate(AccountId = factor(new_AccountId),
                      ## Add some noise to the data
                      Cost = jitter(Cost),
                      Consumptiom = jitter(Consumption))
}


                                        #
                                        # PRIVATE FUNCTIONS START HERE
                                        #

#' Return the account plans in a list
#'
#' @param accId Account ID
#' @param cookie.path  A file with the cookie previously stablished
#' @return A list with the plans
getPlans <- function(accId, cookie.path) {
    httr2::request(smartpaymapi) |>
        httr2::req_url_path_append("orex/api/plans") |>
        httr2::req_url_path_append(accId)  |>
        httr2::req_cookie_preserve(path = cookie.path) |>
        httr2::req_perform() |>
        httr2::resp_body_json()
}

#' Query the OvO API for the account IDs
#'
#' Normally, it's only one.
#' @param cookie.path  A file with the cookie previously stablished
#' @return A vector of account IDs
getAccountIds <- function(cookie.path) {
    httr2::request(smartpaym) |>
        httr2::req_url_path("/api/customer-and-account-ids") |>
        httr2::req_cookie_preserve(path = cookie.path) |>
        httr2::req_perform() |>
        httr2::resp_body_json() |>
        magrittr::extract2("accountIds")
}

#' Get the data for a given month and account
#'
#' The returned tibble will have this shape
#'      Consumption Date       Cost  RateAnytime RateStanding Utility    
#'         <dbl> <date>     <chr>       <dbl>        <dbl> <fct>      
#'1        9.87 2023-04-01 3.15        0.319        0.472 electricity
#'2        5.28 2023-04-02 1.69        0.319        0.472 electricity
#' ...
#' @param accID Account ID
#' @param data A date object with the monnth
#' @param cookie.path  A file with the cookie previously stablished
#' @return A data tibble for that month and account id
getMonthlyData <- function(accId, date, cookie.path) {
    ## Do the GET query
    httr2::request(smartpaym) |>
        httr2::req_url_path_append("api/energy-usage/daily") |>
        httr2::req_url_path_append(accId) |>
        httr2::req_url_query(date = format(date, "%Y-%m")) |>
        httr2::req_cookie_preserve(path = cookie.path) |>
        httr2::req_perform() |>
        httr2::resp_body_json() |> # This returns a list that represents the json answer
        ## Below is the code to transform the list into a tibble (data frame)
        ## Since the list is a nested structure I basically use a map/reduce approach
        purrr::lmap(function(utility) { # map
            utility_name = names(utility[1])
            utility |>
                magrittr::extract2(utility_name) |>
                magrittr::extract2("data") |>
                purrr::map(function(day_entry) { # map
                    day_entry |>
                        purrr::list_flatten() |>
                        tibble::as_tibble() |> # table creation
                        dplyr::rename(Consumption = consumption,
                                      Date = interval_start,
                                      Cost = cost_amount,
                                      RateAnytime = rates_anytime,
                                      RateStanding = rates_standing) |>
                        dplyr::mutate(Date = lubridate::as_date(Date),
                                      Cost = as.numeric(Cost)) |>
                        dplyr::select(Consumption, Date, Cost, RateAnytime, RateStanding)
                }) |>
                dplyr::bind_rows() |> # reduce
                dplyr::mutate(Utility = stringr::str_to_title(utility_name))
        }) |>
        dplyr::bind_rows() |> # reduce
        dplyr::mutate(Utility = as.factor(Utility)) |>
        dplyr::filter(Consumption >= 0) # We can get negative costs. Remove them.
}
