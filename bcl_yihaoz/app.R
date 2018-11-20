#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(ggplot2)
library(dplyr)
library(DT)
library(colourpicker)

bcl <- read.csv("bcl-data.csv", stringsAsFactors = FALSE)


# Define UI for application that draws a histogram
ui <- dashboardPage(
	# create hyperlink and logo in header
	dashboardHeader(title = "BC Liquor Store Prices",
							tags$li(a(href='http://www.bcliquorstores.com',
								   tags$img(src='https://seeklogovector.com/wp-content/uploads/2018/10/bc-liquor-stores-logo-vector.png',
								   		 height='60',width='200')),
									class = "dropdown")),
    skin = "blue",

	# use dashboard to have the option to hide the panel
    dashboardSidebar(
        sliderInput("priceInput", "Price", 0, 100, c(25, 40), pre = "$"),
        radioButtons("typeInput", "Product type",
                     choices = c("BEER", "REFRESHMENT", "SPIRITS", "WINE"),
                     selected = "WINE"),
        uiOutput("countryOutput")
    ),

    dashboardBody(
        div(img(src = "drinkiing.gif"), style="text-align: center;"),
        hr(),

        verbatimTextOutput("summaryText"),
        tabsetPanel(
            tabPanel(
                "Plot",
                fluidRow(
                    box(title = "Liquor price histogram", status = "primary",
                        width = 9,
                        solidHeader = TRUE,
                        collapsible = TRUE,
                    	# let the user to pick the colour
                        colourInput("col", "Select histogram bar colour", "purple"),
                        plotOutput("coolplot"))
                )


            ),
            tabPanel(
                "Table",
                # download button
                div(style="display:inline-block",downloadButton('downloadData', 'Download Data'), style="float:right"),

                # create checkbox for sort by price option
                checkboxInput("sortByPrice", "Sort by price", FALSE),
                conditionalPanel(
                    condition = "input.sortByPrice == true",
                    radioButtons("sortOrder", NULL,
                                 choices = c("Price from low to high",
                                             "Price from high to low"))
                ),
                DT::dataTableOutput("results")
            )
        ),
        br(), br()
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    output$countryOutput <- renderUI({
        selectInput("countryInput", "Country",
                    sort(unique(bcl$Country)),
                    selected = "CANADA")
    })

    output$summaryText <- renderText({
        numOptions <- nrow(filtered())
        if (is.null(numOptions)) {
            numOptions <- 0
        }
        paste0("We found ", numOptions, " options for you")
    })

    filtered <- reactive({
        if (is.null(input$countryInput)) {
            return(NULL)
        }

        filtered <- bcl %>%
            filter(Price >= input$priceInput[1],
                   Price <= input$priceInput[2],
                   Type == input$typeInput,
                   Country == input$countryInput
            )

        # Sort by the price if sortByPrice is checked
        if (input$sortByPrice) {
        	# conditional panel
            if (input$sortOrder == "Price from low to high") {
                filtered <- arrange(filtered, Price)
            }
            else {
                filtered <- arrange(filtered, dplyr::desc(Price))
            }
        }
        else {
        	# keep the original df if sort is not checked
            filtered <- filtered
        }
    })

    output$coolplot <- renderPlot({
        if (is.null(filtered())) {
            return(NULL)
        }
        # col is passed as input for filling
        ggplot(filtered(), aes(Alcohol_Content)) +
            geom_histogram(fill = input$col) +
            theme_bw()
    })

    output$results <- DT::renderDataTable(class = 'cell-border stripe',{
        if (is.null(filtered())) {
            return(NULL)
        }

        filtered()
    })

    # Downloadable csv of selected dataset ----
    output$downloadData <- downloadHandler(
        filename = function() {
            paste("bcl.csv")
        },
        content = function(file) {
            write.csv(filtered(), file)
        }
    )
}

# Run the application
shinyApp(ui = ui, server = server)
