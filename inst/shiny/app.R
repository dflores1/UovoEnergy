## This file is part of UovoEnergy.

## UovoEnergy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

## UovoEnergy is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public License along with Foobar. If not, see <https://www.gnu.org/licenses/>.

library(shiny)

# Define UI ----
ui <- fluidPage(
    titlePanel("Uovo Energy"),
    helpText("🥚 Uovo is the italian name for egg 🥚"),
    helpText("Version: 0.1"),

    sidebarPanel(
        wellPanel(h1("Account Details"),
                  helpText("Connects to your My Ovo account and retrieve the data.",
                           div(tags$b("IMPORTANT: "), "Your login details are not stored anywhere."),
                           textInput("email",
                                     label = h3("Email:")),
                           passwordInput("password",
                                         label = h3("Password:")),
                           actionButton("proceed",
                                        label = "Proceed"),
                           textOutput("info"))),
        wellPanel(h1("Plot Parameters"),
                  checkboxGroupInput("years",
                                     label = "Years: "),
                  sliderInput("rollingMeanWindow",
                              label = "Rolling Mean Days:",
                              min = 1, max = 30, value = 5),
                  helpText("Usually consumption plots are very jagged.",
                           "To smooth them, a rolling mean is being used.",
                           div("By default it's calculate over the span of 5 days,",
                               "which is a reasonable value."),
                           div("However, should you want to deactivate it, just move the slider to 1.")),
                  h3("Seasonal Params:"),
                  checkboxInput("regression",
                                label = "Add Regression Line",
                                value = FALSE),
                  helpText("Adds a regression line following the cosine model:",
                           div("𝑦 = 𝐴 + 𝐵·𝑥 + 𝐶·cos(2𝜋𝑥) + 𝐷·sin(2𝜋𝑥)"),
                           "This helps to see how your energy comsumption varies according to the season."),
                  checkboxInput("seasonBars",
                                label = "Add Season Bars",
                                value = FALSE),
                  helpText("Adds a bar at the bottom of the consumption plots.",
                           "This bar denotes the seasons: winter/spring/summer/autumn."),
                  h3("Other:"),
                  checkboxInput("hideAccountIds",
                                label = "Remove Account Ids",
                                value = FALSE),
                  helpText("Removes the account ID and replaces it with a random name.",
                           "Also adds some random noise to the data.",
                           "Useful if you want to post the plot somewhere on the internet.")),
        wellPanel(
            h1("About Costs"),
            helpText("The energy bill is usually divided in two parts:",
                     div("\n Cost = Standing Rate + Consumption * Unit Rate \n"),
                     "This means that regardless of how much energy you save,",
                     "you are always going to pay the Standing Rate as a minimum.",
                     "This rate is shown in blue.")),
        wellPanel(
            h1("Uovo Energy"),
            h2("Source code"),
            div("Find the source code at: ",
                a(href="https://github.com/dflores1/UovoEnergy", "github.com/dflores1/UovoEnergy")),
            h2("License"),
            h3("GPLv3"),
            div(paste(
                "UovoEnergy is free software: you can redistribute it and/or modify it under the",
                "terms of the GNU General Public License as published by the Free Software Foundation,",
                "either version 3 of the License, or (at your option) any later version.")),
            br(),
            div(paste(
                "UovoEnergy is distributed in the hope that it will be useful,",
                "but WITHOUT ANY WARRANTY; without even the implied warranty of",
                "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.",
                "See the GNU General Public License for more details.")),
            br(),
            div("You should have received a copy of the GNU General Public License along with UovoEnergy. If not, see ",
                a(href="https://www.gnu.org/licenses/","<https://www.gnu.org/licenses/>.")))),

    mainPanel(
        h1("Disclaimer"),
        div(tags$b("This is NOT the official OVO Energy Portal")),
        div("For the official website and data, please go to the",
            a(href="https://www.ovoenergy.com", "OVO Energy Portal.")),
        h1("Readings"),
        wellPanel(h2("Electricity"),
                  plotOutput("electricityConsumption.plot")),
        wellPanel(h2("Gas"),
                  plotOutput("gasConsumption.plot")),
        h1("Costs"),
        wellPanel(h2("Electricity"),
                  plotOutput("electricityCost.plot")),
        wellPanel(h2("Gas"),
                  plotOutput("gasCost.plot"))),
        
)

# Define server logic ----
server <- function(input, output, session) {

    data.tbl <- NA
    
    output$info <- renderText({"No data"})
    
    observeEvent(input$proceed, {
        cookie.path <- UovoEnergy::connect(input$email, input$password)
        ## Get the consumptions table (tibble)
        data.tbl <- UovoEnergy::getData(cookie.path)
        ## Update the date control with the correct possible values
        choiceYears <- unique(lubridate::year(data.tbl$Date))
        updateCheckboxGroupInput(session, "years",
                                 choiceNames = as.character(choiceYears),
                                 choiceValues = choiceYears,
                                 selected = choiceYears)
        output$info <- renderText({"Generating plots"})
        output$electricityConsumption.plot <- renderPlot({
            UovoEnergy::makeConsumptionPlot(data.tbl, "Electricity", input$years,
                                            input$hideAccountIds, input$rollingMeanWindow,
                                            input$regression, input$seasonBars)},
            res = 96)
        output$gasConsumption.plot <- renderPlot({
            UovoEnergy::makeConsumptionPlot(data.tbl, "Gas", input$years,
                                            input$hideAccountIds, input$rollingMeanWindow,
                                            input$regression, input$seasonBars)},
            res = 96)
        output$electricityCost.plot <- renderPlot({
            UovoEnergy::makeCostPlot(data.tbl, "Electricity", input$years,
                                     input$hideAccountIds, input$rollingMeanWindow)},
            res = 96)
        output$gasCost.plot <- renderPlot({
            UovoEnergy::makeCostPlot(data.tbl, "Gas", input$years,
                                     input$hideAccountIds, input$rollingMeanWindow)},
            res = 96)
        output$info <- renderText({"Data Loaded"})
        UovoEnergy::disconnect(cookie.path)
    })

}

# Run the app ----
shinyApp(ui = ui, server = server)
